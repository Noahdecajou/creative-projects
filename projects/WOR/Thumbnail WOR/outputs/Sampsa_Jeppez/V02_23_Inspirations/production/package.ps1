$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path $PSScriptRoot -Parent
$parent=Split-Path $root -Parent
$path=Join-Path $parent 'Sampsa_Jeppez_23_Thumbnails_4K.zip'
if(Test-Path -LiteralPath $path){throw 'Package already exists; create a new version instead'}
$files=@(Get-ChildItem -LiteralPath (Join-Path $root 'exports_4K') -File -Filter '*.png')
if($files.Count-ne23){throw 'Expected exactly 23 PNG'}
$files+=Get-Item -LiteralPath (Join-Path $root 'README.txt'),(Join-Path $root 'apercus\Planche_23_variantes.jpg'),(Join-Path $root 'production\Titres_et_sources.tsv'),(Join-Path $root 'production\Verification_exports.json')
$archive=[IO.Compression.ZipFile]::Open($path,[IO.Compression.ZipArchiveMode]::Create)
try{foreach($f in $files){
 $entry=[IO.Path]::GetRelativePath($root,$f.FullName).Replace('\','/')
 [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$f.FullName,$entry,[IO.Compression.CompressionLevel]::Fastest)|Out-Null
}}finally{$archive.Dispose()}
$archive=[IO.Compression.ZipFile]::OpenRead($path)
$checks=@()
try{foreach($entry in $archive.Entries){
 $local=Join-Path $root $entry.FullName
 $stream=$entry.Open()
 try{$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream))}finally{$stream.Dispose()}
 $expected=(Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash
 if($hash-ne$expected){throw ('Archive hash mismatch: '+$entry.FullName)}
 $checks += [pscustomobject]@{Entry=$entry.FullName;Bytes=$entry.Length;SHA256=$hash;Matches=$true}
}}finally{$archive.Dispose()}
$checks|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $root 'production\Verification_zip_entries.json') -Encoding utf8
$result=[pscustomobject]@{Path=$path;Entries=$checks.Count;PNGCount=@($checks|Where-Object Entry -like 'exports_4K/*.png').Count;Bytes=(Get-Item -LiteralPath $path).Length;SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;AllEntriesVerified=$true}
$result|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $root 'production\Verification_package.json') -Encoding utf8
$result|ConvertTo-Json

