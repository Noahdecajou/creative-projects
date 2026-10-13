$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
$root=Split-Path $PSScriptRoot -Parent
$baseDir=Split-Path $root -Parent
$zipPath=Join-Path $baseDir 'Sampsa_Jeppez_V01_Package.zip'
$final=Join-Path $root 'exports_4K\Sampsa_Jeppez_V01_12K_to_5M_Grain4_3840x2160.png'
$im=[Drawing.Image]::FromFile($final)
if($im.Width -ne 3840 -or $im.Height -ne 2160){throw 'Invalid final dimensions'}
$im.Dispose()
$sources=@(Get-ChildItem -LiteralPath (Join-Path $root 'sources_HD') -Recurse -File)
if($sources.Count -ne 24){throw 'Expected 24 selected native stills'}
foreach($source in $sources){$im=[Drawing.Image]::FromFile($source.FullName);if($im.Width -ne 1920 -or $im.Height -ne 1080){throw 'Source dimensions mismatch'};$im.Dispose()}
$meta=[ordered]@{Guest='Sampsa Jeppez';Project='Words of Rizdom';Version='V01';FinalWidth=3840;FinalHeight=2160;Native4K=$false;SourceWidth=1920;SourceHeight=1080;GeneratedBaseWidth=1672;GeneratedBaseHeight=941;NativeStillsReviewed=50;SelectedStills=24;SampsaSelected=20;RizSelected=4;FinalVariants=1;GrainAmount=0.04;GrainDistribution='Uniform monochromatic +/- 4% of 255';Seed=20261012;ExactTitle='$12K TO $5M';VideoDownloaded=$false;ProxyDownloaded=$false;FinalSHA256=(Get-FileHash -LiteralPath $final).Hash}
$meta | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification.json') -Encoding utf8
$files=@(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {$_.FullName -notmatch '\\candidates\\' -and $_.Name -notmatch '_grid\.jpg$|^Selection_Contact_|^01_00-01-23\.jpg$|^collect\.ps1$|^curate\.ps1$'})
if(Test-Path -LiteralPath $zipPath){throw 'Archive already exists; use a new version instead of overwriting'}
$zip=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
foreach($file in $files){$rel=$file.FullName.Substring($root.Length+1).Replace('\','/');[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,$rel,[IO.Compression.CompressionLevel]::Optimal)|Out-Null}
$zip.Dispose()
$zip=[IO.Compression.ZipFile]::OpenRead($zipPath);$checked=0
foreach($entry in $zip.Entries){
 $file=Join-Path $root $entry.FullName
 if($entry.Length -ne (Get-Item -LiteralPath $file).Length){throw ('ZIP size mismatch: '+$entry.FullName)}
 $stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[Convert]::ToHexString($sha.ComputeHash($stream));$stream.Dispose();$sha.Dispose()
 if($hash -ne (Get-FileHash -LiteralPath $file).Hash){throw ('ZIP hash mismatch: '+$entry.FullName)}
 $checked++
}
$zip.Dispose()
$result=[ordered]@{Archive=$zipPath;EntryCount=$checked;AllEntrySizesAndSHA256Match=$true;ArchiveBytes=(Get-Item -LiteralPath $zipPath).Length;ArchiveSHA256=(Get-FileHash -LiteralPath $zipPath).Hash;FinalPNGBytes=(Get-Item -LiteralPath $final).Length;FinalWidth=3840;FinalHeight=2160}
$result | ConvertTo-Json | Tee-Object -FilePath (Join-Path $baseDir 'Sampsa_Jeppez_V01_ZIP_Verification.json')
