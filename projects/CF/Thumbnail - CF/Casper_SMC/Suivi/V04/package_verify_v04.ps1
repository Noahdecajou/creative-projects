$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path (Split-Path $PSScriptRoot);$delivery=Join-Path $root 'Livraison'
function Info($file,$kind){$im=[System.Drawing.Image]::FromFile($file.FullName);$w=$im.Width;$h=$im.Height;$im.Dispose();[pscustomobject]@{File=[System.IO.Path]::GetRelativePath($root,$file.FullName);Kind=$kind;Width=$w;Height=$h;Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}}
$files=@(Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V04') -File -Filter '*.png'|Sort-Object Name)
if($files.Count -ne 8){throw 'Eight PNGs required'}
$manifest=@($files|ForEach-Object {Info $_ 'Final enlarged composite'})
if(@($manifest|Where-Object {$_.Width -ne 3840 -or $_.Height -ne 2160}).Count){throw 'Incorrect export dimensions'}
$manifest|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Exports_V04_manifest.csv')
$masters=@(Get-ChildItem -LiteralPath (Join-Path $root 'Masters\V04') -File -Filter '*_master.png')
if($masters.Count -ne 8){throw 'Eight final masters required'}
$masters|ForEach-Object {Info $_ 'Master without final grain'}|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Masters_V04_manifest.csv')
Get-ChildItem -LiteralPath (Join-Path $root 'Masters\V04') -Filter '*generated.png' -File|ForEach-Object {Info $_ 'ImageGen component, pre-enlargement'}|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Generated_components_manifest.csv')
$sourceFiles=@(Get-ChildItem -LiteralPath (Join-Path $root 'Sources_HD') -Recurse -File -Filter '*.jpg')
if($sourceFiles.Count -ne 54){throw 'Expected 54 original stills'}
$sourceChecks=foreach($person in @('Casper','Riz','Tableau')){foreach($row in (Import-Csv -LiteralPath (Join-Path (Split-Path $PSScriptRoot) ($person+'_manifest.csv')))){$file=Join-Path $root ('Sources_HD\'+$person+'\'+$row.File);$hash=(Get-FileHash -LiteralPath $file).Hash;if($hash -ne $row.SHA256){throw ('Source changed: '+$row.File)};[pscustomobject]@{File=$row.File;OriginalSHA256Unchanged=$true}}}
$sourceChecks|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Original_sources_verified.csv')
function CreateZip($path,$members,$flat=$false){if(Test-Path -LiteralPath $path){throw ('Archive exists: '+$path)};$archive=[System.IO.Compression.ZipFile]::Open($path,[System.IO.Compression.ZipArchiveMode]::Create);try{foreach($file in $members){$entry=if($flat){$file.Name}else{[System.IO.Path]::GetRelativePath($root,$file.FullName).Replace('\','/')};$null=[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$file.FullName,$entry,[System.IO.Compression.CompressionLevel]::Optimal)}}finally{$archive.Dispose()}}
function VerifyZip($path,$expected,$flat=$false){$a=[System.IO.Compression.ZipFile]::OpenRead($path);try{if($a.Entries.Count -ne $expected.Count){throw 'ZIP count mismatch'};foreach($entry in $a.Entries){$disk=if($flat){$expected|Where-Object {$_.Name -eq $entry.Name}|Select-Object -First 1}else{Get-Item -LiteralPath (Join-Path $root $entry.FullName)};$stream=$entry.Open();$sha=[System.Security.Cryptography.SHA256]::Create();try{$hash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()};if($hash -ne (Get-FileHash -LiteralPath $disk.FullName).Hash){throw ('Archive hash mismatch: '+$entry.FullName)}};return $a.Entries.Count}finally{$a.Dispose()}}
$zip=Join-Path $delivery 'Casper_8_Thumbnails_V04_3840x2160.zip';CreateZip $zip $files $true;$zipCount=VerifyZip $zip $files $true
$report=[ordered]@{Version='V04';Date='2026-10-12';PNGCount=8;MasterCount=8;Width=3840;Height=2160;Native4K=$false;OriginalSourceCount=54;OriginalSourceHashesUnchanged=$true;VideoOrProxyDownloaded=$false;FinalGrain='5 percent uniform monochromatic, single final pass';VisualReview='All eight previews at 320 and 1280 pixels; native eye crops on 01, 02, 04, 06; marker diagrams and luminous blue panels inspected';ModifiedThumbnails=@('01','02','04','06','08');IdenticalToV03=@('03','05','07');LocalPixelComparison='Pixel_comparison_V03_V04.csv';Archive=[System.IO.Path]::GetFileName($zip);ArchiveEntries=$zipCount;ArchivePayloadHashesMatch=$true;ArchiveBytes=(Get-Item -LiteralPath $zip).Length;ArchiveSHA256=(Get-FileHash -LiteralPath $zip).Hash}
$report|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_V04.json') -Encoding utf8
$members=New-Object System.Collections.Generic.List[System.IO.FileInfo]
foreach($folder in @('Sources_HD','Selections','References','Masters\V04','Exports_4K\V04','Apercus\V04','Suivi\V04','Suivi\Fonts')){foreach($f in (Get-ChildItem -LiteralPath (Join-Path $root $folder) -Recurse -File)){$members.Add($f)}}
foreach($path in @('LISEZ_MOI_V04.txt','LISEZ_MOI_V03.txt','Suivi\drawing_functions.ps1','Suivi\Transcript_Frameio_lu.txt','Suivi\Notes_editoriales.txt','Suivi\Sources_HD_manifest_complet.csv','Suivi\Casper_manifest.csv','Suivi\Riz_manifest.csv','Suivi\Tableau_manifest.csv','Masters\V03\Casper_front_photo.png','Suivi\V03\render_v03.ps1')){$members.Add((Get-Item -LiteralPath (Join-Path $root $path)))}
$production=Join-Path $delivery 'Casper_Production_V04.zip';CreateZip $production $members;$count=VerifyZip $production $members
$prod=[ordered]@{File=[System.IO.Path]::GetFileName($production);Files=$count;AllPayloadHashesMatch=$true;Bytes=(Get-Item -LiteralPath $production).Length;SHA256=(Get-FileHash -LiteralPath $production).Hash}
$prod|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $delivery 'Verification_Production_V04.json') -Encoding utf8
$report|ConvertTo-Json -Compress;$prod|ConvertTo-Json -Compress

