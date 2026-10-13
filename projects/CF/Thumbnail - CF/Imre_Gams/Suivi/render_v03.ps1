$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path $PSScriptRoot
$master=Join-Path $root 'Masters\V03'
$out=Join-Path $root 'Exports\V03'
$preview=Join-Path $root 'Apercus\V03'
. (Join-Path $PSScriptRoot 'add_final_noise.ps1')
$white=[System.Drawing.Color]::White
$yellow=[System.Drawing.Color]::FromArgb(255,235,0)
$black=[System.Drawing.Color]::FromArgb(12,12,12)
$red=[System.Drawing.Color]::FromArgb(235,15,20)
$green=[System.Drawing.Color]::FromArgb(0,152,67)
function Canvas($light=$false){
 $script:b=New-Object System.Drawing.Bitmap(1280,720)
 $script:g=[System.Drawing.Graphics]::FromImage($b)
 $g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.TextRenderingHint='AntiAliasGridFit'
 if($light){$g.Clear([System.Drawing.Color]::FromArgb(235,234,226))}else{$g.Clear([System.Drawing.Color]::FromArgb(22,23,24))}
}
function Photo($file,$x,$y,$w,$h){$im=[System.Drawing.Image]::FromFile((Join-Path $master $file));$g.DrawImage($im,[int]$x,[int]$y,[int]$w,[int]$h);$im.Dispose()}
function Portrait($file,$cx,$y,$h){$im=[System.Drawing.Image]::FromFile((Join-Path $master $file));$w=$h*$im.Width/$im.Height;$g.DrawImage($im,[single]($cx-$w/2),[single]$y,[single]$w,[single]$h);$im.Dispose()}
function SourceCrop($file,$x,$y,$w,$h,$sx=0,$sy=0,$sw=1920,$sh=1080){
 $im=[System.Drawing.Image]::FromFile((Join-Path $root ('Sources_HD\'+$file)))
 $rect=New-Object System.Drawing.Rectangle([int]$x,[int]$y,[int]$w,[int]$h)
 $g.DrawImage($im,$rect,[single]$sx,[single]$sy,[single]$sw,[single]$sh,[System.Drawing.GraphicsUnit]::Pixel);$im.Dispose()
}
function Box($x,$y,$w,$h,$color){$br=New-Object System.Drawing.SolidBrush($color);$g.FillRectangle($br,[single]$x,[single]$y,[single]$w,[single]$h);$br.Dispose()}
function Text($s,$x,$y,$w,$h,$size,$color,$weight='Regular',$center=$false){
 $family=if($weight -eq 'Bold'){'Poppins'}elseif($weight -eq 'SemiBold'){'Poppins SemiBold'}elseif($weight -eq 'Medium'){'Poppins Medium'}else{'Poppins'}
 $style=if($weight -eq 'Bold'){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular}
 $ff=New-Object System.Drawing.FontFamily($family)
 $path=New-Object System.Drawing.Drawing2D.GraphicsPath
 $fmt=[System.Drawing.StringFormat]::GenericTypographic
 $path.AddString($s,$ff,[int]$style,[single]$size,(New-Object System.Drawing.PointF(0,0)),$fmt)
 $bounds=$path.GetBounds();$scale=[math]::Min(1,[math]::Min($w/$bounds.Width,($h*.82)/$bounds.Height))
 $tx=$x-$bounds.X*$scale
 if($center){$tx=$x+($w-$bounds.Width*$scale)/2-$bounds.X*$scale}
 $ty=$y+($h-$bounds.Height*$scale)/2-$bounds.Y*$scale
 $matrix=New-Object System.Drawing.Drawing2D.Matrix($scale,0,0,$scale,$tx,$ty)
 $path.Transform($matrix)
 if($color.ToArgb() -eq $white.ToArgb()){
  $state=$g.Save();$g.TranslateTransform(1,3)
  foreach($stroke in @(10,7,4)){$pen=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(16,0,0,0),[single]$stroke);$pen.LineJoin='Round';$g.DrawPath($pen,$path);$pen.Dispose()}
  $shadowBrush=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(95,0,0,0));$g.FillPath($shadowBrush,$path);$shadowBrush.Dispose();$g.Restore($state)
 }
 $brush=New-Object System.Drawing.SolidBrush($color);$g.FillPath($brush,$path)
 $brush.Dispose();$matrix.Dispose();$path.Dispose();$ff.Dispose();$fmt.Dispose()
}
function RoundPath($x,$y,$w,$h,$radius){$p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$radius*2;$p.AddArc([single]$x,[single]$y,[single]$d,[single]$d,180,90);$p.AddArc([single]($x+$w-$d),[single]$y,[single]$d,[single]$d,270,90);$p.AddArc([single]($x+$w-$d),[single]($y+$h-$d),[single]$d,[single]$d,0,90);$p.AddArc([single]$x,[single]($y+$h-$d),[single]$d,[single]$d,90,90);$p.CloseFigure();return $p}
function RoundedBox($x,$y,$w,$h,$color,$r=12){$p=RoundPath $x $y $w $h $r;$br=New-Object System.Drawing.SolidBrush($color);$g.FillPath($br,$p);$br.Dispose();$p.Dispose()}
function SoftGlow($x,$y,$w,$h,$color){for($spread=24;$spread -ge 1;$spread--){$alpha=[int](1+5*[math]::Exp(-$spread*$spread/170));RoundedBox ($x-$spread) ($y-$spread) ($w+2*$spread) ($h+2*$spread) ([System.Drawing.Color]::FromArgb($alpha,$color.R,$color.G,$color.B)) (12+$spread)}}
function Badge($s,$x,$y,$w,$h,$bg,$fg,$size=50,$weight='Medium'){
 if($bg.ToArgb() -eq $yellow.ToArgb() -or $bg.ToArgb() -eq $white.ToArgb()){SoftGlow $x $y $w $h $bg}
 RoundedBox $x ($y+3) $w $h ([System.Drawing.Color]::FromArgb(70,0,0,0)) 10
 RoundedBox $x $y $w $h $bg 10
 Text $s ($x+16) $y ($w-32) $h $size $fg $weight $true
}
function Arrow($x1,$y1,$cx1,$cy1,$cx2,$cy2,$x2,$y2,$color=$yellow,$width=9){
 $p=New-Object System.Drawing.Pen($color,[single]$width);$cap=New-Object System.Drawing.Drawing2D.AdjustableArrowCap(3,4,$true);$p.CustomEndCap=$cap
 $g.DrawBezier($p,[single]$x1,[single]$y1,[single]$cx1,[single]$cy1,[single]$cx2,[single]$cy2,[single]$x2,[single]$y2);$p.Dispose();$cap.Dispose()
}
function Line($x1,$y1,$x2,$y2,$color,$width=4){$p=New-Object System.Drawing.Pen($color,[single]$width);$g.DrawLine($p,[single]$x1,[single]$y1,[single]$x2,[single]$y2);$p.Dispose()}
function Laptop($file){
 Box 62 237 622 414 ([System.Drawing.Color]::FromArgb(155,157,157));Box 68 244 610 400 $black
 SourceCrop $file 76 252 594 383 250 10 1420 1050
 $pts=[System.Drawing.Point[]]@((New-Object System.Drawing.Point(62,651)),(New-Object System.Drawing.Point(684,651)),(New-Object System.Drawing.Point(738,701)),(New-Object System.Drawing.Point(18,701)))
 $g.FillPolygon([System.Drawing.Brushes]::Silver,$pts);Box 84 657 565 16 ([System.Drawing.Color]::FromArgb(60,60,60));Box 310 680 125 13 ([System.Drawing.Color]::FromArgb(155,155,155))
}
function PlayIcon($x,$y,$w=125){$h=$w*.69;for($sp=8;$sp -ge 1;$sp--){RoundedBox ($x-$sp) ($y+4-$sp) ($w+2*$sp) ($h+2*$sp) ([System.Drawing.Color]::FromArgb(4,0,0,0)) (20+$sp)};RoundedBox $x $y $w $h ([System.Drawing.Color]::FromArgb(255,0,0)) 22;$pts=[System.Drawing.PointF[]]@((New-Object System.Drawing.PointF([single]($x+$w*.4),[single]($y+$h*.25))),(New-Object System.Drawing.PointF([single]($x+$w*.4),[single]($y+$h*.75))),(New-Object System.Drawing.PointF([single]($x+$w*.68),[single]($y+$h*.5))));$g.FillPolygon([System.Drawing.Brushes]::White,$pts)}
function ProgressArrows(){
 $state=$g.Save();$mask=New-Object System.Drawing.Drawing2D.GraphicsPath
 $mask.AddEllipse(244,101,162,234);$mask.AddEllipse(929,98,171,259)
 $g.SetClip($mask,[System.Drawing.Drawing2D.CombineMode]::Exclude)
 Arrow 233 180 289 112 353 134 432 223 $white 3
 Arrow 678 235 734 303 852 289 865 208 $white 3
 Arrow 868 177 967 120 1063 160 1113 226 $white 3
 $g.Restore($state);$mask.Dispose()
}
function Pixelate($x,$y,$w,$h){$tmp=$b.Clone((New-Object System.Drawing.Rectangle($x,$y,$w,$h)),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);for($py=0;$py -lt $h;$py+=18){for($px=0;$px -lt $w;$px+=18){$c=$tmp.GetPixel([math]::Min($px+9,$w-1),[math]::Min($py+9,$h-1));Box ($x+$px) ($y+$py) ([math]::Min(18,$w-$px)) ([math]::Min(18,$h-$py)) $c}};$tmp.Dispose()}
$titles=@('PRICE IS NOT VALUE','WHY BREAKOUTS FAIL','WHAT REALLY DRIVES PRICE','STOP CHASING PRICE','MASTER AUCTION MARKET THEORY','READ THE MARKET','SMART MONEY MYTHS EXPLAINED','PRICE TO VALUE')
$slugs=@('Price_Is_Not_Value','Why_Breakouts_Fail','What_Really_Drives_Price','Stop_Chasing_Price','Master_Auction_Market_Theory','Read_The_Market','Smart_Money_Myths','Price_To_Value')
$manifest=@()
for($i=1;$i -le 8;$i++){
 Canvas ($i -eq 6)
 switch($i){
  1 {Laptop 'frame_17100.jpg';Portrait 'Imre_camera_cutout.png' 1007 8 925;Text 'PRICE IS NOT' 32 18 739 93 92 $white 'SemiBold';Badge 'VALUE' 32 125 425 94 $white $black 102 'Bold';Badge 'Auction Market Theory' 235 642 650 64 $yellow $black 43;Arrow 760 611 760 546 706 475 679 451}
  2 {Laptop 'frame_66600.jpg';Portrait 'Imre_camera_cutout.png' 1007 8 925;Text 'WHY' 32 18 199 96 88 $white 'SemiBold';Badge 'BREAKOUTS' 250 18 522 96 $white $black 76 'Bold';Text 'FAIL' 32 124 570 98 94 $white 'SemiBold';Badge 'Read the Market Regime' 235 642 650 64 $yellow $black 40;Arrow 760 611 760 546 706 475 679 451}
  3 {Photo '03_artwork.png' 0 0 1280 720;Text 'WHAT' 152 8 332 100 92 $white 'SemiBold';Badge 'REALLY' 501 11 555 93 $white $black 88 'Bold';Badge 'DRIVES' 470 121 342 73 $yellow $black 65 'Bold';Badge 'PRICE' 493 194 295 76 $yellow $black 69 'Bold';Badge '2 MARKET STATES' 735 460 500 66 $green $white 43;Arrow 629 284 556 388 560 541 632 612;Arrow 771 448 742 403 766 365 803 341}
  4 {Box 345 80 590 416 ([System.Drawing.Color]::FromArgb(130,130,130));SourceCrop 'frame_66600.jpg' 355 90 570 396 260 20 1390 1020;Portrait 'Imre_camera_cutout.png' 265 12 820;Portrait 'Riz_front_cutout.png' 990 14 770;Badge 'PRICE vs VALUE' 459 31 362 61 $yellow $black 38;Arrow 620 104 626 130 637 152 668 173;Text 'STOP CHASING' 278 502 740 96 86 $white 'SemiBold' $true;Badge 'PRICE' 430 608 420 99 $white $black 96 'Bold'}
  5 {Photo '05_artwork.png' 0 0 1280 720;Text 'MASTER' 26 9 425 96 88 $white 'SemiBold';Text 'AUCTION' 470 9 782 96 93 $yellow 'SemiBold';Text 'MARKET THEORY' 838 112 414 70 54 $white 'SemiBold';Line 851 190 1230 190 $yellow 4;Text '2 MARKET' 68 210 280 51 46 $white 'Medium';Text 'STATES' 91 260 252 51 46 $white 'Medium';Badge 'IMRE GAMS' 970 420 277 45 $black $white 30;Badge 'STEP BY STEP' 477 501 350 54 $black $white 36;Arrow 322 318 312 355 354 363 393 351;Arrow 589 593 623 580 642 570 644 558}
  6 {Box 125 158 1030 480 ([System.Drawing.Color]::FromArgb(250,250,250));Text 'READ THE' 36 13 562 98 86 $black 'SemiBold';Badge 'MARKET' 619 19 609 89 $yellow $black 84 'Bold';Text 'BALANCE' 175 187 252 41 30 $black 'Medium';Text 'IMBALANCE' 894 187 266 41 30 $black 'Medium';Line 179 250 397 250 $red;Line 179 363 397 363 $green;Line 179 306 397 306 ([System.Drawing.Color]::DodgerBlue) 2;Line 179 353 214 261 $black;Line 214 261 252 354 $black;Line 252 354 290 260 $black;Line 290 260 329 355 $black;Line 329 355 386 267 $black;Line 900 356 944 322 $black;Line 944 322 970 335 $black;Line 970 335 1008 280 $black;Line 1008 280 1043 294 $black;Line 1043 294 1107 245 $black;Text 'FAIR VALUE' 173 430 253 40 29 $black 'Medium';Text 'MICRO-RANGE' 898 430 257 40 27 $black 'Medium';Line 908 551 966 508 $black;Line 966 508 989 526 $black;Line 989 526 1007 507 $black;Line 1007 507 1030 521 $black;Line 1030 521 1075 470 $black;Line 963 500 1044 500 $red 2;Line 963 533 1044 533 $green 2;Line 179 510 382 510 ([System.Drawing.Color]::DodgerBlue) 4;Line 179 529 336 529 ([System.Drawing.Color]::DodgerBlue) 4;Line 179 548 371 548 ([System.Drawing.Color]::DodgerBlue) 4;Portrait 'Imre_camera_cutout.png' 640 109 822.5}
  7 {Photo '07_artwork.png' 0 0 1280 720;Badge 'SMART MONEY MYTHS' 287 28 745 89 $red $white 59 'SemiBold';Text 'EXPLAINED' 391 130 535 66 58 $white 'Regular' $true;Text 'RIZ' 43 186 125 35 26 $white 'SemiBold';Text 'IMRE' 1145 184 109 35 26 $white 'SemiBold';Arrow 112 223 109 257 131 275 171 277 $white 3;Arrow 1191 225 1190 261 1166 278 1126 279 $white 3;PlayIcon 543 260 190}
  8 {Photo '08_artwork.png' 0 0 1280 720;Pixelate 247 137 151 178;ProgressArrows;Text 'PRICE' 48 14 392 91 87 $white 'SemiBold';Badge 'VALUE' 787 17 447 91 $red $white 88 'SemiBold';Arrow 468 60 554 60 643 60 740 60 $white 9;Badge 'BALANCE' 29 159 220 49 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 27;Badge 'REGIME' 439 212 230 48 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 27;Badge 'MACRO-RANGE' 620 159 250 49 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 25;Badge 'CLOSE THE GAP' 1080 225 192 48 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 23;PlayIcon 570 346 132}
 }
 $g.Dispose();$id='{0:00}' -f $i;$name=$id+'_'+$slugs[$i-1]
 $b.Save((Join-Path $master ($name+'_master.png')),[System.Drawing.Imaging.ImageFormat]::Png)
 $export=New-Object System.Drawing.Bitmap(3840,2160);$eg=[System.Drawing.Graphics]::FromImage($export);$eg.InterpolationMode='HighQualityBicubic';$eg.DrawImage($b,0,0,3840,2160);$eg.Dispose()
 [ThumbnailNoise]::Apply($export,5.0,(610120+$i))
 $finalName=$name+'_3840x2160.png';$export.Save((Join-Path $out $finalName),[System.Drawing.Imaging.ImageFormat]::Png)
 foreach($size in @(320,1280)){$h=[int]($size*9/16);$small=New-Object System.Drawing.Bitmap($size,$h);$sg=[System.Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($export,0,0,$size,$h);$sg.Dispose();$small.Save((Join-Path $preview ($id+'_'+$size+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$small.Dispose()}
 $manifest+=[pscustomobject]@{ID=$id;Title=$titles[$i-1];File=$finalName;MasterWidth=1280;MasterHeight=720;ExportWidth=3840;ExportHeight=2160;Upscaled=$true;NoisePercent=5;Noise='Gaussian monochromatic sigma12.75 after resize once';GuestShirt=$(if($i -in @(3,7,8)){'black'}else{'white'});HostShirt='original beige polo';Method='Original identity references plus generative retouch and scenes; separately composed typography and episode board photos'}
 $export.Dispose();$b.Dispose()
}
$manifest | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Exports_manifest_V03.csv')
function Sheet($tw,$th,$name){$sheet=New-Object System.Drawing.Bitmap(($tw*2),(($th+30)*4));$sg=[System.Drawing.Graphics]::FromImage($sheet);$sg.Clear([System.Drawing.Color]::FromArgb(22,22,22));$sg.InterpolationMode='HighQualityBicubic';$f=New-Object System.Drawing.Font('Arial',14);for($j=0;$j -lt 8;$j++){$id='{0:00}' -f ($j+1);$im=[System.Drawing.Image]::FromFile((Join-Path $preview ($id+'_1280.jpg')));$x=($j%2)*$tw;$y=[int][math]::Floor($j/2)*($th+30);$sg.DrawImage($im,$x,$y,$tw,$th);$sg.DrawString(($id+'  '+$titles[$j]),$f,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+$th+4));$im.Dispose()};$f.Dispose();$sg.Dispose();$sheet.Save((Join-Path $preview $name),[System.Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()}
Sheet 640 360 'Planche_8_Thumbnails_V03.jpg'
Sheet 320 180 'Controle_Mobile_V03.jpg'
Write-Output 'Eight masters, exports and previews rendered.'




