$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path $PSScriptRoot
$exports=Join-Path $root 'Exports_4K\V02'
$delivery=Join-Path $root 'Livraison'
function Inspect($f,$kind){
 $im=[System.Drawing.Image]::FromFile($f.FullName);$w=$im.Width;$h=$im.Height;$im.Dispose()
 [pscustomobject]@{File=[System.IO.Path]::GetRelativePath($root,$f.FullName);Kind=$kind;Width=$w;Height=$h;Bytes=$f.Length;SHA256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash}
}
$final=@(Get-ChildItem -LiteralPath $exports -Filter '*.png' -File|Sort-Object Name)
if($final.Count -ne 8){throw 'Expected exactly eight final PNGs.'}
$manifest=@($final|ForEach-Object {Inspect $_ 'Final PNG / composite with enlarged components'})
if(@($manifest|Where-Object {$_.Width -ne 3840 -or $_.Height -ne 2160}).Count){throw 'Wrong export dimensions'}
$sources=@(Get-ChildItem -LiteralPath (Join-Path $root 'Sources_HD') -File -Recurse -Filter '*.jpg')
if($sources.Count -ne 54){throw 'Expected 54 native stills.'}
$sourceManifest=@($sources|ForEach-Object {Inspect $_ 'Native Frame.io Download Still / 2160p'})
if(@($sourceManifest|Where-Object {$_.Width -ne 3840 -or $_.Height -ne 2160}).Count){throw 'Wrong native still dimensions'}
foreach($subject in @('Casper','Riz','Tableau')){
 $old=Import-Csv -LiteralPath (Join-Path $PSScriptRoot ($subject+'_manifest.csv'))
 foreach($item in $old){$current=$sourceManifest|Where-Object {[System.IO.Path]::GetFileName($_.File) -eq $item.File};if($current.SHA256 -ne $item.SHA256){throw ('Original source changed: '+$item.File)}}
}
$manifest|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Exports_V02_manifest.csv')
$sourceManifest|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Sources_HD_manifest_complet.csv')
Get-ChildItem -LiteralPath (Join-Path $root 'Masters\V02') -Filter '*.png' -File|ForEach-Object {Inspect $_ 'Master / asset'}|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Masters_V02_manifest.csv')
$zip=Join-Path $delivery 'Casper_8_Thumbnails_V02_3840x2160.zip'
if(Test-Path -LiteralPath $zip){throw 'Archive already exists; preserve delivery versions.'}
Compress-Archive -LiteralPath $final.FullName -DestinationPath $zip -CompressionLevel Optimal
$a=[System.IO.Compression.ZipFile]::OpenRead($zip)
try{
 if($a.Entries.Count -ne 8){throw 'Unexpected ZIP entry count'}
 foreach($e in $a.Entries){$stream=$e.Open();$sha=[System.Security.Cryptography.SHA256]::Create();try{$hash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()};$m=$manifest|Where-Object {[System.IO.Path]::GetFileName($_.File) -eq $e.Name};if(!$m -or $m.SHA256 -ne $hash){throw ('ZIP mismatch: '+$e.Name)}}
}finally{$a.Dispose()}
$report=[ordered]@{Version='V02';Date='2026-10-12';PNGCount=8;Width=3840;Height=2160;NativeSourceCount=54;OriginalSourceHashesUnchanged=$true;SourceVideoOrProxyDownloaded=$false;CreationEntirelyNative4K=$false;ArchiveFile=[System.IO.Path]::GetFileName($zip);ArchiveEntries=8;ArchivePayloadHashesMatch=$true;ArchiveBytes=(Get-Item -LiteralPath $zip).Length;ArchiveSHA256=(Get-FileHash -LiteralPath $zip).Hash;VisualReview='All 8 designs at 1280px and 320px, plus native 100% face crops; source face-core opaque pixels matched exactly before resizing and grain.'}
$report|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_V02.json') -Encoding utf8
$package=Join-Path $delivery 'Casper_Projet_Complet_V02.zip'
if(Test-Path -LiteralPath $package){throw 'Full package already exists; preserve delivery versions.'}
$items=@('Sources_HD','Selections','References','Masters','Exports_4K','Apercus','Suivi','LISEZ_MOI.txt')|ForEach-Object {Join-Path $root $_}
Compress-Archive -LiteralPath $items -DestinationPath $package -CompressionLevel Optimal
$a=[System.IO.Compression.ZipFile]::OpenRead($package)
try{
 $files=@($a.Entries|Where-Object {$_.Name})
 $pngs=@($files|Where-Object {$_.FullName.Replace('\','/') -match '^Exports_4K/V02/.*\.png$'})
 if($pngs.Count -ne 8){throw 'Full package missing exports'}
 foreach($e in $files){$disk=Join-Path $root $e.FullName;if(!(Test-Path -LiteralPath $disk)){throw ('Unknown package entry: '+$e.FullName)};$stream=$e.Open();$sha=[System.Security.Cryptography.SHA256]::Create();try{$hash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()};if($hash -ne (Get-FileHash -LiteralPath $disk).Hash){throw ('Package mismatch: '+$e.FullName)}}
 $packageReport=[ordered]@{File=[System.IO.Path]::GetFileName($package);Entries=$a.Entries.Count;Files=$files.Count;FinalPNGs=$pngs.Count;AllPayloadHashesMatch=$true;Bytes=(Get-Item -LiteralPath $package).Length;SHA256=(Get-FileHash -LiteralPath $package).Hash}
}finally{$a.Dispose()}
$packageReport|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $delivery 'Verification_Projet_Complet_V02.json') -Encoding utf8
$report|ConvertTo-Json -Compress
$packageReport|ConvertTo-Json -Compress
