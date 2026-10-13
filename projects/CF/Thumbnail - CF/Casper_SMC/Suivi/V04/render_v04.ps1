param([switch]$Final)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V04';$preview=Join-Path $root 'Apercus\V04';$exports=Join-Path $root 'Exports_4K\V04';$src=Join-Path $root 'Sources_HD'
$WhiteColor=[System.Drawing.Color]::White;$BlackColor=[System.Drawing.Color]::FromArgb(10,14,18);$YellowColor=[System.Drawing.Color]::FromArgb(255,226,0);$RedColor=[System.Drawing.Color]::FromArgb(241,22,22);$GreenColor=[System.Drawing.Color]::FromArgb(0,161,66);$Blue=[System.Drawing.Color]::FromArgb(26,68,95)
$metrics=New-Object System.Collections.Generic.List[object]
. (Join-Path (Split-Path $PSScriptRoot) 'drawing_functions.ps1')
function Glow {}
function ElectricPanel($x,$y,$w,$h,$radius=10){
 for($n=30;$n -ge 1;$n--){$a=[int][math]::Round(6*[math]::Exp(-$n*$n/245));if($a -gt 0){Rounded ($x-$n) ($y-$n) ($w+2*$n) ($h+2*$n) (C $a 0 153 255) ($radius+$n)}}
 $p=RoundPath $x $y $w $h $radius
 $brush=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),(C 255 7 125 255),(C 255 0 68 238))
 $g.FillPath($brush,$p);$brush.Dispose()
 $pen=[System.Drawing.Pen]::new((C 235 112 228 255),1.35);$g.DrawPath($pen,$p);$pen.Dispose();$p.Dispose()
}
function LaptopPlate { $im=[System.Drawing.Image]::FromFile((Join-Path $assets 'laptop_plate.png'));$g.DrawImage($im,[System.Drawing.RectangleF]::new(0,0,1280,42),[System.Drawing.RectangleF]::new(0,0,$im.Width,1),[System.Drawing.GraphicsUnit]::Pixel);$im.Dispose();Photo 'laptop_plate.png' 0 40 1280 720 }
function Person($name,$cx,$top,$height,$flip=$false){$info=switch($name){'Casper_front_photo.png'{@(687,36,282)};'Riz_front_photo.png'{@(642,66,346)}};$im=[System.Drawing.Image]::FromFile((Join-Path $assets $name));$sx=$info[0];if($flip){$im.RotateFlip('RotateNoneFlipX');$sx=1280-$sx};$scale=$height/$info[2];$g.DrawImage($im,[single]($cx-$sx*$scale),[single]($top-$info[1]*$scale),[single](1280*$scale),[single](720*$scale));$im.Dispose()}
function Board($file,$x,$y,$w,$h){$im=[System.Drawing.Bitmap]::FromFile((Join-Path $src ('Tableau\'+$file)));$b=$im.Clone([System.Drawing.Rectangle]::new(715,180,2380,1775),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$im.Dispose();$b.RotateFlip('Rotate180FlipNone');$ratio=[math]::Min($w/$b.Width,$h/$b.Height);$dw=$b.Width*$ratio;$dh=$b.Height*$ratio;Rect $x $y $w $h $BlackColor;$g.DrawImage($b,[single]($x+($w-$dw)/2),[single]($y+($h-$dh)/2),[single]$dw,[single]$dh);$b.Dispose()}
function Candle($x,$y,$h,$up=$true,$w=11){$color=if($up){$GreenColor}else{$RedColor};Stroke @($x,($y-9),$x,($y+$h+10)) $color 2;Rect ($x-$w/2) $y $w $h $color}
function Stage($n,$title,$x,$y,$w){Rounded $x $y 37 37 $YellowColor 7;Fit $n ($x+4) ($y+6) 29 25 30 $BlackColor 'Bold';Ink $title ($x+49) ($y+5) 35 $BlackColor 'SemiBold' ($w-49)}
function LightBoard {
 Gradient 0 0 1280 720 (C 255 226 230 224) (C 255 191 201 192)
 Rounded 30 144 1222 552 (C 48 15 28 29) 9;Rounded 25 136 1226 549 (C 255 249 250 247) 9
 for($xx=50;$xx -lt 1240;$xx+=25){Stroke @($xx,159,$xx,667) (C 11 49 84 102) .65};for($yy=160;$yy -lt 668;$yy+=25){Stroke @(43,$yy,1235,$yy) (C 11 49 84 102) .65}
 CompactRow 'READ THE' 'MARKET' 50 25 98 $BlackColor $BlackColor $false 1180 $true 26
 $a=MeasureInk 'READ THE' 98 'SemiBold';$b=MeasureInk 'MARKET' 98 'Bold';$left=(1280-$a.Width-$b.Width-26)/2;Rect ($left+$a.Width+14) 20 ($b.Width+24) 88 $YellowColor;Ink 'MARKET' ($left+$a.Width+26) 31 98 $BlackColor 'Bold'
 Stage '1' 'CONDITION' 64 173 340
 Ink 'BALANCE' 68 228 25 $Blue 'SemiBold'
 Photo 'chart_balance.png' 65 264 306 79
 Ink 'TREND' 70 363 25 $Blue 'SemiBold'
 Photo 'chart_trend.png' 69 391 291 79
 Stage '3' 'TRIGGER' 65 491 322
 Photo 'chart_trigger.png' 67 531 305 88
 Ink '2-MIN STRUCTURE BREAK' 67 634 20 $Blue 'Medium'
 Stage '2' 'ZONES' 905 173 308
 Ink 'VOLUME AT PRICE' 908 227 23 $Blue 'SemiBold'
 Photo 'chart_profile.png' 902 259 307 188
 foreach($item in @(@('VAH',283),@('POC',343),@('VAL',405))){Ink $item[0] 1170 ($item[1]-9) 22 $Blue 'SemiBold'}
 Ink 'VALUE AREA' 908 463 24 $Blue 'SemiBold'
 Photo 'chart_accept.png' 919 489 290 129
 Ink 'ACCEPT / REJECT' 986 624 21 $Blue 'Medium'
 Person 'Casper_front_photo.png' 638 160 359
 ElectricPanel 414 625 453 63 9;Fit 'CONDITION / ZONES / TRIGGER' 427 642 427 29 27 $WhiteColor 'Medium'
}
$cs=@'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class V4Grain { public static void Tone(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);try{var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);for(int p=0;p<v.Length;p+=4){double l=.0722*v[p]+.7152*v[p+1]+.2126*v[p+2];for(int c=0;c<3;c++){double z=l+(v[p+c]-l)*1.075;z=(z-118)*1.065+118;v[p+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(z)));}}Marshal.Copy(v,0,d.Scan0,v.Length);}finally{b.UnlockBits(d);}} public static void Add(Bitmap b,int seed){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);try{var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);var r=new Random(seed);for(int p=0;p<v.Length;p+=4){double n=(r.NextDouble()*2-1)*12.75;for(int c=0;c<3;c++)v[p+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(v[p+c]+n)));}Marshal.Copy(v,0,d.Scan0,v.Length);}finally{b.UnlockBits(d);}}}
'@
$rt=Split-Path ([System.Drawing.Bitmap].Assembly.Location);Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $rt 'System.Private.Windows.GdiPlus.dll'),(Join-Path $rt 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$slugs=@('Trade_With_A_System','Who_Is_In_Control','Trading_In_3_Decisions','Stop_Overthinking','Master_Volume_Profile','Read_The_Market','Let_Your_Winners_Run','Price_To_Order_Flow')
for($i=1;$i -le 8;$i++){
 $script:id='{0:00}' -f $i;$script:canvas=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$script:g=[System.Drawing.Graphics]::FromImage($canvas);$g.Clear((C 255 16 18 22));$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
 switch($i){
 1 {LaptopPlate;Board 'Tableau_00-23-00.jpg' 93 247 609 363;Person 'Casper_front_photo.png' 1030 24 485;Ink 'TRADE WITH A' 27 28 91 $WhiteColor 'SemiBold' 746 $true;$null=Badge 'SYSTEM' 27 118 111 $WhiteColor $BlackColor 'Bold' 15 10;$null=Badge 'Condition - Zones - Trigger' 210 639 42 $YellowColor $BlackColor 'Medium' 16 11 715;Arrow 758 625 779 554 732 502 676 471 $YellowColor 7}
 2 {LaptopPlate;Board 'Tableau_00-31-00.jpg' 93 247 609 363;Person 'Casper_front_photo.png' 1030 24 485;Ink "WHO'S IN" 28 25 102 $WhiteColor 'SemiBold' 734 $true;$null=Badge 'CONTROL?' 28 126 104 $WhiteColor $BlackColor 'Bold' 15 10 735;$null=Badge 'Read the Volume Profile' 231 639 44 $YellowColor $BlackColor 'Medium' 16 11 711;Arrow 758 625 779 554 732 502 676 471 $YellowColor 7}
 3 {Photo '03_scene_photo_test.png';Gradient 0 0 1280 130 (C 135 0 0 0) (C 0 0 0 0);CompactRow 'TRADING' 'IN' 32 14 100 $WhiteColor $BlackColor $true 1216 $true 18;Panel 452 174 377 151 $YellowColor $false 10;Fit '3' 471 182 339 58 80 $BlackColor 'Bold';Fit 'DECISIONS' 466 254 349 47 55 $BlackColor 'Bold';Panel 772 470 481 58 $GreenColor $false 9;Fit 'A CLEAR TRADING SYSTEM' 783 482 459 35 34 $WhiteColor 'Medium';Arrow 627 346 587 411 589 553 619 628 $YellowColor 7;Arrow 847 457 827 424 841 398 865 385 $YellowColor 6}
 4 {Gradient 0 0 1280 720 (C 255 34 42 48) (C 255 4 10 15);Panel 319 132 646 405 (C 255 98 105 113) $false 9;Board 'Tableau_00-23-00.jpg' 327 141 630 388;Person 'Casper_front_photo.png' 238 23 442;Person 'Riz_front_photo.png' 1040 21 445 $true;$null=Badge 'CONDITION / ZONES / TRIGGER' 425 28 29 $YellowColor $BlackColor 'SemiBold' 15 11 438;Arrow 644 91 630 113 650 144 680 162 $YellowColor 6;Gradient 0 420 1280 300 (C 0 0 0 0) (C 255 0 0 0);Fit 'STOP' 365 510 550 75 100 $WhiteColor 'SemiBold' $true;$null=Badge 'OVERTHINKING' 196 606 88 $WhiteColor $BlackColor 'Bold' 19 12 888}
 5 {Photo '05_scene_photo_test.png';Gradient 0 0 1280 106 (C 130 0 0 0) (C 0 0 0 0);CompactRow 'MASTER' 'VOLUME' 24 10 88 $WhiteColor $YellowColor $false 1230 $false 19;Fit 'PROFILE' 896 107 350 68 82 $WhiteColor 'SemiBold' $true;Stroke @(903,183,1235,183) $YellowColor 4;Panel 47 220 288 108 (C 217 12 17 22) $false 10;Fit '3 CLEAR' 61 232 260 33 40 $WhiteColor 'SemiBold';Fit 'DECISIONS' 61 281 260 34 40 $WhiteColor 'SemiBold';Arrow 276 346 274 379 355 402 419 368 $YellowColor 6;Panel 995 412 238 56 (C 224 12 17 22) $false 23;Fit 'CASPER' 1006 424 216 33 43 $WhiteColor 'Medium';Panel 462 518 365 62 (C 228 12 17 22) $false 10;Fit 'STEP BY STEP' 476 532 337 34 39 $WhiteColor 'SemiBold';Arrow 901 584 888 557 862 548 831 548 $YellowColor 6}
 6 {LightBoard}
 7 {Photo '07_scene_photo_test.png';Gradient 0 0 1280 160 (C 120 0 0 0) (C 0 0 0 0);$null=Badge 'LET YOUR WINNERS' 278 23 65 $RedColor $WhiteColor 'SemiBold' 17 12 763;Fit 'RUN' 506 117 306 64 85 $WhiteColor 'Regular' $true;Ink 'RIZ' 42 83 29 $WhiteColor 'SemiBold' 9999 $true;Ink 'CASPER' 1103 73 29 $WhiteColor 'SemiBold' 9999 $true;Arrow 68 128 56 160 146 210 208 194 $WhiteColor 3;Arrow 1177 118 1187 158 1088 196 1040 188 $WhiteColor 3;Youtube 569 281 139}
 8 {Photo '08_scene_photo_test.png';Gradient 0 0 1280 132 (C 130 0 0 0) (C 0 0 0 0);Pixelate 222 143 142 144;Ink 'PRICE' 46 25 97 $WhiteColor 'SemiBold' 9999 $true;Arrow 409 62 487 62 564 62 636 62 $WhiteColor 11;$null=Badge 'ORDER FLOW' 689 20 77 $RedColor $WhiteColor 'SemiBold' 19 14 548;ElectricPanel 20 198 184 52 10;Fit 'CONDITION' 29 211 165 26 28 $WhiteColor 'Medium';ElectricPanel 441 249 170 55 10;Fit 'ZONES' 454 261 144 30 31 $WhiteColor 'Medium';ElectricPanel 682 172 184 53 10;Fit 'TRIGGER' 692 184 164 29 31 $WhiteColor 'Medium';Arrow 209 194 307 132 381 176 450 253 $WhiteColor 3 $true;Arrow 614 276 657 311 717 279 750 231 $WhiteColor 3 $true;Youtube 576 369 137}
 }
  $g.Dispose();[V4Grain]::Tone($canvas);$name=$id+'_'+$slugs[$i-1];$canvas.Save((Join-Path $assets ($name+'_master.png')),[System.Drawing.Imaging.ImageFormat]::Png)
 if($Final){[V4Grain]::Add($canvas,(20261012+$i));$canvas.Save((Join-Path $exports ($name+'_3840x2160.png')),[System.Drawing.Imaging.ImageFormat]::Png)}
 foreach($size in @(1280,320)){$small=[System.Drawing.Bitmap]::new($size,[int]($size*9/16));$sg=[System.Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$small.Width,$small.Height);$sg.Dispose();$small.Save((Join-Path $preview ($id+'_'+$size+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$small.Dispose()};$canvas.Dispose();Write-Output ('Rendered '+$id)
}
$metrics|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Typography_geometry_V04.csv')
foreach($tw in @(640,320)){$th=[int]($tw*9/16);$sheet=[System.Drawing.Bitmap]::new(($tw*2),(($th+26)*4));$sg=[System.Drawing.Graphics]::FromImage($sheet);$sg.Clear((C 255 20 20 20));$sg.InterpolationMode='HighQualityBicubic';$font=[System.Drawing.Font]::new('Arial',12,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel);for($j=0;$j -lt 8;$j++){$label='{0:00}' -f ($j+1);$im=[System.Drawing.Image]::FromFile((Join-Path $preview ($label+'_1280.jpg')));$x=($j%2)*$tw;$y=[int][math]::Floor($j/2)*($th+26);$sg.DrawImage($im,$x,$y,$tw,$th);$sg.DrawString(('CASPER / V04 / '+$label),$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+$th+6));$im.Dispose()};$sg.Dispose();$font.Dispose();$sheet.Save((Join-Path $preview ('Planche_V04_'+$tw+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()}





