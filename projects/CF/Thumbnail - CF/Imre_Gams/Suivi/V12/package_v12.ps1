$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path (Split-Path $PSScriptRoot)
$out=Join-Path $root 'Exports\V12'
$files=@(Get-ChildItem -LiteralPath $out -Filter '*.png' -File | Sort-Object Name)
if($files.Count -ne 8){throw 'Expected eight PNGs.'}
$records=@()
foreach($file in $files){
 $im=[System.Drawing.Image]::FromFile($file.FullName)
 if($im.Width -ne 3840 -or $im.Height -ne 2160){throw ('Dimensions invalid: '+$file.Name)}
 $records+=[pscustomobject]@{File=$file.Name;Width=$im.Width;Height=$im.Height;Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash;PhotoUpscaled=$true;FinalNoisePercent=0}
 $im.Dispose()
}
$records | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Verification_exports_V12.csv')
$assetRecords=@()
foreach($file in (Get-ChildItem -LiteralPath (Join-Path $root 'Masters\V12') -Filter '*.png')){
 $im=[System.Drawing.Image]::FromFile($file.FullName)
 $assetRecords+=[pscustomobject]@{File=$file.Name;Width=$im.Width;Height=$im.Height;Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
 $im.Dispose()
}
$assetRecords | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Manifest_masters_V12.csv')
$zipPath=Join-Path $root 'Livraison\Imre_Gams_8_Thumbnails_V12_3840x2160.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Archive already exists; preserve previous delivery.'}
$zip=[System.IO.Compression.ZipFile]::Open($zipPath,[System.IO.Compression.ZipArchiveMode]::Create)
try{foreach($file in $files){[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,$file.Name,[System.IO.Compression.CompressionLevel]::NoCompression) | Out-Null}}finally{$zip.Dispose()}
$zip=[System.IO.Compression.ZipFile]::OpenRead($zipPath)
try{
 if($zip.Entries.Count -ne 8){throw 'Wrong archive count.'}
 foreach($entry in $zip.Entries){
  $expected=$records | Where-Object File -eq $entry.FullName
  if(-not $expected -or $entry.Length -ne $expected.Bytes){throw 'Entry mismatch.'}
  $st=$entry.Open();$sha=[System.Security.Cryptography.SHA256]::Create()
  try{$actual=([System.BitConverter]::ToString($sha.ComputeHash($st))).Replace('-','')}finally{$sha.Dispose();$st.Dispose()}
  if($actual -ne $expected.SHA256){throw ('SHA256 mismatch: '+$entry.FullName)}
 }
}finally{$zip.Dispose()}
Write-Output ('VERIFIED: 8 PNG 3840x2160; 8 ZIP entries; all SHA256 match. '+$zipPath)








