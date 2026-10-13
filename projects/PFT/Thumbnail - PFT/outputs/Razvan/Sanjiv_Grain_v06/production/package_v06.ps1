$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$batchRoot=Split-Path $PSScriptRoot -Parent
$zipPath=Join-Path (Split-Path (Split-Path $batchRoot -Parent) -Parent) 'Razvan_Sanjiv_Grain_v06.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Archive already exists'}
$files=@(Get-ChildItem -LiteralPath $batchRoot -Recurse -File)
[System.IO.Compression.ZipFile]::CreateFromDirectory($batchRoot,$zipPath,[System.IO.Compression.CompressionLevel]::Fastest,$true)
$archive=[System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
 $entries=@($archive.Entries | Where-Object Name)
 if($entries.Count -ne $files.Count){throw 'Archive count mismatch'}
 $sha=[System.Security.Cryptography.SHA256]::Create()
 foreach($file in $files){
  $name=(Split-Path $batchRoot -Leaf)+'/'+$file.FullName.Substring($batchRoot.Length+1).Replace('\','/')
  $entry=$archive.GetEntry($name)
  if(!$entry -or $entry.Length -ne $file.Length){throw 'Archive size mismatch'}
  $stream=$entry.Open()
  try {$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose()}
  if($hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw ('Archive hash mismatch: '+$name)}
 }
 $sha.Dispose()
 $jpgs=@($entries | Where-Object FullName -like '*/YouTube_1280x720/*.jpg').Count
 if($jpgs -ne 13){throw 'Missing upload files'}
 [pscustomobject]@{Archive=$zipPath;VerifiedEntries=$entries.Count;UploadJpegs=$jpgs;Bytes=(Get-Item -LiteralPath $zipPath).Length;SHA256=(Get-FileHash -LiteralPath $zipPath).Hash;Verification='Every entry verified against source SHA256 and size'} | ConvertTo-Json | Tee-Object -FilePath (Join-Path (Split-Path $zipPath -Parent) 'Razvan_Sanjiv_Grain_v06_archive_verification.json')
} finally {$archive.Dispose()}
