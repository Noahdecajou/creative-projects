. 'C:\Users\notti\Documents\ChatGPT\Thumbnail - CF\add_final_noise.ps1'
$projectPath = Split-Path $PSScriptRoot
$sourcePath = Join-Path $projectPath 'Stories_V02'
$outputPath = Join-Path $projectPath 'Stories_V03_Grain_4pct'
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
$inputs = @(Get-ChildItem -LiteralPath $sourcePath -Filter '*.png' -File | Sort-Object Name)
if ($inputs.Count -ne 8) { throw 'Expected eight source stories.' }
$records = @()
$index = 0
foreach ($inputFile in $inputs) {
    $original = [System.Drawing.Bitmap]::new($inputFile.FullName)
    $bitmap = [System.Drawing.Bitmap]::new($original.Width,$original.Height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $canvas = [System.Drawing.Graphics]::FromImage($bitmap)
    $canvas.DrawImageUnscaled($original,0,0)
    $canvas.Dispose()
    $original.Dispose()
    [ThumbnailNoise]::Apply($bitmap,4.0,131026+$index)
    $destination = Join-Path $outputPath $inputFile.Name
    $bitmap.Save($destination,[System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    $check = [System.Drawing.Bitmap]::new($destination)
    if ($check.Width -ne 1080 -or $check.Height -ne 1920) { throw 'Unexpected export dimensions.' }
    $check.Dispose()
    $records += [pscustomobject]@{file=$inputFile.Name;dimensions=@(1080,1920);grain_percent=4;sigma=10.2;grain='Gaussian monochromatic, same noise in RGB channels';seed=131026+$index}
    $index++
}
$archivePath = Join-Path $projectPath 'Casper_8_Stories_V03_Grain_4pct_1080x1920.zip'
Compress-Archive -Path (Join-Path $outputPath '*.png') -DestinationPath $archivePath -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    if ($archive.Entries.Count -ne 8) { throw 'Unexpected ZIP contents.' }
    foreach ($entry in $archive.Entries) {
        $stream = $entry.Open()
        $decoded = [System.Drawing.Bitmap]::new($stream)
        if ($decoded.Width -ne 1080 -or $decoded.Height -ne 1920) { throw 'Unexpected archived dimensions.' }
        $decoded.Dispose()
        $stream.Dispose()
    }
} finally { $archive.Dispose() }
$records | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $projectPath 'Suivi\Verification_grain_V03.json') -Encoding utf8
Write-Output ('Verified: {0} PNG, 1080 x 1920, 4 percent grain; ZIP {1}' -f $records.Count,$archivePath)

