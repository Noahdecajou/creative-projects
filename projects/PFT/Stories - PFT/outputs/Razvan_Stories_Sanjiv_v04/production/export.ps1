$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$batchRoot=Split-Path -Parent $PSScriptRoot
$m=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
foreach($dir in @('PNG_1080x1920','JPEG_1080x1920','masters','sources_originales','references','apercus')) { New-Item -ItemType Directory -Path (Join-Path $batchRoot $dir) -Force | Out-Null }
$codec=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$params=[Drawing.Imaging.EncoderParameters]::new(1)
$params.Param[0]=[Drawing.Imaging.EncoderParameter]::new([Drawing.Imaging.Encoder]::Quality,[long]95)
$verified=@()
foreach($item in $m.items) {
 $stem='Razvan_{0:00}_{1}_v04' -f $item.n,$item.slug
 Copy-Item -LiteralPath $item.path -Destination (Join-Path $batchRoot ('masters\'+$stem+'_native.png'))
 foreach($original in @($item.inputs | Select-Object -First 2)) {Copy-Item -LiteralPath $original -Destination (Join-Path $batchRoot ('sources_originales\'+[IO.Path]::GetFileName($original)))}
 foreach($reference in @($item.inputs | Select-Object -Skip 2)) {Copy-Item -LiteralPath $reference -Destination (Join-Path $batchRoot ('references\'+[IO.Path]::GetFileName($reference)))}
 $im=[Drawing.Image]::FromFile($item.path)
 $bmp=[Drawing.Bitmap]::new(1080,1920,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
 $g=[Drawing.Graphics]::FromImage($bmp)
 $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
 $g.DrawImage($im,[Drawing.Rectangle]::new(0,0,1080,1920))
 $png=Join-Path $batchRoot ('PNG_1080x1920\'+$stem+'.png')
 $jpg=Join-Path $batchRoot ('JPEG_1080x1920\'+$stem+'.jpg')
 $bmp.Save($png,[Drawing.Imaging.ImageFormat]::Png)
 $bmp.Save($jpg,$codec,$params)
 $verified += [pscustomobject]@{Number=$item.n;Title=$item.title;PNG=$png;JPEG=$jpg;NativeWidth=$im.Width;NativeHeight=$im.Height;ExportWidth=1080;ExportHeight=1920;SHA256=(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash}
 $im.Dispose();$g.Dispose();$bmp.Dispose()
}
$verified | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'verification.json') -Encoding utf8
foreach($group in @(@{Start=0;Count=6;Name='Planche_01_06.jpg'},@{Start=6;Count=7;Name='Planche_07_13.jpg'})) {
 $rows=[int][math]::Ceiling($group.Count/3)
 $bmp=[Drawing.Bitmap]::new(1080,($rows*680))
 $g=[Drawing.Graphics]::FromImage($bmp)
 $g.Clear([Drawing.Color]::FromArgb(18,20,22))
 $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 $font=[Drawing.Font]::new('Arial',14,[Drawing.FontStyle]::Bold)
 for($j=0;$j -lt $group.Count;$j++) {
  $i=$group.Start+$j;$x=[int](($j%3)*360);$y=[int]([math]::Floor($j/3)*680)
  $label='{0:00}  {1}' -f ($i+1),$m.items[$i].slug.Replace('_',' ')
  $g.DrawString($label,$font,[Drawing.Brushes]::White,[float]($x+8),[float]($y+8))
  $im=[Drawing.Image]::FromFile($verified[$i].PNG)
  $g.DrawImage($im,[Drawing.Rectangle]::new($x,$y+40,360,640))
  $im.Dispose()
 }
 $bmp.Save((Join-Path $batchRoot ('apercus\'+$group.Name)),$codec,$params)
 $g.Dispose();$bmp.Dispose();$font.Dispose()
}
$params.Dispose()
@'
RAZVAN STORIES SANJIV V04 — 13 adaptations du set Thumbnail V06 final du 12 octobre 2026.
PNG_1080x1920 et JPEG_1080x1920 : 13 stories dans chaque format.
masters : images natives generees. Exports redimensionnes en haute qualite, sans nettete supplementaire.
sources_originales : photos camera reutilisees pour chaque creation et correction.
references : thumbnails V05 et references de story utilisees.
production : prompts, correspondance 1 pour 1, script, dimensions et empreintes SHA256.
apercus : planches 01-06 et 07-13.
Textes anglais et accents vert degrade, rouge et jaune du set V06.
Sanjiv reconstruit depuis sa capture originale sur les 7 duos. V06 definitive utilisee comme reference.
Footer FULL PODCAST, Spotify et YouTube ; aucun jour/horaire/sponsor ajoute.
Les anciennes stories restent disponibles separement.
Outil de creation : image_gen integre. 13 visuels verifies visuellement.
'@ | Set-Content -LiteralPath (Join-Path $batchRoot 'README.txt') -Encoding utf8
$zip=Join-Path (Split-Path -Parent $batchRoot) 'Razvan_Stories_Sanjiv_v04.zip'
if(Test-Path -LiteralPath $zip) {throw 'Archive exists; preserve it.'}
[IO.Compression.ZipFile]::CreateFromDirectory($batchRoot,$zip,[IO.Compression.CompressionLevel]::Optimal,$false)
$a=[IO.Compression.ZipFile]::OpenRead($zip)
$pn=@($a.Entries | Where-Object FullName -like 'PNG_1080x1920/*')
$jn=@($a.Entries | Where-Object FullName -like 'JPEG_1080x1920/*')
if($pn.Count -ne 13 -or $jn.Count -ne 13) {throw 'Incorrect export count'}
$count=0
foreach($e in $a.Entries) {
 $s=$e.Open();$h=[Security.Cryptography.SHA256]::Create()
 $hash=[BitConverter]::ToString($h.ComputeHash($s)).Replace('-','')
 $s.Dispose();$h.Dispose()
 if($hash -ne (Get-FileHash -LiteralPath (Join-Path $batchRoot $e.FullName) -Algorithm SHA256).Hash) {throw ('ZIP mismatch '+$e.FullName)}
 $count++
}
$a.Dispose()
foreach($file in @($verified.PNG)+@($verified.JPEG)) {$im=[Drawing.Image]::FromFile($file);if($im.Width -ne 1080 -or $im.Height -ne 1920){throw 'Incorrect dimensions'};$im.Dispose()}
[pscustomobject]@{Archive=$zip;PNG=$pn.Count;JPEG=$jn.Count;VerifiedArchiveEntries=$count;Bytes=(Get-Item -LiteralPath $zip).Length} | ConvertTo-Json
