$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path $PSScriptRoot
$master=Join-Path $root 'Masters\V01'
$out=Join-Path $root 'Exports\V01'
$preview=Join-Path $root 'Apercus'
. (Join-Path (Split-Path $root) 'add_final_noise.ps1')
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
function SourceCrop($file,$x,$y,$w,$h,$sx=0,$sy=0,$sw=1920,$sh=1080){
 $im=[System.Drawing.Image]::FromFile((Join-Path $root ('Sources_HD\'+$file)))
 $rect=New-Object System.Drawing.Rectangle([int]$x,[int]$y,[int]$w,[int]$h)
 $g.DrawImage($im,$rect,[single]$sx,[single]$sy,[single]$sw,[single]$sh,[System.Drawing.GraphicsUnit]::Pixel);$im.Dispose()
}
function Box($x,$y,$w,$h,$color){$br=New-Object System.Drawing.SolidBrush($color);$g.FillRectangle($br,[single]$x,[single]$y,[single]$w,[single]$h);$br.Dispose()}
function Text($s,$x,$y,$w,$h,$size,$color,$weight='Regular',$center=$false){
 $family=if($weight -eq 'Bold'){'Poppins'}elseif($weight -eq 'SemiBold'){'Poppins SemiBold'}elseif($weight -eq 'Medium'){'Poppins Medium'}else{'Poppins'}
 $style=if($weight -eq 'Bold'){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular}
 $f=New-Object System.Drawing.Font($family,[single]$size,$style,[System.Drawing.GraphicsUnit]::Pixel)
 $fmt=New-Object System.Drawing.StringFormat;$fmt.FormatFlags=[System.Drawing.StringFormatFlags]::NoWrap
 if($center){$fmt.Alignment='Center'};$fmt.LineAlignment='Center'
 while($g.MeasureString($s,$f).Width -gt $w -and $f.Size -gt 12){$n=$f.Size-1;$f.Dispose();$f=New-Object System.Drawing.Font($family,[single]$n,$style,[System.Drawing.GraphicsUnit]::Pixel)}
 $brush=New-Object System.Drawing.SolidBrush($color)
 $g.DrawString($s,$f,$brush,(New-Object System.Drawing.RectangleF([single]$x,[single]$y,[single]$w,[single]$h)),$fmt)
 $brush.Dispose();$f.Dispose();$fmt.Dispose()
}
function Badge($s,$x,$y,$w,$h,$bg,$fg,$size=50,$weight='Medium'){Box $x $y $w $h $bg;Text $s ($x+8) $y ($w-16) $h $size $fg $weight $true}
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
function PlayIcon($x,$y,$w=125){Box $x $y $w ($w*0.65) $red;$pts=[System.Drawing.Point[]]@((New-Object System.Drawing.Point([int]($x+$w*.4),[int]($y+$w*.15))),(New-Object System.Drawing.Point([int]($x+$w*.4),[int]($y+$w*.5))),(New-Object System.Drawing.Point([int]($x+$w*.68),[int]($y+$w*.325))));$g.FillPolygon([System.Drawing.Brushes]::White,$pts)}
function Pixelate($x,$y,$w,$h){$tmp=$b.Clone((New-Object System.Drawing.Rectangle($x,$y,$w,$h)),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);for($py=0;$py -lt $h;$py+=18){for($px=0;$px -lt $w;$px+=18){$c=$tmp.GetPixel([math]::Min($px+9,$w-1),[math]::Min($py+9,$h-1));Box ($x+$px) ($y+$py) ([math]::Min(18,$w-$px)) ([math]::Min(18,$h-$py)) $c}};$tmp.Dispose()}
$titles=@('PRICE IS NOT VALUE','WHY BREAKOUTS FAIL','WHAT REALLY DRIVES PRICE','STOP CHASING PRICE','MASTER AUCTION MARKET THEORY','READ THE MARKET','SMART MONEY MYTHS EXPLAINED','PRICE TO VALUE')
$slugs=@('Price_Is_Not_Value','Why_Breakouts_Fail','What_Really_Drives_Price','Stop_Chasing_Price','Master_Auction_Market_Theory','Read_The_Market','Smart_Money_Myths','Price_To_Value')
$manifest=@()
for($i=1;$i -le 8;$i++){
 Canvas ($i -eq 6)
 switch($i){
  1 {Laptop 'frame_17100.jpg';Photo 'Imre_white_cutout.png' 261 -5 1505 847;Text 'PRICE IS NOT' 25 15 755 98 92 $white 'SemiBold';Badge 'VALUE' 28 119 478 108 $white $black 102 'Bold';Badge 'Auction Market Theory' 235 646 650 61 $yellow $black 48;Arrow 760 611 760 546 706 475 679 451}
  2 {Laptop 'frame_66600.jpg';Photo 'Imre_white_cutout.png' 261 -5 1505 847;Text 'WHY' 28 15 300 100 94 $white 'SemiBold';Badge 'BREAKOUTS' 28 121 760 101 $white $black 90 'Bold';Text 'FAIL' 334 14 360 100 94 $white 'SemiBold';Badge 'Read the Market Regime' 235 646 650 61 $yellow $black 45;Arrow 760 611 760 546 706 475 679 451}
  3 {Photo '03_artwork.png' 0 0 1280 720;Text 'WHAT' 152 8 332 100 92 $white 'SemiBold';Badge 'REALLY' 501 11 555 93 $white $black 88 'Bold';Badge 'DRIVES' 470 121 342 73 $yellow $black 65 'Bold';Badge 'PRICE' 493 194 295 76 $yellow $black 69 'Bold';Badge '2 MARKET STATES' 735 460 500 66 $green $white 43;Arrow 629 284 556 388 560 541 632 612;Arrow 771 448 742 403 766 365 803 341}
  4 {Box 360 80 572 416 ([System.Drawing.Color]::FromArgb(130,130,130));SourceCrop 'frame_66600.jpg' 370 90 552 396 260 20 1390 1020;Photo 'Imre_white_cutout.png' -509 -3 1505 847;Photo 'Riz_beige_cutout.png' 187 0 1421 800;Badge 'PRICE vs VALUE' 470 28 340 60 $yellow $black 42;Text 'STOP CHASING' 264 497 782 105 84 $white 'SemiBold' $true;Badge 'PRICE' 430 610 420 100 $white $black 94 'Bold';Arrow 639 94 650 123 672 151 702 166}
  5 {Photo '05_artwork.png' 0 0 1280 720;Text 'MASTER' 26 9 425 96 88 $white 'SemiBold';Text 'AUCTION' 470 9 782 96 93 $yellow 'SemiBold';Text 'MARKET THEORY' 838 112 414 70 54 $white 'SemiBold';Line 851 190 1230 190 $yellow 4;Text '2 MARKET' 68 210 280 51 46 $white 'Medium';Text 'STATES' 91 260 252 51 46 $white 'Medium';Badge 'IMRE GAMS' 970 420 277 45 $black $white 30;Badge 'STEP BY STEP' 477 501 350 54 $black $white 36;Arrow 322 318 312 355 354 363 393 351;Arrow 589 593 623 580 642 570 644 558}
  6 {Box 125 158 1030 480 ([System.Drawing.Color]::FromArgb(250,250,250));Text 'READ THE' 36 13 562 98 86 $black 'SemiBold';Badge 'MARKET' 619 19 609 89 $yellow $black 84 'Bold';Text 'BALANCE' 175 187 252 41 30 $black 'Medium';Text 'IMBALANCE' 894 187 266 41 30 $black 'Medium';Line 179 250 397 250 $red;Line 179 363 397 363 $green;Line 179 306 397 306 ([System.Drawing.Color]::DodgerBlue) 2;Line 179 353 214 261 $black;Line 214 261 252 354 $black;Line 252 354 290 260 $black;Line 290 260 329 355 $black;Line 329 355 386 267 $black;Line 900 356 944 322 $black;Line 944 322 970 335 $black;Line 970 335 1008 280 $black;Line 1008 280 1043 294 $black;Line 1043 294 1107 245 $black;Text 'FAIR VALUE' 173 430 253 40 29 $black 'Medium';Text 'MICRO-RANGE' 898 430 257 40 27 $black 'Medium';Line 908 551 966 508 $black;Line 966 508 989 526 $black;Line 989 526 1007 507 $black;Line 1007 507 1030 521 $black;Line 1030 521 1075 470 $black;Line 963 500 1044 500 $red 2;Line 963 533 1044 533 $green 2;Line 179 510 382 510 ([System.Drawing.Color]::DodgerBlue) 4;Line 179 529 336 529 ([System.Drawing.Color]::DodgerBlue) 4;Line 179 548 371 548 ([System.Drawing.Color]::DodgerBlue) 4;Photo 'Imre_white_cutout.png' 41 132 1170 658}
  7 {Photo '07_artwork.png' 0 0 1280 720;Badge 'SMART MONEY MYTHS' 287 28 745 87 $red $white 61 'SemiBold';Text 'EXPLAINED' 391 122 535 68 61 $white 'Medium' $true;Text 'RIZ' 43 186 125 35 27 $white 'SemiBold';Text 'IMRE' 1145 184 109 35 27 $white 'SemiBold';Arrow 112 223 109 257 131 275 171 277 $white 3;Arrow 1191 225 1190 261 1166 278 1126 279 $white 3;PlayIcon 582 273 118}
  8 {Photo '08_artwork.png' 0 0 1280 720;Pixelate 247 137 151 178;Text 'PRICE' 48 14 392 91 87 $white 'SemiBold';Badge 'VALUE' 787 17 447 91 $red $white 88 'SemiBold';Arrow 468 60 554 60 643 60 740 60 $white 9;Badge 'BALANCE' 29 159 220 49 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 28;Badge 'REGIME' 439 212 230 48 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 28;Badge 'MICRO-RANGE' 620 159 250 49 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 27;Badge 'FAIR VALUE' 1088 225 175 48 ([System.Drawing.Color]::FromArgb(46,67,83)) $white 27;PlayIcon 573 349 126}
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
$manifest | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Exports_manifest.csv')
function Sheet($tw,$th,$name){$sheet=New-Object System.Drawing.Bitmap(($tw*2),(($th+30)*4));$sg=[System.Drawing.Graphics]::FromImage($sheet);$sg.Clear([System.Drawing.Color]::FromArgb(22,22,22));$sg.InterpolationMode='HighQualityBicubic';$f=New-Object System.Drawing.Font('Arial',14);for($j=0;$j -lt 8;$j++){$id='{0:00}' -f ($j+1);$im=[System.Drawing.Image]::FromFile((Join-Path $preview ($id+'_1280.jpg')));$x=($j%2)*$tw;$y=[int][math]::Floor($j/2)*($th+30);$sg.DrawImage($im,$x,$y,$tw,$th);$sg.DrawString(($id+'  '+$titles[$j]),$f,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+$th+4));$im.Dispose()};$f.Dispose();$sg.Dispose();$sheet.Save((Join-Path $preview $name),[System.Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()}
Sheet 640 360 'Planche_8_Thumbnails_V01.jpg'
Sheet 320 180 'Controle_Mobile_V01.jpg'
Write-Output 'Eight masters, exports and previews rendered.'

