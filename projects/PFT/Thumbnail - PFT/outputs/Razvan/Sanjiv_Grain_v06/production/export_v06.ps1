$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$batchRoot=Split-Path $PSScriptRoot -Parent
$oldRoot=Join-Path (Split-Path $batchRoot -Parent) 'Green_Gradient_v05'
$uploadRoot=Join-Path $batchRoot 'YouTube_1280x720'
New-Item -ItemType Directory -Path $uploadRoot -Force | Out-Null
$previous=Get-Content -LiteralPath (Join-Path $oldRoot 'production\export_and_verify.ps1') -Raw
$functionStart=$previous.IndexOf('function Export-Image')
$functionEnd=$previous.IndexOf('$records = @()')
Invoke-Expression $previous.Substring($functionStart,$functionEnd-$functionStart)
$files=@(Get-ChildItem -LiteralPath (Join-Path $batchRoot 'masters') -File | Sort-Object Name)
if($files.Count -ne 13){throw 'Missing masters'}
foreach($file in $files){
 $stem=$file.BaseName -replace '_master_\d+x\d+$',''
 $im=[System.Drawing.Image]::FromFile($file.FullName)
 if($im.Width -ne 1672 -or $im.Height -ne 941){throw 'Invalid master dimensions'}
 Export-Image $im 1280 720 (Join-Path $uploadRoot ($stem+'_1280x720.jpg')) $true
 Export-Image $im 1280 720 (Join-Path (Join-Path $batchRoot 'apercus') ($stem+'_preview.png'))
 Export-Image $im 3840 2160 (Join-Path (Join-Path $batchRoot 'exports_4K') ($stem+'_3840x2160.png'))
 $im.Dispose()
}
Copy-Item -LiteralPath (Join-Path $oldRoot 'sources_HD\Razvan_First_Frame_Original.jpg') -Destination (Join-Path $batchRoot 'sources_HD')
Copy-Item -LiteralPath (Join-Path (Split-Path $batchRoot -Parent) 'sources_HD\Animateur_02_00-00-48-00.jpg') -Destination (Join-Path $batchRoot 'sources_HD\Sanjiv_Original_00-00-48-00.jpg')
Copy-Item -LiteralPath (Join-Path (Split-Path $batchRoot -Parent) 'sources_HD\Animateur_12_00-37-36-00.jpg') -Destination (Join-Path $batchRoot 'sources_HD\Sanjiv_Original_00-37-36-00.jpg')
$sheet=[System.Drawing.Bitmap]::new(1280,2730)
$g=[System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(18,20,24))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$font=[System.Drawing.Font]::new('Arial',15,[System.Drawing.FontStyle]::Bold)
for($i=0;$i -lt $files.Count;$i++){
 $x=($i%2)*640;$y=[int][Math]::Floor($i/2)*390
 $g.DrawString(('V06 - {0:00}' -f ($i+1)),$font,[System.Drawing.Brushes]::White,[single]($x+10),[single]($y+4))
 $im=[System.Drawing.Image]::FromFile($files[$i].FullName)
 $g.DrawImage($im,[int]$x,[int]($y+30),640,360)
 $im.Dispose()
}
$sheet.Save((Join-Path $batchRoot 'apercus\Planche_13_V06.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$sheet.Dispose()
$faceManifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'face_manifest.json') -Raw | ConvertFrom-Json
$compare=[System.Drawing.Bitmap]::new(1050,1995)
$g=[System.Drawing.Graphics]::FromImage($compare)
$g.Clear([System.Drawing.Color]::FromArgb(18,20,24))
$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
for($i=0;$i -lt $faceManifest.Count;$i++){
 $item=$faceManifest[$i];$r=$item.rect;$y=$i*285
 $g.DrawString(('V05 - {0:00}' -f $item.n),$font,[System.Drawing.Brushes]::White,10,[single]($y+4))
 $g.DrawString(('V06 - {0:00}' -f $item.n),$font,[System.Drawing.Brushes]::White,535,[single]($y+4))
 $a=[System.Drawing.Image]::FromFile($item.original)
 $b=[System.Drawing.Image]::FromFile((Join-Path (Join-Path $batchRoot 'masters') (Split-Path $item.original -Leaf)))
 $scale=[Math]::Min(500.0/$r[2],245.0/$r[3]);$w=[int]($r[2]*$scale);$h=[int]($r[3]*$scale)
 $g.DrawImage($a,[System.Drawing.Rectangle]::new(10,$y+32,$w,$h),[single]$r[0],[single]$r[1],[single]$r[2],[single]$r[3],[System.Drawing.GraphicsUnit]::Pixel)
 $g.DrawImage($b,[System.Drawing.Rectangle]::new(535,$y+32,$w,$h),[single]$r[0],[single]$r[1],[single]$r[2],[single]$r[3],[System.Drawing.GraphicsUnit]::Pixel)
 $a.Dispose();$b.Dispose()
}
$compare.Save((Join-Path $batchRoot 'apercus\Comparaison_Sanjiv_V05_V06.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$compare.Dispose();$font.Dispose()
$notes=@('PROP FIRM TRADER - RAZVAN - V06 - 12 OCTOBRE 2026','DERNIERE VERSION : V06. 13 miniatures. YouTube_1280x720 = JPEG prêts à uploader.','Sanjiv corrigé sur 02, 04, 06, 07, 08, 09, 13 depuis deux captures originales du podcast.','Retouche IA via imagegen intégré, insertion limitée à sa tête avec bord fondu.','Avant grain : zéro pixel modifié hors de la région de tête sur les sept images.','Tous les masters : filtre Adobe Photoshop Add Noise réglé à 5 %. Filtre sur toute image, textes inclus.','Le redimensionnement à 1280x720 atténue légèrement la texture.','Masters 1672x941; exports_4K 3840x2160 agrandis bicubiques, pas 4K natif.','Sources HD originales inchangées. Aperçus : planche complète et comparaison des sept visages.','Production : prompts, paramètres Adobe, preuve de préservation locale et scripts.')
$notes | Set-Content -LiteralPath (Join-Path $batchRoot 'README.txt') -Encoding utf8
$checks=@()
foreach($file in (Get-ChildItem -LiteralPath $batchRoot -Recurse -File | Where-Object Extension -in @('.png','.jpg'))){
 $im=[System.Drawing.Image]::FromFile($file.FullName)
 if($file.Directory.Name -eq 'YouTube_1280x720' -and ($im.Width -ne 1280 -or $im.Height -ne 720 -or $file.Length -gt 2000000)){throw 'Invalid JPEG'}
 if($file.Directory.Name -eq 'exports_4K' -and ($im.Width -ne 3840 -or $im.Height -ne 2160)){throw 'Invalid enlarged export'}
 $checks+=[pscustomobject]@{File=$file.FullName.Substring($batchRoot.Length+1);Width=$im.Width;Height=$im.Height;Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName).Hash}
 $im.Dispose()
}
$checks | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'verification_images.json') -Encoding utf8
[pscustomobject]@{Masters=13;UploadJpegs=@(Get-ChildItem -LiteralPath $uploadRoot -File).Count;ImagesChecked=$checks.Count;Root=$batchRoot} | ConvertTo-Json

