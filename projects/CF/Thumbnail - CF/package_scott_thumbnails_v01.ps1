$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = $PSScriptRoot
$follow = Join-Path $root 'Suivi\Scott_Pulcini_Thumbnails_V01'
$masterDir = Join-Path $root 'Masters\Scott_Pulcini_Thumbnails_V01'
$exportDir = Join-Path $root 'Exports_4K\Scott_Pulcini_Thumbnails_V01'
$previewDir = Join-Path $root 'Apercus\Scott_Pulcini_Thumbnails_V01'
$items = Get-Content -Raw -LiteralPath (Join-Path $follow 'Generated_sources.json') | ConvertFrom-Json

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
    $export.Save($exportPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $export.Dispose()
    $small = Resize-Photo $source 320 180
    $small.Save((Join-Path $previewDir ($item.id + '_mobile_320x180.png')), [System.Drawing.Imaging.ImageFormat]::Png)
    $small.Dispose()
    $preview = Resize-Photo $source 1280 720
    $preview.Save((Join-Path $previewDir ($item.id + '_apercu.jpg')), [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $preview.Dispose()
    $check = [System.Drawing.Image]::FromFile($exportPath)
    if ($check.Width -ne 3840 -or $check.Height -ne 2160) { throw ('Dimensions incorrectes : ' + $exportPath) }
    $manifest += [pscustomobject]@{ id=$item.id; title=$item.title; reference=$item.ref; file=$exportName; master_width=$source.Width; master_height=$source.Height; export_width=$check.Width; export_height=$check.Height; upscaled=($source.Width -lt 3840); status='Cree - non publie' }
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
        $source = [System.Drawing.Image]::FromFile((Join-Path $masterDir ($item.id + '_' + $item.slug + '_master.png')))
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
SCOTT PULCINI — 8 THUMBNAILS — V01

Huit adaptations, une par fichier du dossier Design - Ref.
Fichiers finaux : 8 PNG de 3840 x 2160 pixels, 16:9.
IMPORTANT : exports agrandis par interpolation bicubique depuis les masters générés. Ce ne sont pas des créations natives 4K. Les dimensions originales de chaque master figurent dans Manifest_exports.json. Aucun ajout de netteté ou de détails de peau pendant l'agrandissement.

Production : image_gen intégré, références de design fournies, photos HD originales de Riz et Scott exportées avec Download Still dans Frame.io. Les compositions sont génératives à partir des photographies ; elles ne constituent pas un collage garanti pixel pour pixel. Les PNG masters sont aplatis, sans calques.
Les tableaux intégrés ont été adaptés à la composition. La version 06 utilise un tableau pédagogique illustratif ; ce n'est pas une capture de plateforme de trading.

Organisation dans le dossier de travail :
- Sources_HD : photographies originales conservées intactes.
- Design - Ref : références intactes.
- Masters/Scott_Pulcini_Thumbnails_V01 : 8 PNG à leur résolution générée.
- Exports_4K/Scott_Pulcini_Thumbnails_V01 : 8 PNG finaux.
- Apercus/Scott_Pulcini_Thumbnails_V01 : planche générale, contrôle mobile et aperçus individuels.
- Suivi/Scott_Pulcini_Thumbnails_V01 : transcript, accroches, prompts et manifestes.

Les accroches sont des formulations éditoriales fondées sur le transcript, et non des citations littérales. Aucun ancien montant financier des références n'a été attribué à Scott.
Aucune publication effectuée.
'@
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $follow 'LIRE_MOI.txt') -Value $readme

$zipPath = Join-Path $root 'Livraison\Scott_Pulcini_8_Thumbnails_V01_4K.zip'
if (Test-Path -LiteralPath $zipPath) { throw 'Le ZIP V01 existe déjà ; préserver cette version et créer une nouvelle version.' }
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($file in (Get-ChildItem -LiteralPath $exportDir -File -Filter '*.png')) { [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, ('PNG_4K/' + $file.Name), [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null }
foreach ($name in @('Planche_8_Thumbnails.jpg','Controle_Mobile_320.jpg')) { [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $previewDir $name), ('Apercus/' + $name), [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null }
foreach ($name in @('LIRE_MOI.txt','Accroches.txt','Prompts.txt','Manifest_exports.json')) { [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $follow $name), ('Suivi/' + $name), [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null }
$zip.Dispose()
$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
$pngCount = @($zip.Entries | Where-Object { $_.FullName -like 'PNG_4K/*.png' }).Count
$zip.Dispose()
if ($pngCount -ne 8) { throw ('Nombre incorrect de PNG : ' + $pngCount) }
$manifest | Format-Table id, master_width, master_height, export_width, export_height, upscaled
Get-Item -LiteralPath $zipPath | Select-Object FullName,Length
