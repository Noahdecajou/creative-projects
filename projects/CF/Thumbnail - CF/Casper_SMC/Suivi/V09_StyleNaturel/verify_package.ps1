$ErrorActionPreference='Stop';Add-Type -AssemblyName System.Drawing;Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path (Split-Path $PSScriptRoot);$v='V09_StyleNaturel';$delivery=Join-Path $root 'Livraison'
function Details($path){$f=Get-Item -LiteralPath $path;$im=[System.Drawing.Image]::FromFile($f.FullName);$w=$im.Width;$h=$im.Height;$im.Dispose();[pscustomobject]@{File=[System.IO.Path]::GetRelativePath($root,$f.FullName);Width=$w;Height=$h;Bytes=$f.Length;SHA256=(Get-FileHash -LiteralPath $f.FullName).Hash}}
$exports=@(Get-ChildItem -LiteralPath (Join-Path $root ('Exports_4K\'+$v)) -Filter '*.png' -File)
if($exports.Count -ne 1){throw 'Exactly one final thumbnail required'}
$export=Details $exports[0].FullName;$master=Details (Join-Path $root ('Masters\'+$v+'\09_Trading_In_3_Decisions_Natural_master.png'))
if($export.Width -ne 3840 -or $export.Height -ne 2160){throw 'Incorrect final dimensions'}
if($export.SHA256 -ne $master.SHA256){throw 'Unexpected export effect or grain'}
@($export,$master)|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Final_manifest.csv')
$sourceReport=foreach($row in (Import-Csv -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'Sources_HD_manifest_complet.csv'))){if((Get-FileHash -LiteralPath (Join-Path $root $row.File)).Hash -ne $row.SHA256){throw ('Original changed: '+$row.File)};[pscustomobject]@{File=$row.File;Unchanged=$true}}
if(@($sourceReport).Count -ne 54){throw 'Expected 54 original stills'}
$sourceReport|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Original_sources_verified.csv')
$old=foreach($manifest in @('Suivi\V07\Exports_V07_manifest.csv','Suivi\V09_StyleNaturel\V08_baseline.csv')){foreach($row in (Import-Csv -LiteralPath (Join-Path $root $manifest))){if((Get-FileHash -LiteralPath (Join-Path $root $row.File)).Hash -ne $row.SHA256){throw ('Previous export changed: '+$row.File)};[pscustomobject]@{File=$row.File;ByteIdentical=$true}}}
$old|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Previous_exports_preserved.csv')
$type=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Typography_manifest.json') -Raw|ConvertFrom-Json
if($type.Text -ne 'Trading in 3 decisions.' -or $type.X -lt 35 -or ($type.X+$type.TotalWidth) -gt 1245 -or $type.AddedGrain){throw 'Copy, margins or grain invalid'}
$photo=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Photographic_verification.json') -Raw|ConvertFrom-Json
if($photo.OriginalCasperFaceRGBChangedPixels -ne 0 -or $photo.OriginalCasperNeckRGBChangedPixels -ne 0 -or $photo.FaceWarp){throw 'Photo preservation failed'}
function ZipCreate($path,$members,$flat=$false){if(Test-Path -LiteralPath $path){throw 'Archive already exists'};$z=[System.IO.Compression.ZipFile]::Open($path,[System.IO.Compression.ZipArchiveMode]::Create);try{foreach($f in $members){$name=if($flat){$f.Name}else{[System.IO.Path]::GetRelativePath($root,$f.FullName).Replace('\','/')};$null=[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,$f.FullName,$name,[System.IO.Compression.CompressionLevel]::Optimal)}}finally{$z.Dispose()}}
function ZipVerify($path,$members,$flat=$false){$z=[System.IO.Compression.ZipFile]::OpenRead($path);try{if($z.Entries.Count -ne $members.Count){throw 'ZIP count mismatch'};foreach($e in $z.Entries){$f=if($flat){$members|Where-Object {$_.Name -eq $e.Name}|Select-Object -First 1}else{Get-Item -LiteralPath (Join-Path $root $e.FullName)};$stream=$e.Open();$sha=[System.Security.Cryptography.SHA256]::Create();try{$hash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()};if($hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash){throw 'ZIP payload mismatch'}};return $z.Entries.Count}finally{$z.Dispose()}}
$zip=Join-Path $delivery 'Casper_09_Style_Naturel_V09_3840x2160.zip';ZipCreate $zip $exports $true;$count=ZipVerify $zip $exports $true
$report=[ordered]@{Version=$v;Date='2026-10-15';PNGCount=1;Width=3840;Height=2160;Native4K=$false;GeneratedPlateDimensions='1672x941';AddedGrain=$false;OriginalSourcesUnchanged=54;PreviousExportsUnchanged=@($old).Count;FacePhotoVerification=$photo;Text=$type.Text;NativeTypography=$true;MasterEqualsFinalExport=$true;VisualReview='1280 and 320 previews, original photographic head and neck, hair boundary, glasses, collar and hands';Archive=[System.IO.Path]::GetFileName($zip);ArchiveEntries=$count;ArchivePayloadHashesMatch=$true;ArchiveSHA256=(Get-FileHash -LiteralPath $zip).Hash}
$report|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_V09.json') -Encoding utf8
$members=[System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach($folder in @(('Masters\'+$v),('Exports_4K\'+$v),('Apercus\'+$v),('Suivi\'+$v),'References\StyleNaturel_V08','Suivi\Fonts')){foreach($f in (Get-ChildItem -LiteralPath (Join-Path $root $folder) -Recurse -File)){$members.Add($f)}}
foreach($path in @('LISEZ_MOI_V09_StyleNaturel.txt','Sources_HD\Casper\Casper_00-12-00.jpg','Sources_HD\Riz\Riz_01-16-00.jpg','Masters\V01\Casper_00-12-00_cutout.png','Suivi\Transcript_Frameio_lu.txt')){$members.Add((Get-Item -LiteralPath (Join-Path $root $path)))}
$prod=Join-Path $delivery 'Casper_09_Style_Naturel_V09_Production.zip';ZipCreate $prod $members;$prodCount=ZipVerify $prod $members
$p=[pscustomobject]@{File=[System.IO.Path]::GetFileName($prod);Entries=$prodCount;AllPayloadHashesMatch=$true;Bytes=(Get-Item -LiteralPath $prod).Length;SHA256=(Get-FileHash -LiteralPath $prod).Hash};$p|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $delivery 'Verification_Production_V09_StyleNaturel.json') -Encoding utf8
$report|ConvertTo-Json -Compress;$p|ConvertTo-Json -Compress
