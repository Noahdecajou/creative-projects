$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$batchRoot=Split-Path $PSScriptRoot -Parent
$greenRef=Join-Path $PSScriptRoot 'edit_inputs\Green_Gradient_Reference.png'
Copy-Item -LiteralPath 'C:\Users\notti\Pictures\Screenshots\Screenshot 2026-10-12 110619.png' -Destination $greenRef
$im=[System.Drawing.Image]::FromFile($greenRef)
$checked=@(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'verification_images.json') -Raw | ConvertFrom-Json)
$checked+=[pscustomobject]@{File='production\edit_inputs\Green_Gradient_Reference.png';Width=$im.Width;Height=$im.Height;Bytes=(Get-Item -LiteralPath $greenRef).Length;SHA256=(Get-FileHash -LiteralPath $greenRef -Algorithm SHA256).Hash}
$im.Dispose()
$checked | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'verification_images.json') -Encoding utf8
$zipPath=Join-Path (Split-Path (Split-Path $batchRoot -Parent) -Parent) 'Razvan_Green_Gradient_v05.zip'
$files=@(Get-ChildItem -LiteralPath $batchRoot -Recurse -File)
if(Test-Path -LiteralPath $zipPath){throw 'Archive already exists; refusing overwrite'}
[System.IO.Compression.ZipFile]::CreateFromDirectory($batchRoot,$zipPath,[System.IO.Compression.CompressionLevel]::Fastest,$true)
$archive=[System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
 $entries=@($archive.Entries | Where-Object {$_.Name})
 if($entries.Count -ne $files.Count){throw 'Archive count mismatch'}
 $sha=[System.Security.Cryptography.SHA256]::Create()
 foreach($file in $files){
  $entryName=(Split-Path $batchRoot -Leaf)+'/'+$file.FullName.Substring($batchRoot.Length+1).Replace('\','/')
  $entry=$archive.GetEntry($entryName)
  if(!$entry -or $entry.Length -ne $file.Length){throw ('Missing/wrong size: '+$entryName)}
  $stream=$entry.Open()
  try{$entryHash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose()}
  if($entryHash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash){throw ('Hash mismatch: '+$entryName)}
 }
 $sha.Dispose()
 $jpgs=@($entries | Where-Object FullName -like '*/YouTube_1280x720/*').Count
 $pngs=@($entries | Where-Object FullName -like '*/exports_4K/*').Count
 if($jpgs -ne 13 -or $pngs -ne 13){throw 'Need 13 finals of each format'}
 [pscustomobject]@{Archive=$zipPath;VerifiedEntries=$entries.Count;UploadJpegs=$jpgs;ExportPngs=$pngs;Bytes=(Get-Item -LiteralPath $zipPath).Length;SHA256=(Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash;Verification='Every entry size and SHA256 matches source files'} | ConvertTo-Json | Tee-Object -FilePath (Join-Path (Split-Path $zipPath -Parent) 'Razvan_Green_Gradient_v05_archive_verification.json')
}finally{$archive.Dispose()}
