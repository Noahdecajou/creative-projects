$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$batchRoot=Split-Path $PSScriptRoot -Parent
$zipPath=Join-Path (Split-Path (Split-Path $batchRoot -Parent) -Parent) 'Razvan_Six_References_v04.zip'
$files=@(Get-ChildItem -LiteralPath $batchRoot -Recurse -File)
if(Test-Path -LiteralPath $zipPath){throw 'Archive already exists; refusing overwrite'}
[System.IO.Compression.ZipFile]::CreateFromDirectory($batchRoot,$zipPath,[System.IO.Compression.CompressionLevel]::Fastest,$true)
$archive=[System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
  $entries=@($archive.Entries | Where-Object {$_.Name})
  if($entries.Count -ne $files.Count){throw 'Archive count mismatch'}
  $sha=[System.Security.Cryptography.SHA256]::Create()
  foreach($file in $files) {
    $entryName=(Split-Path $batchRoot -Leaf)+'/'+$file.FullName.Substring($batchRoot.Length+1).Replace('\','/')
    $entry=$archive.GetEntry($entryName)
    if(!$entry -or $entry.Length -ne $file.Length){throw ('Missing or wrong size: '+$entryName)}
    $stream=$entry.Open()
    try {$entryHash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')} finally {$stream.Dispose()}
    if($entryHash -ne (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash){throw ('Hash mismatch: '+$entryName)}
  }
  $sha.Dispose()
  [pscustomobject]@{Archive=$zipPath;VerifiedEntries=$entries.Count;UploadJpegs=@($entries | Where-Object FullName -like '*/YouTube_1280x720/*').Count;ExportPngs=@($entries | Where-Object FullName -like '*/exports_4K/*').Count;Bytes=(Get-Item -LiteralPath $zipPath).Length;SHA256=(Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash;Verification='All entry sizes and SHA256 match source files'} | ConvertTo-Json | Tee-Object -FilePath (Join-Path (Split-Path $zipPath -Parent) 'Razvan_Six_References_v04_archive_verification.json')
} finally {$archive.Dispose()}

