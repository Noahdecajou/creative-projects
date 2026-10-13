$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$batchRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent (Split-Path -Parent $batchRoot)
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
foreach ($subfolder in @('PNG_1080x1920','JPEG_1080x1920','masters','sources_originales','apercus')) {
    New-Item -ItemType Directory -Path (Join-Path $batchRoot $subfolder) -Force | Out-Null
}
$previousRoot = Join-Path $workspaceRoot 'outputs\Razvan_Stories_v01\masters'
New-Item -ItemType Directory -Path $previousRoot -Force | Out-Null
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$jpegParameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
$jpegParameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, [long]95)
$verification = @()
foreach ($item in $manifest.items) {
    $stem = 'Razvan_{0:00}_{1}' -f $item.n,$item.slug
    Copy-Item -LiteralPath $item.originalGenerated -Destination (Join-Path $previousRoot ($stem + '_v01_native.png'))
    Copy-Item -LiteralPath $item.correctedGenerated -Destination (Join-Path $batchRoot ('masters\' + $stem + '_v02_native.png'))
    foreach ($sourceFile in @($item.correctionInputs | Select-Object -Skip 1)) {
        Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $batchRoot ('sources_originales\' + [IO.Path]::GetFileName($sourceFile)))
    }
    $sourceImage = [System.Drawing.Image]::FromFile($item.correctedGenerated)
    $exportBitmap = [System.Drawing.Bitmap]::new(1080,1920,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($exportBitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($sourceImage,[System.Drawing.Rectangle]::new(0,0,1080,1920))
    $pngFile = Join-Path $batchRoot ('PNG_1080x1920\' + $stem + '_v02.png')
    $jpgFile = Join-Path $batchRoot ('JPEG_1080x1920\' + $stem + '_v02.jpg')
    $exportBitmap.Save($pngFile,[System.Drawing.Imaging.ImageFormat]::Png)
    $exportBitmap.Save($jpgFile,$jpegCodec,$jpegParameters)
    $verification += [pscustomobject]@{Number=$item.n;NativeWidth=$sourceImage.Width;NativeHeight=$sourceImage.Height;ExportWidth=1080;ExportHeight=1920;ExportMethod='High quality resize, no additional sharpening';PNG=$pngFile;JPEG=$jpgFile;SHA256=(Get-FileHash -LiteralPath $pngFile -Algorithm SHA256).Hash}
    $graphics.Dispose(); $exportBitmap.Dispose(); $sourceImage.Dispose()
}
$verification | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'verification.json') -Encoding utf8
$contactBitmap = [System.Drawing.Bitmap]::new(1080,1360)
$contactGraphics = [System.Drawing.Graphics]::FromImage($contactBitmap)
$contactGraphics.Clear([System.Drawing.Color]::FromArgb(18,20,22))
$contactGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$labelFont = [System.Drawing.Font]::new('Arial',15,[System.Drawing.FontStyle]::Bold)
for($index=0;$index -lt 6;$index++) {
    $column = $index % 3; $row = [math]::Floor($index / 3)
    $x = [int]($column * 360); $y = [int]($row * 680)
    $contactGraphics.DrawString(('{0:00}  {1}' -f ($index+1),$manifest.items[$index].slug.Replace('_',' ')),$labelFont,[System.Drawing.Brushes]::White,[float]($x+10),[float]($y+8))
    $contactImage = [System.Drawing.Image]::FromFile($verification[$index].PNG)
    $contactGraphics.DrawImage($contactImage,[System.Drawing.Rectangle]::new($x,$y+40,360,640))
    $contactImage.Dispose()
}
$contactBitmap.Save((Join-Path $batchRoot 'apercus\Planche_6_Stories_v02.jpg'),$jpegCodec,$jpegParameters)
$contactGraphics.Dispose(); $contactBitmap.Dispose(); $labelFont.Dispose(); $jpegParameters.Dispose()
@'
RAZVAN — 6 INSTAGRAM STORIES — V02

PNG_1080x1920: six fichiers PNG prêts à utiliser.
JPEG_1080x1920: les mêmes six stories en JPEG qualité 95.
masters: fichiers natifs générés, avant redimensionnement.
sources_originales: captures originales utilisées à nouveau pour chaque correction des portraits.
apercus: planche des six stories.
production: prompts, correspondance avec les thumbnails, script et vérification.

Correction V02: texture de peau adoucie, portraits plus éclairés et moins contrastés. Identité guidée par les captures originales, et mise en page guidée par les stories approuvées.
Les exports 1080x1920 sont redimensionnés depuis les masters natifs ; aucune netteté supplémentaire n'est appliquée.
Les six stories correspondent aux six dernières thumbnails Razvan v04.
Sans date ou horaire fournis : footer FULL PODCAST, Spotify et YouTube.
Les versions initiales sont conservées séparément dans outputs/Razvan_Stories_v01/masters.
Outil : image_gen intégré.
'@ | Set-Content -LiteralPath (Join-Path $batchRoot 'README.txt') -Encoding utf8
$zipFile = Join-Path (Split-Path -Parent $batchRoot) 'Razvan_Stories_v02.zip'
if(Test-Path -LiteralPath $zipFile) { throw 'ZIP already exists; use a new version.' }
[System.IO.Compression.ZipFile]::CreateFromDirectory($batchRoot,$zipFile,[System.IO.Compression.CompressionLevel]::Optimal,$false)
$archive = [System.IO.Compression.ZipFile]::OpenRead($zipFile)
$zipPNGs = @($archive.Entries | Where-Object FullName -like 'PNG_1080x1920/*')
$zipJPEGs = @($archive.Entries | Where-Object FullName -like 'JPEG_1080x1920/*')
if($zipPNGs.Count -ne 6 -or $zipJPEGs.Count -ne 6) { throw 'Final export count mismatch.' }
$verifiedCount = 0
foreach($entry in $archive.Entries) {
    $localFile = Join-Path $batchRoot $entry.FullName
    $entryStream = $entry.Open()
    $hasher = [Security.Cryptography.SHA256]::Create()
    $entryHash = [BitConverter]::ToString($hasher.ComputeHash($entryStream)).Replace('-','')
    $entryStream.Dispose(); $hasher.Dispose()
    if($entryHash -ne (Get-FileHash -LiteralPath $localFile -Algorithm SHA256).Hash) { throw ('Hash mismatch: ' + $entry.FullName) }
    $verifiedCount++
}
$archive.Dispose()
[pscustomobject]@{Archive=$zipFile;PNGCount=$zipPNGs.Count;JPEGCount=$zipJPEGs.Count;FilesVerifiedSHA256=$verifiedCount;ArchiveBytes=(Get-Item -LiteralPath $zipFile).Length} | ConvertTo-Json
