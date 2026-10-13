$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$batchRoot = Split-Path $PSScriptRoot -Parent
$razvanRoot = Split-Path $batchRoot -Parent
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'generation_manifest.json') -Raw | ConvertFrom-Json
$uploadRoot = Join-Path $batchRoot 'YouTube_1280x720'
New-Item -ItemType Directory -Path $uploadRoot -Force | Out-Null

function Export-Image($Source, [int]$W, [int]$H, [string]$Path, [bool]$Jpeg=$false) {
    $bmp = [System.Drawing.Bitmap]::new($W,$H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
    $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $srcW = [double]$Source.Width
    $srcH = [double]$Source.Height
    if ($srcW/$srcH -gt $W/$H) { $srcW = $srcH*$W/$H } else { $srcH = $srcW*$H/$W }
    $srcX = ($Source.Width-$srcW)/2
    $srcY = ($Source.Height-$srcH)/2
    $g.DrawImage($Source,[System.Drawing.Rectangle]::new(0,0,$W,$H),[single]$srcX,[single]$srcY,[single]$srcW,[single]$srcH,[System.Drawing.GraphicsUnit]::Pixel,$attributes)
    if ($Jpeg) {
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
        $params = [System.Drawing.Imaging.EncoderParameters]::new(1)
        $params.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality,[long]95)
        $bmp.Save($Path,$codec,$params)
        $params.Dispose()
    } else { $bmp.Save($Path,[System.Drawing.Imaging.ImageFormat]::Png) }
    $attributes.Dispose()
    $g.Dispose()
    $bmp.Dispose()
}

$records = @()
foreach ($item in $manifest.items) {
    $stem = 'Razvan_{0:00}_{1}' -f $item.n,$item.slug
    $nativeImage = [System.Drawing.Image]::FromFile($item.generatedPath)
    $width = $nativeImage.Width
    $height = $nativeImage.Height
    $nativeImage.Dispose()
    $masterName = '{0}_master_{1}x{2}.png' -f $stem,$width,$height
    $masterPath = Join-Path (Join-Path $batchRoot 'masters') $masterName
    Copy-Item -LiteralPath $item.generatedPath -Destination $masterPath
    if ((Get-FileHash -LiteralPath $item.generatedPath).Hash -ne (Get-FileHash -LiteralPath $masterPath).Hash) { throw 'Master mismatch' }
    $im = [System.Drawing.Image]::FromFile($masterPath)
    Export-Image $im 3840 2160 (Join-Path (Join-Path $batchRoot 'exports_4K') ($stem+'_3840x2160.png'))
    Export-Image $im 1280 720 (Join-Path (Join-Path $batchRoot 'apercus') ($stem+'_preview.png'))
    Export-Image $im 320 180 (Join-Path (Join-Path $batchRoot 'apercus') ($stem+'_mobile.png'))
    Export-Image $im 1280 720 (Join-Path $uploadRoot ($stem+'_1280x720.jpg')) $true
    $im.Dispose()
    $records += [pscustomobject]@{Number=$item.n;Title=$item.title;Reference=$item.reference;Master=$masterName;NativeWidth=$width;NativeHeight=$height;ExportWidth=3840;ExportHeight=2160;ExportMethod='HighQualityBicubic; minimal center crop for exact 16:9';Stem=$stem;Evidence=$item.evidence}
}
$records | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'export_manifest.json') -Encoding utf8

$sourceRecords = @()
foreach ($name in ($manifest.items.inputs | Select-Object -Unique)) {
    $original = Join-Path (Join-Path $razvanRoot 'sources_HD') $name
    $copy = Join-Path (Join-Path $batchRoot 'sources_HD') $name
    Copy-Item -LiteralPath $original -Destination $copy
    $hash = (Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash
    if ($hash -ne (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash) { throw 'Source copy mismatch' }
    $sourceRecords += [pscustomobject]@{File=$name;SHA256=$hash;Width=3840;Height=2160;Origin='Frame.io native Download Still'}
}
$sourceRecords | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'source_manifest.json') -Encoding utf8

$sheet = [System.Drawing.Bitmap]::new(1920,1740)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(18,20,24))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font = [System.Drawing.Font]::new('Arial',20,[System.Drawing.FontStyle]::Bold)
foreach ($record in $records) {
    $i=$record.Number-1
    $x=($i%2)*960
    $y=[int][Math]::Floor($i/2)*580
    $g.DrawString(('{0:00}   {1}' -f $record.Number,$record.Title),$font,[System.Drawing.Brushes]::White,[single]($x+14),[single]($y+7))
    $im=[System.Drawing.Image]::FromFile((Join-Path (Join-Path $batchRoot 'apercus') ($record.Stem+'_preview.png')))
    $g.DrawImage($im,[int]$x,[int]($y+40),960,540)
    $im.Dispose()
}
$sheet.Save((Join-Path (Join-Path $batchRoot 'apercus') 'Planche_6_Thumbnails.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$sheet.Dispose()

$mobileSheet = [System.Drawing.Bitmap]::new(960,420)
$g = [System.Drawing.Graphics]::FromImage($mobileSheet)
$g.Clear([System.Drawing.Color]::FromArgb(18,20,24))
$mobileFont = [System.Drawing.Font]::new('Arial',14,[System.Drawing.FontStyle]::Bold)
foreach ($record in $records) {
    $i=$record.Number-1
    $x=($i%3)*320
    $y=[int][Math]::Floor($i/3)*210
    $g.DrawString(('{0:00}' -f $record.Number),$mobileFont,[System.Drawing.Brushes]::White,[single]($x+6),[single]($y+4))
    $im=[System.Drawing.Image]::FromFile((Join-Path (Join-Path $batchRoot 'apercus') ($record.Stem+'_mobile.png')))
    $g.DrawImageUnscaled($im,[int]$x,[int]($y+30))
    $im.Dispose()
}
$mobileSheet.Save((Join-Path (Join-Path $batchRoot 'apercus') 'QA_mobile_320x180.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$mobileSheet.Dispose()
$mobileFont.Dispose()
$font.Dispose()

$notes = @(
'PROP FIRM TRADER - RAZVAN - SIX REFERENCES V02',
'',
'6 nouveaux thumbnails adaptes un par un depuis les 6 fichiers du dossier Design - Ref.',
'Images creees avec le generateur integre image_gen, a partir de portraits et tableaux extraits de Frame.io.',
'Portraits principaux : 00:08:18:00 et 00:19:00:00. Regard plus frontal, luminosite et saturation augmentees.',
'Les images finales sont des compositions generees. Les sources_HD sont les captures natives inchangees.',
'',
'DOSSIERS',
'YouTube_1280x720 : 6 JPEG 16:9 pour utilisation directe.',
'exports_4K : 6 PNG 3840x2160.',
'masters : 6 fichiers originaux du generateur, conserves sans modification.',
'apercus : planche des 6, apercus individuels et controle a 320x180.',
'sources_HD : 7 captures Frame.io natives 3840x2160 utilisees comme references de contenu.',
'production : prompts complets, corrections, correspondance des references et verification technique.',
'',
'RESOLUTION',
'Le generateur a livre cinq masters de 1672x941 et un de 1671x941. Les PNG 3840x2160 sont des exports agrandis par interpolation bicubique de haute qualite, pas des generations 4K natives.',
'',
'ACCROCHES ET CORRESPONDANCE'
)
foreach($record in $records) {
    $notes += ('{0:00} - {1}' -f $record.Number,$record.Title)
    $notes += ('Reference : '+$record.Reference)
    $notes += ('Source podcast : '+$record.Evidence)
    $notes += ''
}
$notes += 'La somme de 158 000 USD en deux semaines est annoncee dans introduction du podcast, et non verifiee par un document de compte.'
$notes += 'Les 4R concernent exemple de re-entree apres deux trades a breakeven, distinct du resultat global annonce.'
$notes += 'Les durees de generation dans le manifeste sont des durees d appels incluant attente et file d attente. Ce ne sont pas des temps internes du modele.'
$notes | Set-Content -LiteralPath (Join-Path $batchRoot 'README.txt') -Encoding utf8

$checked = @()
foreach($file in (Get-ChildItem -LiteralPath $batchRoot -Recurse -File | Where-Object Extension -in @('.png','.jpg'))) {
    $im=[System.Drawing.Image]::FromFile($file.FullName)
    if($file.Directory.Name -eq 'exports_4K' -and ($im.Width -ne 3840 -or $im.Height -ne 2160)){throw 'Invalid 4K export'}
    if($file.Directory.Name -eq 'YouTube_1280x720' -and ($im.Width -ne 1280 -or $im.Height -ne 720 -or $file.Length -gt 2000000)){throw 'Invalid upload JPEG'}
    $checked += [pscustomobject]@{File=$file.FullName.Substring($batchRoot.Length+1);Width=$im.Width;Height=$im.Height;Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
    $im.Dispose()
}
$exportFiles = @(Get-ChildItem -LiteralPath (Join-Path $batchRoot 'exports_4K') -File)
if($exportFiles.Count -ne 6){throw 'Need exactly six exports'}
if(@($checked | Where-Object File -like 'exports_4K*' | Select-Object -ExpandProperty SHA256 -Unique).Count -ne 6){throw 'Duplicate exports'}
$checked | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'verification_images.json') -Encoding utf8
[pscustomobject]@{ImagesChecked=$checked.Count;Exports4K=$exportFiles.Count;UploadJpegs=6;NativeSources=$sourceRecords.Count;NativeMasters=($records | ForEach-Object {"$($_.NativeWidth)x$($_.NativeHeight)"} | Select-Object -Unique);Output=$batchRoot} | ConvertTo-Json

