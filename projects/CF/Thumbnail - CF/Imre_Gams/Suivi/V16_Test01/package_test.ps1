$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path (Split-Path $PSScriptRoot)
$preview=Join-Path $root 'Apercus\V16_Test01'
$exports=Join-Path $root 'Exports\V16_Test01'
Copy-Item -LiteralPath (Join-Path $preview '01_1280.jpg') -Destination (Join-Path $exports '01_Price_Is_Not_Value_V16_Test_1280x720.jpg')
$sheet=[Drawing.Bitmap]::new(1280,402)
$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(245,245,243));$g.InterpolationMode='HighQualityBicubic'
$font=[Drawing.Font]::new('Arial',17,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Pixel)
foreach($item in @(@{x=0;path=(Join-Path $root 'Apercus\V15_Test01\01_1280.jpg');label='AVANT - V15'},@{x=640;path=(Join-Path $preview '01_1280.jpg');label='OMBRE ET LUEURS - V16'})){
 $im=[Drawing.Image]::FromFile($item.path);$g.DrawString($item.label,$font,[Drawing.Brushes]::Black,[single]($item.x+14),[single]10);$g.DrawImage($im,[int]$item.x,42,640,360);$im.Dispose()
}
$g.Dispose();$font.Dispose();$sheet.Save((Join-Path $preview 'Comparatif_01_V15_V16.png'),[Drawing.Imaging.ImageFormat]::Png);$sheet.Dispose()
$reportPath=Join-Path $preview 'Comparatif_V16.html';$report=Get-Content -LiteralPath $reportPath -Raw
$local=[regex]::Matches($report,'(?:src|href)="([^"]+)"') | ForEach-Object {$_.Groups[1].Value} | Where-Object {$_ -notmatch '^https?:'} | Sort-Object -Unique
foreach($link in $local){if(-not(Test-Path -LiteralPath (Join-Path $preview $link))){throw ('Missing report link: '+$link)}}
$zipPath=Join-Path $root 'Livraison\Imre_Gams_01_Ombre_Lueurs_V16.zip'
if(Test-Path -LiteralPath $zipPath){throw 'Versioned archive already exists'}
[IO.Compression.ZipFile]::CreateFromDirectory($exports,$zipPath,[IO.Compression.CompressionLevel]::Optimal,$false)
$zip=[IO.Compression.ZipFile]::OpenRead($zipPath)
try{
 if($zip.Entries.Count -ne 2){throw 'Expected two image exports'}
 foreach($entry in $zip.Entries){$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();$hash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','');$stream.Dispose();$sha.Dispose();$source=(Get-FileHash -LiteralPath (Join-Path $exports $entry.FullName) -Algorithm SHA256).Hash;if($hash -ne $source){throw 'Archive hash mismatch'}}
}finally{$zip.Dispose()}
Write-Output ('Verified comparison links: '+$local.Count)
Write-Output ('Verified archive: '+$zipPath+' / 2 images / hashes match')
