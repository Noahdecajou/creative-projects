param([switch]$RenderOnly, [switch]$PackageOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = $PSScriptRoot
. (Join-Path $root 'add_final_noise.ps1')
$follow = Join-Path $root 'Suivi\Scott_Pulcini_Thumbnails_V03'
$masterDir = Join-Path $root 'Masters\Scott_Pulcini_Thumbnails_V03'
$exportDir = Join-Path $root 'Exports_4K\Scott_Pulcini_Thumbnails_V03'
$previewDir = Join-Path $root 'Apercus\Scott_Pulcini_Thumbnails_V03'
$items = Get-Content -Raw -LiteralPath (Join-Path $follow 'Generated_sources.json') | ConvertFrom-Json

if (-not $PackageOnly) {
function Resize-Photo([System.Drawing.Image]$source, [int]$width, [int]$height) {
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $attributes = New-Object System.Drawing.Imaging.ImageAttributes
    $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $cropWidth = [double]$source.Width
    $cropHeight = [double]$source.Height
    if (($cropWidth / $cropHeight) -gt ($width / $height)) { $cropWidth = $cropHeight * $width / $height } else { $cropHeight = $cropWidth * $height / $width }
    $rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
    $graphics.DrawImage($source, $rect, [single](($source.Width - $cropWidth)/2), [single](($source.Height - $cropHeight)/2), [single]$cropWidth, [single]$cropHeight, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
    $attributes.Dispose()
    $graphics.Dispose()
    return $bitmap
}

$manifest = @()
foreach ($item in $items) {
    $masterPath = Join-Path $masterDir ($item.id + '_' + $item.slug + '_master.png')
    if (-not (Test-Path -LiteralPath $masterPath)) { Copy-Item -LiteralPath $item.path -Destination $masterPath }
    $source = [System.Drawing.Image]::FromFile($masterPath)
    $exportName = $item.id + '_' + $item.slug + '_3840x2160.png'
    $exportPath = Join-Path $exportDir $exportName
    $export = Resize-Photo $source 3840 2160
    [ThumbnailNoise]::Apply($export, 5.0, (61008 + [int]$item.id))
    $export.Save($exportPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $small = Resize-Photo $export 320 180
    $small.Save((Join-Path $previewDir ($item.id + '_mobile_320x180.png')), [System.Drawing.Imaging.ImageFormat]::Png)
    $small.Dispose()
    $preview = Resize-Photo $export 1280 720
    $preview.Save((Join-Path $previewDir ($item.id + '_apercu.jpg')), [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $preview.Dispose()
    $export.Dispose()
    $check = [System.Drawing.Image]::FromFile($exportPath)
    if ($check.Width -ne 3840 -or $check.Height -ne 2160) { throw ('Dimensions incorrectes : ' + $exportPath) }
    $manifest += [pscustomobject]@{ id=$item.id; title=$item.title; reference=$item.ref; file=$exportName; master_width=$source.Width; master_height=$source.Height; export_width=$check.Width; export_height=$check.Height; upscaled=($source.Width -lt 3840); shirt_color=$item.color; noise_percent=5; noise_distribution='Gaussian monochromatic, sigma 12.75/255, applied after 4K resize'; status='Cree - non publie' }
    $check.Dispose()
    $source.Dispose()
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $follow 'Manifest_exports.json')

function Make-Sheet([int]$tileW, [int]$tileH, [int]$columns, [string]$name) {
    $labelH = 34
    $rows = [int][Math]::Ceiling($items.Count / $columns)
    $sheet = New-Object System.Drawing.Bitmap(($columns * $tileW), ($rows * ($tileH + $labelH)))
    $g = [System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(24,24,24))
    $font = New-Object System.Drawing.Font('Arial', 13, [System.Drawing.FontStyle]::Bold)
    for ($i=0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $source = [System.Drawing.Image]::FromFile((Join-Path $exportDir ($item.id + '_' + $item.slug + '_3840x2160.png')))
        $tile = Resize-Photo $source $tileW $tileH
        $x = ($i % $columns) * $tileW
        $y = [int][Math]::Floor($i / $columns) * ($tileH + $labelH)
        $g.DrawImageUnscaled($tile, $x, $y)
        $g.DrawString(($item.id + '  ' + $item.short), $font, [System.Drawing.Brushes]::White, [single]($x+10), [single]($y+$tileH+6))
        $tile.Dispose()
        $source.Dispose()
    }
    $g.Dispose()
    $font.Dispose()
    $sheet.Save((Join-Path $previewDir $name), [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $sheet.Dispose()
}
Make-Sheet 800 450 2 'Planche_8_Thumbnails.jpg'
Make-Sheet 320 180 2 'Controle_Mobile_320.jpg'

$readme = @'
SCOTT PULCINI - 8 THUMBNAILS - V03

Huit adaptations des references, avec les corrections de composition puis de couleur du polo.
Fichiers finaux : 8 PNG de 3840 x 2160 pixels, format 16:9.
IMPORTANT : exports agrandis par interpolation bicubique depuis les masters. Ce ne sont pas des creations natives 4K. Dimensions sources detaillees dans Manifest_exports.json. Aucun ajout de nettete pendant l'export.

Corrections :
01, 02, 04 : ecrans Bookmap issus de trois Download Still du podcast, recadres et assembles directement dans les ecrans du design. Aucun telechargement de video ou de proxy. Captures natives 1920 x 1080, meilleure qualite proposee par le lecteur final (1080p).
05 : Scott regarde le tableau noir et dessine au marqueur vert.
07 : Scott parle vers Riz qui l'ecoute.
08 : visage de Scott volontairement pixellise.
Tous : eclairage plus clair, typographie geometrique proche de Poppins et graisses plus variees. La police est rendue dans les images generees, ce n'est pas un document typographique editable.
Polos de Scott : blanc sur 01, 02, 04, 05, 06 ; noir sur 03, 07, 08.
Finition : 5 % de bruit gaussien monochromatique sur chacun des huit PNG, applique en derniere etape apres le redimensionnement 4K. Les masters sans bruit sont conserves. Parametre technique : ecart-type 12,75 sur 255, meme bruit dans les trois canaux couleur.
Recoloration du polo : les retouches generees ont ete assemblees dans un masque du polo d'origine ; visages, peau, mains, textes et captures de V02 conserves hors de ce masque, avant la finition de bruit finale.

Production : image_gen integre, compositions de reference et photos HD originales de Riz et Scott. Les portraits proviennent d'une composition generative avec references photographiques ; ils ne constituent pas un collage garanti pixel pour pixel des photos HD. Les insertions finales des plateformes sont des assemblages directs des captures du podcast. Les masters PNG sont aplatis, sans calques.
Le tableau blanc pedagogique de 06 est illustratif. Les tableaux noirs restent des supports de presentation, pas des captures de plateforme.

Organisation :
Sources_HD : originaux intacts, y compris les cinq captures Scott_OrderFlow.
Design - Ref : references intactes.
Masters/Scott_Pulcini_Thumbnails_V03 : huit masters finaux.
Exports_4K/Scott_Pulcini_Thumbnails_V03 : huit PNG 3840 x 2160.
Apercus/Scott_Pulcini_Thumbnails_V03 : planche, controle mobile et apercus individuels.
Suivi/Scott_Pulcini_Thumbnails_V03 : transcript, accroches, prompts, sources et controles.
V01 et masters V02 conserves.

Les titres restent des formulations editoriales fondees sur le transcript, pas des citations litterales. Les textes valides de V01 sont conserves ; aucun montant financier des anciennes references n'est attribue a Scott.
Aucune publication effectuee.
'@
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $follow 'LIRE_MOI.txt') -Value $readme
}
if ($RenderOnly) { Get-Content -Raw -LiteralPath (Join-Path $follow 'Manifest_exports.json'); exit 0 }
$manifest = Get-Content -Raw -LiteralPath (Join-Path $follow 'Manifest_exports.json') | ConvertFrom-Json

$zipPath = Join-Path $root 'Livraison\Scott_Pulcini_8_Thumbnails_V03_4K.zip'
if (Test-Path -LiteralPath $zipPath) { throw 'Le ZIP V03 existe déjà ; préserver cette version et créer une nouvelle version.' }
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($file in (Get-ChildItem -LiteralPath $exportDir -File -Filter '*.png')) { [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, ('PNG_4K/' + $file.Name), [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null }
foreach ($name in @('Planche_8_Thumbnails.jpg','Controle_Mobile_320.jpg')) { [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $previewDir $name), ('Apercus/' + $name), [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null }
foreach ($name in @('LIRE_MOI.txt','Accroches.txt','Prompts.txt','Manifest_exports.json','Corrections_et_sources.txt','Direct_screen_composites.json','Controle_qualite.txt')) { [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $follow $name), ('Suivi/' + $name), [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null }
$zip.Dispose()
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$pngCount = @($zip.Entries | Where-Object { $_.FullName -like 'PNG_4K/*.png' }).Count
$zip.Dispose()
if ($pngCount -ne 8) { throw ('Nombre incorrect de PNG : ' + $pngCount) }
$manifest | Format-Table id, master_width, master_height, export_width, export_height, upscaled
Get-Item -LiteralPath $zipPath | Select-Object FullName,Length
