param([switch]$Final)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot;$assets=Join-Path $root 'Masters\V01';$preview=Join-Path $root 'Apercus\V01';$exports=Join-Path $root 'Exports_4K\V01';$src=Join-Path $root 'Sources_HD'
$WhiteColor=[System.Drawing.Color]::White;$BlackColor=[System.Drawing.Color]::FromArgb(10,10,10);$YellowColor=[System.Drawing.Color]::FromArgb(255,230,0);$RedColor=[System.Drawing.Color]::FromArgb(237,23,23);$GreenColor=[System.Drawing.Color]::FromArgb(0,148,58);$Blue=[System.Drawing.Color]::FromArgb(46,64,78)
$metrics=New-Object System.Collections.Generic.List[object]
. (Join-Path $PSScriptRoot 'drawing_functions.ps1')
if($Final){. (Join-Path $PSScriptRoot 'add_final_noise.ps1')}
function Glow {} # No neon or decorative halo.
function Person($name,$cx,$top,$height,$flip=$false){
 $info=switch($name){'Casper_front_photo.png'{@(687,36,282)};'Casper_explain_photo.png'{@(742,54,336)};'Casper_conversation_photo.png'{@(718,48,288)};'Riz_front_photo.png'{@(642,66,346)};'Riz_conversation_photo.png'{@(672,78,345)}}
 $im=[System.Drawing.Image]::FromFile((Join-Path $assets $name));$sx=$info[0];if($flip){$im.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX);$sx=1280-$sx}
 $scale=$height/$info[2];$g.DrawImage($im,[single]($cx-$sx*$scale),[single]($top-$info[1]*$scale),[single](1280*$scale),[single](720*$scale));$im.Dispose()
}
function BoardImage($file){
 $im=[System.Drawing.Bitmap]::FromFile((Join-Path $src ('Tableau\'+$file)))
 $b=$im.Clone([System.Drawing.Rectangle]::new(715,180,2380,1775),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$im.Dispose();$b.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone);return $b
}
function Board($file,$x,$y,$w,$h,$fit=$false){
 $im=BoardImage $file
 if($fit){$ratio=[math]::Min($w/$im.Width,$h/$im.Height);$dw=$im.Width*$ratio;$dh=$im.Height*$ratio;Rect $x $y $w $h $BlackColor;$g.DrawImage($im,[single]($x+($w-$dw)/2),[single]($y+($h-$dh)/2),[single]$dw,[single]$dh)}
 else{$g.DrawImage($im,[single]$x,[single]$y,[single]$w,[single]$h)}
 $im.Dispose()
}
function TableFront($y=620){$im=[System.Drawing.Image]::FromFile((Join-Path $assets 'conversation_studio_plate.png'));$rect=[System.Drawing.RectangleF]::new(0,$y,1280,(720-$y));$g.DrawImage($im,$rect,[System.Drawing.RectangleF]::new(0,($im.Height*.79),$im.Width,($im.Height*.21)),[System.Drawing.GraphicsUnit]::Pixel);$im.Dispose()}
function LaptopBack($x,$y,$w){
 $im=[System.Drawing.Image]::FromFile((Join-Path $root 'References\07_Hidden_Orders_Revealed_master.png'))
 $save=$g.Save();$scale=$w/566;$g.TranslateTransform([single]$x,[single]$y);$g.ScaleTransform([single]$scale,[single]$scale);$p=New-Object System.Drawing.Drawing2D.GraphicsPath
 $p.AddPolygon([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(2,0),[System.Drawing.PointF]::new(467,41),[System.Drawing.PointF]::new(490,229),[System.Drawing.PointF]::new(562,235),[System.Drawing.PointF]::new(557,258),[System.Drawing.PointF]::new(491,328),[System.Drawing.PointF]::new(46,282)))
 $g.SetClip($p);$g.DrawImage($im,[single]-672,[single]-608,[single]1672,[single]941);$g.Restore($save);$p.Dispose();$im.Dispose()
}
function LightBoard {
 Gradient 0 0 1280 720 (C 255 233 232 221) (C 255 199 204 195)
 Rounded 71 165 1138 505 (C 65 0 0 0) 7;Rounded 67 158 1138 505 (C 255 248 249 246) 7
 foreach($pt in @(@(88,178),@(1176,178),@(88,630),@(1176,630))){$g.FillEllipse([System.Drawing.Brushes]::Silver,[single]$pt[0],[single]$pt[1],10,10)}
 CompactRow 'READ THE' 'MARKET' 36 24 106 $BlackColor $BlackColor $false 1208 $true 19
 Rect 610 119 582 10 $YellowColor
 Ink 'CONDITION' 119 207 35 $BlackColor 'SemiBold';Ink 'ZONES' 950 206 38 $BlackColor 'SemiBold'
 Stroke @(119,285,161,257,204,305,246,261,293,306,339,267) $Blue 4
 Stroke @(119,250,344,250) $RedColor 3;Stroke @(119,321,344,321) $GreenColor 3
 $bars=@(32,57,92,133,152,143,109,76,48)
 for($v=0;$v -lt $bars.Count;$v++){Rect 949 (270+$v*18) $bars[$v] 12 (C 255 51 123 161)}
 Ink 'BALANCE / TREND' 117 364 23 $BlackColor 'Medium'
 Ink 'TRIGGER' 936 475 34 $BlackColor 'SemiBold';Stroke @(935,577,958,565,979,583,1000,552,1019,570,1042,526,1084,501,1126,479) $BlackColor 4
 Stroke @(936,540,1119,540) $RedColor 2 $true
 Person 'Casper_front_photo.png' 633 147 355
}
$slugs=@('Trade_With_A_System','Who_Is_In_Control','Trading_In_3_Decisions','Stop_Overthinking','Master_Volume_Profile','Read_The_Market','Let_Your_Winners_Run','Price_To_Order_Flow')
for($i=1;$i -le 8;$i++){
 $script:id='{0:00}' -f $i;$script:canvas=New-Object System.Drawing.Bitmap(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$script:g=[System.Drawing.Graphics]::FromImage($canvas);$g.Clear((C 255 24 25 26));$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
 switch($i){
  1 {
   Photo 'laptop_plate.png' 0 40 1280 720;Board 'Tableau_00-23-00.jpg' 93 247 609 363 $true
   Person 'Casper_front_photo.png' 1030 24 485
   Ink 'TRADE WITH A' 27 28 91 $WhiteColor 'SemiBold' 746 $true
   $null=Badge 'SYSTEM' 27 118 111 $WhiteColor $BlackColor 'Bold' 15 10
   $null=Badge 'Condition - Zones - Trigger' 210 639 42 $YellowColor $BlackColor 'Medium' 16 11 715
   Arrow 758 625 779 554 732 502 676 471 $YellowColor 7
  }
  2 {
   Photo 'laptop_plate.png' 0 40 1280 720;Board 'Tableau_00-31-00.jpg' 93 247 609 363 $true
   Person 'Casper_front_photo.png' 1030 24 485
   Ink "WHO'S IN" 28 25 102 $WhiteColor 'SemiBold' 734 $true
   $null=Badge 'CONTROL?' 28 126 104 $WhiteColor $BlackColor 'Bold' 15 10 735
   $null=Badge 'Read the Volume Profile' 231 639 44 $YellowColor $BlackColor 'Medium' 16 11 711
   Arrow 758 625 779 554 732 502 676 471 $YellowColor 7
  }
  3 {
   Photo 'conversation_studio_plate.png';Gradient 0 0 1280 620 (C 230 8 10 12) (C 225 25 25 25)
   Person 'Riz_front_photo.png' 262 143 318;Person 'Casper_conversation_photo.png' 1004 139 300
   TableFront 625;Board 'Tableau_00-23-00.jpg' 414 624 471 123
   CompactRow 'TRADING' 'IN' 32 14 100 $WhiteColor $BlackColor $true 1216 $true 18
   Panel 452 168 377 151 $YellowColor $false 10;Fit '3' 471 176 339 58 80 $BlackColor 'Bold';Fit 'DECISIONS' 466 248 349 47 55 $BlackColor 'Bold'
   Panel 744 508 498 61 $GreenColor $false 9;Fit 'A CLEAR TRADING SYSTEM' 754 520 478 36 35 $WhiteColor 'Medium'
   Arrow 636 343 591 405 594 532 654 640 $YellowColor 7;Arrow 855 493 819 454 836 424 865 403 $YellowColor 6
  }
  4 {
   Gradient 0 0 1280 720 (C 255 47 47 45) (C 255 12 14 16)
   Panel 319 132 646 405 (C 255 110 113 113) $false 9;Board 'Tableau_00-23-00.jpg' 327 141 630 388 $true
   Person 'Casper_front_photo.png' 238 23 442;Person 'Riz_front_photo.png' 1040 21 445 $true
   $null=Badge 'CONDITION / ZONES / TRIGGER' 425 28 29 $YellowColor $BlackColor 'SemiBold' 15 11 438
   Arrow 644 91 630 113 650 144 680 162 $YellowColor 6
   Gradient 0 420 1280 300 (C 0 0 0 0) (C 255 0 0 0)
   Fit 'STOP' 365 510 550 75 100 $WhiteColor 'SemiBold' $true
   $null=Badge 'OVERTHINKING' 196 606 88 $WhiteColor $BlackColor 'Bold' 19 12 888
  }
  5 {
   Photo 'warm_studio_plate.png';Gradient 0 0 1280 200 (C 200 0 0 0) (C 0 0 0 0)
   Board 'Tableau_00-31-00.jpg' 348 595 566 174
   Person 'Casper_explain_photo.png' 673 143 262
   CompactRow 'MASTER' 'VOLUME' 25 17 112 $WhiteColor $YellowColor $false 1230 $false 17
   Fit 'PROFILE' 880 135 367 74 88 $WhiteColor 'SemiBold' $true;Stroke @(882,220,1235,220) $YellowColor 4
   Panel 53 235 295 105 (C 215 15 15 15) $false 10;Fit '3 CLEAR' 67 247 267 34 43 $WhiteColor 'SemiBold';Fit 'DECISIONS' 67 295 267 32 39 $WhiteColor 'SemiBold'
   Arrow 280 358 277 401 350 410 423 393 $YellowColor 6
   Panel 952 419 277 60 (C 230 17 17 17) $false 26;Fit 'CASPER' 966 432 249 34 45 $WhiteColor 'Medium'
   Panel 455 521 405 65 (C 242 15 15 15) $false 12;Fit 'STEP BY STEP' 472 533 371 40 44 $WhiteColor 'SemiBold'
   Arrow 882 624 894 592 879 558 861 553 $YellowColor 6
  }
  6 {LightBoard}
  7 {
   Photo 'conversation_studio_plate.png';Gradient 0 0 1280 270 (C 160 0 0 0) (C 0 0 0 0)
   Person 'Riz_conversation_photo.png' 268 143 298;Person 'Casper_conversation_photo.png' 1005 141 284
   TableFront 626;LaptopBack 457 474 444
   $null=Badge 'LET YOUR WINNERS' 278 27 65 $RedColor $WhiteColor 'SemiBold' 17 12 763
   Fit 'RUN' 506 120 306 64 85 $WhiteColor 'Regular' $true
   Ink 'RIZ' 45 103 29 $WhiteColor 'SemiBold' 9999 $true;Ink 'CASPER' 1111 99 29 $WhiteColor 'SemiBold' 9999 $true
   Arrow 68 146 56 192 89 235 143 236 $WhiteColor 3;Arrow 1177 142 1189 185 1158 220 1118 235 $WhiteColor 3
   Youtube 563 288 139
  }
  8 {
   Photo 'conversation_studio_plate.png';Gradient 0 0 1280 300 (C 150 0 0 0) (C 0 0 0 0)
   Person 'Casper_conversation_photo.png' 268 141 305 $true;Person 'Riz_conversation_photo.png' 1020 137 305 $true
   TableFront 627;Board 'Tableau_00-31-00.jpg' 366 635 548 148
   Pixelate 183 215 168 212
   Ink 'PRICE' 59 27 97 $WhiteColor 'SemiBold' 9999 $true;Arrow 422 65 501 65 571 65 644 65 $WhiteColor 12
   $null=Badge 'ORDER FLOW' 701 25 75 $RedColor $WhiteColor 'SemiBold' 19 14 534
   Panel 18 160 180 54 $Blue $false 12;Fit 'CONDITION' 26 171 164 30 28 $WhiteColor 'Medium'
   Panel 429 240 170 55 $Blue $false 12;Fit 'ZONES' 442 251 144 31 31 $WhiteColor 'Medium'
   Panel 689 169 189 54 $Blue $false 12;Fit 'TRIGGER' 701 181 165 29 31 $WhiteColor 'Medium'
   Arrow 200 181 270 131 355 158 427 254 $WhiteColor 3 $true;Arrow 601 267 653 302 704 267 749 226 $WhiteColor 3 $true
   Youtube 563 365 147
  }
 }
 $g.Dispose();$name=$id+'_'+$slugs[$i-1];$canvas.Save((Join-Path $assets ($name+'_master.png')),[System.Drawing.Imaging.ImageFormat]::Png)
 if($Final){[ThumbnailNoise]::Apply($canvas,5.0,(812010+$i));$canvas.Save((Join-Path $exports ($name+'_3840x2160.png')),[System.Drawing.Imaging.ImageFormat]::Png)}
 foreach($size in @(1280,320)){$small=New-Object System.Drawing.Bitmap($size,[int]($size*9/16));$sg=[System.Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$small.Width,$small.Height);$sg.Dispose();$small.Save((Join-Path $preview ($id+'_'+$size+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$small.Dispose()};$canvas.Dispose();Write-Output ('Rendered '+$id)
}
$metrics | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Typography_geometry_V01.csv')
foreach($tw in @(640,320)){
 $th=[int]($tw*9/16);$sheet=New-Object System.Drawing.Bitmap(($tw*2),(($th+26)*4));$sg=[System.Drawing.Graphics]::FromImage($sheet);$sg.Clear((C 255 20 20 20));$sg.InterpolationMode='HighQualityBicubic';$font=New-Object System.Drawing.Font('Arial',12,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
 for($j=0;$j -lt 8;$j++){$label='{0:00}' -f ($j+1);$im=[System.Drawing.Image]::FromFile((Join-Path $preview ($label+'_1280.jpg')));$x=($j%2)*$tw;$y=[int][math]::Floor($j/2)*($th+26);$sg.DrawImage($im,$x,$y,$tw,$th);$sg.DrawString(('CASPER / '+$label),$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+$th+6));$im.Dispose()};$sg.Dispose();$font.Dispose();$sheet.Save((Join-Path $preview ('Planche_V01_'+$tw+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
}

