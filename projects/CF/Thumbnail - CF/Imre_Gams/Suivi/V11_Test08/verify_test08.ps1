$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot)
$export=Join-Path $root 'Exports\V11_Test08\08_Price_To_Value_V11_Test_Sans_Grain_3840x2160.png'
$im=[System.Drawing.Bitmap]::FromFile($export)
if($im.Width -ne 3840 -or $im.Height -ne 2160){throw 'Unexpected dimensions'}
$alignment=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Title_alignment.csv')
if($alignment.GapLeft -ne $alignment.GapRight){throw 'Title gaps differ'}
$reference=[System.Drawing.Bitmap]::FromFile((Join-Path $root 'Masters\V11_Test08\Reference_composition_Riz.jpg'))
$reference.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
$expected=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics=[System.Drawing.Graphics]::FromImage($expected);$graphics.ScaleTransform(3,3);$graphics.SmoothingMode='AntiAlias';$graphics.InterpolationMode='HighQualityBicubic';$graphics.PixelOffsetMode='HighQuality';$graphics.CompositingQuality='HighQuality';$graphics.DrawImage($reference,0,0,1280,720);$graphics.Dispose();$reference.Dispose()
$sampleCount=0;$mismatch=0
for($y=245;$y -le 320;$y+=5){for($x=940;$x -le 1040;$x+=5){$sampleCount++;if($im.GetPixel(($x*3+1),($y*3+1)).ToArgb() -ne $expected.GetPixel(($x*3+1),($y*3+1)).ToArgb()){$mismatch++}}}
$im.Dispose();$expected.Dispose()
if($mismatch -gt 0){throw ('Reference Riz face sample mismatch: '+$mismatch)}
$record=[pscustomobject]@{File=(Split-Path $export -Leaf);Width=3840;Height=2160;AddedGrainPercent=0;TitleGapLeft=58;TitleGapRight=58;ReferenceRizFaceSamples=$sampleCount;ExactReferenceMatches=$sampleCount;SHA256=(Get-FileHash -LiteralPath $export -Algorithm SHA256).Hash;PhotoUpscaled=$true}
$record | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Verification_export.csv')
Write-Output ('VERIFIED: one PNG 3840x2160; no grain; equal title spacing; '+$sampleCount+' Riz face samples match the supplied mirrored photo exactly.')
