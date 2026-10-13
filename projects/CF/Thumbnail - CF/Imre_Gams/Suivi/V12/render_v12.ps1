param([switch]$Final)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$jpeg=[System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$quality=[System.Drawing.Imaging.EncoderParameters]::new(1);$quality.Param[0]=[System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality,[long]95)
$root=Split-Path (Split-Path $PSScriptRoot)
$assets=Join-Path $root 'Masters\V12'
$preview=Join-Path $root 'Apercus\V12'
$exports=Join-Path $root 'Exports\V12'
$src=Join-Path $root 'Sources_HD'
. (Join-Path $PSScriptRoot 'soft_glow.ps1')

$WhiteColor=[System.Drawing.Color]::White
$BlackColor=[System.Drawing.Color]::FromArgb(10,10,10)
$YellowColor=[System.Drawing.Color]::FromArgb(255,230,0)
$RedColor=[System.Drawing.Color]::FromArgb(255,0,14)
$GreenColor=[System.Drawing.Color]::FromArgb(0,177,73)
$Blue=[System.Drawing.Color]::FromArgb(46,64,78)
$metrics=New-Object System.Collections.Generic.List[object]
function C($a,$r,$gg,$bb){return [System.Drawing.Color]::FromArgb([int]$a,[int]$r,[int]$gg,[int]$bb)}
function Rect($x,$y,$w,$h,$color){$br=New-Object System.Drawing.SolidBrush($color);$g.FillRectangle($br,[single]$x,[single]$y,[single]$w,[single]$h);$br.Dispose()}
function RoundPath($x,$y,$w,$h,$radius=12){$p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$radius*2;$p.AddArc([single]$x,[single]$y,[single]$d,[single]$d,180,90);$p.AddArc([single]($x+$w-$d),[single]$y,[single]$d,[single]$d,270,90);$p.AddArc([single]($x+$w-$d),[single]($y+$h-$d),[single]$d,[single]$d,0,90);$p.AddArc([single]$x,[single]($y+$h-$d),[single]$d,[single]$d,90,90);$p.CloseFigure();return $p}
function Rounded($x,$y,$w,$h,$color,$r=12){$p=RoundPath $x $y $w $h $r;$br=New-Object System.Drawing.SolidBrush($color);$g.FillPath($br,$p);$p.Dispose();$br.Dispose()}
function Gradient($x,$y,$w,$h,$top,$bottom){$br=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.PointF([single]$x,[single]$y)),(New-Object System.Drawing.PointF([single]$x,[single]($y+$h))),$top,$bottom);$g.FillRectangle($br,[single]$x,[single]$y,[single]$w,[single]$h);$br.Dispose()}
function Glow($x,$y,$w,$h,$color){for($n=16;$n -ge 1;$n--){$a=[int][math]::Round(4*[math]::Exp(-$n*$n/70));if($a -gt 0){Rounded ($x-$n) ($y-$n) ($w+2*$n) ($h+2*$n) (C $a $color.R $color.G $color.B) (12+$n)}}}
function Panel($x,$y,$w,$h,$color,$glow=$false,$radius=11){
 if($glow){Glow $x $y $w $h $color}
 for($n=5;$n -ge 1;$n--){Rounded ($x-$n) ($y+4-$n) ($w+2*$n) ($h+2*$n) (C 8 0 0 0) ($radius+$n)}
 $p=RoundPath $x $y $w $h $radius
 $bottom=$color;if($color.ToArgb() -eq $WhiteColor.ToArgb()){$bottom=C 255 230 230 230}elseif($color.ToArgb() -eq $RedColor.ToArgb()){$bottom=C 255 222 0 0}
 $br=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.PointF([single]$x,[single]$y)),(New-Object System.Drawing.PointF([single]$x,[single]($y+$h))),$color,$bottom)
 $g.FillPath($br,$p);$br.Dispose();$pen=New-Object System.Drawing.Pen((C 90 255 255 255),1);$g.DrawPath($pen,$p);$pen.Dispose();$p.Dispose()
}
function Glyph($s,$size,$weight='SemiBold'){
 $family=if($weight -eq 'Bold'){'Poppins'}elseif($weight -eq 'Regular'){'Poppins'}else{'Poppins '+$weight}
 $style=if($weight -eq 'Bold'){1}else{0}
 $ff=New-Object System.Drawing.FontFamily($family);$p=New-Object System.Drawing.Drawing2D.GraphicsPath
 $p.AddString($s,$ff,$style,[single]$size,(New-Object System.Drawing.PointF(0,0)),[System.Drawing.StringFormat]::GenericTypographic);$ff.Dispose();return $p
}
function MeasureInk($s,$size,$weight='SemiBold'){$p=Glyph $s $size $weight;$bb=$p.GetBounds();$p.Dispose();return $bb}
function Ink($s,$x,$y,$size,$color,$weight='SemiBold',$maxW=9999,$shadow=$false){
 $p=Glyph $s $size $weight;$bb=$p.GetBounds();$scale=[math]::Min(1.0,$maxW/$bb.Width)
 $m=New-Object System.Drawing.Drawing2D.Matrix([single]$scale,0,0,[single]$scale,[single]($x-$bb.X*$scale),[single]($y-$bb.Y*$scale));$p.Transform($m);$m.Dispose()
 if($shadow){$state=$g.Save();$g.TranslateTransform(0,3);foreach($sw in @(12,8,4)){$pen=New-Object System.Drawing.Pen((C 15 0 0 0),[single]$sw);$pen.LineJoin='Round';$g.DrawPath($pen,$p);$pen.Dispose()};$br=New-Object System.Drawing.SolidBrush((C 145 0 0 0));$g.FillPath($br,$p);$br.Dispose();$g.Restore($state)}
 $br=New-Object System.Drawing.SolidBrush($color);$g.FillPath($br,$p);$br.Dispose();$p.Dispose()
 $metrics.Add([pscustomobject]@{Image=$script:id;Text=$s;X=$x;Y=$y;Width=[math]::Round($bb.Width*$scale,2);Height=[math]::Round($bb.Height*$scale,2);Font=$size;Weight=$weight})
}
function Fit($s,$x,$y,$w,$h,$size,$color,$weight='SemiBold',$shadow=$false){$bb=MeasureInk $s $size $weight;$ratio=[math]::Min(1.0,[math]::Min($w/$bb.Width,$h/$bb.Height));$size*=$ratio;$bb=MeasureInk $s $size $weight;Ink $s ($x+($w-$bb.Width)/2) ($y+($h-$bb.Height)/2) $size $color $weight 9999 $shadow}
function Badge($s,$x,$y,$size,$bg,$fg,$weight='Bold',$padX=14,$padY=10,$maxW=9999){
 $bb=MeasureInk $s $size $weight;if($bb.Width+2*$padX -gt $maxW){$size*=($maxW-2*$padX)/$bb.Width;$bb=MeasureInk $s $size $weight}
 $w=$bb.Width+2*$padX;$h=$bb.Height+2*$padY;$hasGlow=$bg.ToArgb() -eq $WhiteColor.ToArgb() -or $bg.ToArgb() -eq $YellowColor.ToArgb()
 Panel $x $y $w $h $bg $hasGlow
 Ink $s ($x+$padX) ($y+$padY) $size $fg $weight
 return [pscustomobject]@{Width=$w;Height=$h}
}
function CompactRow($a,$b,$x,$y,$size,$colorA,$colorB,$boxB=$false,$maxW=1220,$center=$false,$gap=15){
 $ba=MeasureInk $a $size 'SemiBold';$bb=MeasureInk $b $size 'Bold';$pad=if($boxB){28}else{0};$total=$ba.Width+$gap+$bb.Width+$pad
 if($total -gt $maxW){$size*=($maxW-$gap-$pad)/($ba.Width+$bb.Width);$ba=MeasureInk $a $size 'SemiBold';$bb=MeasureInk $b $size 'Bold';$total=$ba.Width+$gap+$bb.Width+$pad}
 if($center){$x+=( $maxW-$total)/2}
 $h=[math]::Max($ba.Height,$bb.Height)+20
 Ink $a $x ($y+($h-$ba.Height)/2) $size $colorA 'SemiBold' 9999 ($colorA.ToArgb() -ne $BlackColor.ToArgb())
 $bx=$x+$ba.Width+$gap
 if($boxB){Panel $bx $y ($bb.Width+28) $h $WhiteColor $true;Ink $b ($bx+14) ($y+($h-$bb.Height)/2) $size $BlackColor 'Bold'}else{Ink $b $bx ($y+($h-$bb.Height)/2) $size $colorB 'Bold' 9999 ($colorB.ToArgb() -ne $BlackColor.ToArgb())}
}
function Photo($name,$x=0,$y=0,$w=1280,$h=720){$im=[System.Drawing.Image]::FromFile((Join-Path $assets $name));$g.DrawImage($im,[single]$x,[single]$y,[single]$w,[single]$h);$im.Dispose()}
function PortraitHead($name,$cx,$top,$headHeight,$srcCX,$srcTop,$srcHeadHeight){$im=[System.Drawing.Image]::FromFile((Join-Path $assets $name));$scale=$headHeight/$srcHeadHeight;$g.DrawImage($im,[single]($cx-$srcCX*$scale),[single]($top-$srcTop*$scale),[single]($im.Width*$scale),[single]($im.Height*$scale));$im.Dispose()}
function Still($name,$x,$y,$w,$h){$im=[System.Drawing.Image]::FromFile((Join-Path $src $name));$ratio=[math]::Min($w/$im.Width,$h/$im.Height);$dw=$im.Width*$ratio;$dh=$im.Height*$ratio;Rect $x $y $w $h $BlackColor;$g.DrawImage($im,[single]($x+($w-$dw)/2),[single]($y+($h-$dh)/2),[single]$dw,[single]$dh);$im.Dispose()}
function Stroke($points,$color,$width=3,$dash=$false){$p=New-Object System.Drawing.Pen($color,[single]$width);$p.LineJoin='Round';$p.StartCap='Round';$p.EndCap='Round';if($dash){$p.DashPattern=[single[]]@(3,2)};$pts=@();for($q=0;$q -lt $points.Count;$q+=2){$pts+=New-Object System.Drawing.PointF([single]$points[$q],[single]$points[$q+1])};$g.DrawLines($p,[System.Drawing.PointF[]]$pts);$p.Dispose()}
function LightStroke($points,$color,$width=3){
 for($radius=16;$radius -ge 1;$radius--){$alpha=[int][math]::Round(4*[math]::Exp(-$radius*$radius/65.0));if($alpha -gt 0){Stroke $points (C $alpha $color.R $color.G $color.B) ($width+2*$radius)}}
 Stroke $points $color $width
}
function HeaderArrow(){
 # A single filled contour: the shaft never protrudes beyond the pointed head.
 $p=New-Object System.Drawing.Drawing2D.GraphicsPath
 $pts=[System.Drawing.PointF[]]@((New-Object System.Drawing.PointF(438,51)),(New-Object System.Drawing.PointF(659,51)),(New-Object System.Drawing.PointF(659,37)),(New-Object System.Drawing.PointF(703,59)),(New-Object System.Drawing.PointF(659,81)),(New-Object System.Drawing.PointF(659,67)),(New-Object System.Drawing.PointF(438,67)))
 $p.AddLines($pts);$p.AddArc(430,51,16,16,90,180);$p.CloseFigure();$g.FillPath([System.Drawing.Brushes]::White,$p);$p.Dispose()
}
function Arrow($x1,$y1,$c1x,$c1y,$c2x,$c2y,$x2,$y2,$color,$width=6,$dash=$false){
 $p=New-Object System.Drawing.Pen($color,[single]$width);$p.StartCap='Round';$p.LineJoin='Round';$p.EndCap='Round';if($dash){$p.DashPattern=[single[]]@(3,2)}
 $g.DrawBezier($p,[single]$x1,[single]$y1,[single]$c1x,[single]$c1y,[single]$c2x,[single]$c2y,[single]$x2,[single]$y2);$p.Dispose()
 $dx=$x2-$c2x;$dy=$y2-$c2y;$len=[math]::Sqrt($dx*$dx+$dy*$dy);$ux=$dx/$len;$uy=$dy/$len;$head=[math]::Max(11,$width*3);$half=$head*.48
 $pts=[System.Drawing.PointF[]]@((New-Object System.Drawing.PointF([single]$x2,[single]$y2)),(New-Object System.Drawing.PointF([single]($x2-$ux*$head-$uy*$half),[single]($y2-$uy*$head+$ux*$half))),(New-Object System.Drawing.PointF([single]($x2-$ux*$head+$uy*$half),[single]($y2-$uy*$head-$ux*$half))))
 $br=New-Object System.Drawing.SolidBrush($color);$g.FillPolygon($br,$pts);$br.Dispose()
}
function Youtube($x,$y,$w){
 $h=$w*.68;for($sp=8;$sp -ge 1;$sp--){Rounded ($x-$sp) ($y+5-$sp) ($w+2*$sp) ($h+2*$sp) (C 5 0 0 0) (22+$sp)}
 # Slightly bowed edges follow the supplied YouTube treatment.
 $p=New-Object System.Drawing.Drawing2D.GraphicsPath
 $p.AddBezier([single]($x+22),[single]$y,[single]($x+$w*.33),[single]($y-4),[single]($x+$w*.67),[single]($y-4),[single]($x+$w-22),[single]$y)
 $p.AddBezier([single]($x+$w-22),[single]$y,[single]($x+$w+2),[single]$y,[single]($x+$w+2),[single]($y+$h),[single]($x+$w-22),[single]($y+$h))
 $p.AddBezier([single]($x+$w-22),[single]($y+$h),[single]($x+$w*.67),[single]($y+$h+4),[single]($x+$w*.33),[single]($y+$h+4),[single]($x+22),[single]($y+$h))
 $p.AddBezier([single]($x+22),[single]($y+$h),[single]($x-2),[single]($y+$h),[single]($x-2),[single]$y,[single]($x+22),[single]$y);$p.CloseFigure()
 $br=New-Object System.Drawing.SolidBrush($RedColor);$g.FillPath($br,$p);$br.Dispose();$pen=New-Object System.Drawing.Pen((C 125 255 255 255),1.2);$g.DrawPath($pen,$p);$pen.Dispose();$p.Dispose()
 $tri=[System.Drawing.PointF[]]@((New-Object System.Drawing.PointF([single]($x+$w*.40),[single]($y+$h*.25))),(New-Object System.Drawing.PointF([single]($x+$w*.40),[single]($y+$h*.75))),(New-Object System.Drawing.PointF([single]($x+$w*.68),[single]($y+$h*.5))))
 $g.FillPolygon([System.Drawing.Brushes]::White,$tri)
}
function Pixelate($x,$y,$w,$h){for($yy=$y;$yy -lt $y+$h;$yy+=18){for($xx=$x;$xx -lt $x+$w;$xx+=18){$cc=$canvas.GetPixel([int](($xx+9)*3),[int](($yy+9)*3));Rect $xx $yy ([math]::Min(18,$x+$w-$xx)) ([math]::Min(18,$y+$h-$yy)) $cc}}}
function DiagramBackdrop(){
 Photo 'background_simple.png'
}
function Dot($x,$y,$r,$color){$br=New-Object System.Drawing.SolidBrush($color);$g.FillEllipse($br,[single]($x-$r),[single]($y-$r),[single]($r*2),[single]($r*2));$br.Dispose()}
function AuctionDiagram(){
 $cyan=C 255 37 215 255;$sell=C 255 255 80 90;$buy=C 255 21 239 92
 Rect 56 394 690 61 (C 230 22 73 103)
 LightStroke @(56,312,747,312) $sell 5
 LightStroke @(56,424,747,424) $cyan 5
 LightStroke @(56,539,747,539) $buy 5
 LightStroke @(65,499,140,319,220,531,300,319,380,531,460,319,540,524) $WhiteColor 8
 foreach($xx in @(140,300,460)){Dot $xx 319 8 $sell}
 foreach($xx in @(220,380,540)){Dot $xx 531 8 $buy}
 Ink 'SELLERS' 563 263 34 $sell 'SemiBold' 180
 Panel 543 396 215 54 (C 255 12 115 154) $false 8
 Fit 'FAIR VALUE' 554 407 193 32 34 $WhiteColor 'SemiBold'
 Ink 'BUYERS' 574 555 34 $buy 'SemiBold' 170
}
function RegimeDiagram(){
 $cyan=C 255 37 215 255;$sell=C 255 255 80 90;$buy=C 255 21 239 92
 Ink 'AMT' 57 248 44 $WhiteColor 'SemiBold'
 Arrow 170 266 185 266 207 266 224 266 $YellowColor 5
 $null=Badge 'B/I' 243 237 43 $WhiteColor $BlackColor 'SemiBold' 15 11
 Arrow 336 266 354 266 375 266 394 266 $YellowColor 5
 Ink 'OPPORTUNITY' 413 251 35 $YellowColor 'SemiBold' 340
 Ink 'BALANCE' 58 326 33 $WhiteColor 'Medium'
 Ink 'IMBALANCE' 437 326 33 $WhiteColor 'Medium' 315
 Rect 57 391 300 162 (C 225 16 52 79)
 LightStroke @(57,391,357,391) $cyan 4
 LightStroke @(57,553,357,553) $cyan 4
 LightStroke @(68,533,120,407,173,533,223,406,253,450) $WhiteColor 8
 LightStroke @(253,450,292,367,309,417) $sell 8
 Arrow 309 417 315 443 323 466 330 489 $sell 8
 LightStroke @(283,346,300,329) $sell 5;LightStroke @(283,329,300,346) $sell 5
 Rect 479 501 57 28 (C 170 10 83 41);Rect 551 451 63 30 (C 170 10 83 41);Rect 624 407 60 31 (C 170 10 83 41)
 LightStroke @(435,552,490,506,517,525,563,456,589,478,636,410,663,436,719,373) $buy 8
}
function PriceValueDiagram(){
 $cyan=C 255 37 215 255
 Rect 430 301 430 118 (C 225 18 76 102)
 LightStroke @(430,301,860,301) (C 255 28 169 213) 4
 LightStroke @(430,419,860,419) (C 255 28 169 213) 4
 LightStroke @(430,361,860,361) $cyan 5
 LightStroke @(453,391,505,316,557,397,608,324,647,361,695,206,740,254,799,175) $WhiteColor 9
 Dot 799 175 9 $WhiteColor
 Ink 'PRICE' 706 124 36 $WhiteColor 'SemiBold'
 Panel 534 427 220 51 (C 255 12 115 154) $false 9
 Fit 'FAIR VALUE' 545 437 198 31 35 $WhiteColor 'SemiBold'
}
function PhotoExtendedTop($name,$offset){
 # Extend the plate's top edge into the canvas margin. The scene stays at its approved position.
 $im=[System.Drawing.Image]::FromFile((Join-Path $assets $name))
 for($xx=0;$xx -lt 1280;$xx++){$sx=[math]::Min($im.Width-1,[int]($xx*$im.Width/1280));$cc=$im.GetPixel($sx,0);Rect $xx 0 1 ($offset+1) $cc}
 $g.DrawImage($im,[single]0,[single]$offset,[single]1280,[single]720);$im.Dispose()
}
function Image06(){
 Gradient 0 0 1280 720 (C 255 248 250 253) (C 255 220 227 237)
 Rounded 21 148 1238 504 (C 255 251 253 255) 10
 # Highlight lies behind the measured MARKET word only.
 $left=MeasureInk 'READ THE' 102 'SemiBold';$right=MeasureInk 'MARKET' 102 'Bold';$total=$left.Width+17+$right.Width
 Rect (40+(1200-$total)/2+$left.Width+9) 15 ($right.Width+18) 95 $YellowColor
 CompactRow 'READ THE' 'MARKET' 40 20 102 $BlackColor $BlackColor $false 1200 $true 17
 $navy=C 255 10 29 43;$teal=C 255 0 130 188;$rose=C 255 237 23 60;$emerald=C 255 0 170 87;$gold=C 255 226 168 0
 foreach($card in @(@(42,166,368,228),@(870,166,368,228),@(42,411,368,231),@(870,411,368,231))){Panel $card[0] $card[1] $card[2] $card[3] (C 255 255 255 255) $false 12}
 Ink 'BALANCE' 61 185 35 $navy 'SemiBold'
 Rect 71 245 298 82 (C 28 19 128 164)
 Stroke @(71,245,369,245) $rose 3;Stroke @(71,327,369,327) $emerald 3
 Stroke @(76,313,112,252,152,319,194,252,235,319,276,232) $navy 5
 Arrow 276 232 285 259 306 292 323 313 $rose 5
 Stroke @(272,214,285,225) $rose 3;Stroke @(272,225,285,214) $rose 3
 Panel 65 346 322 34 $rose $false 6;Fit 'FALSE BREAKOUT' 76 352 300 22 29 $WhiteColor 'SemiBold'
 Ink 'IMBALANCE' 889 185 35 $navy 'SemiBold' 329
 Rect 921 303 57 27 (C 40 0 149 78);Rect 1004 272 55 25 (C 40 0 149 78);Rect 1082 240 54 27 (C 40 0 149 78)
 Stroke @(898,329,938,306,969,321,1018,276,1047,291,1096,245,1125,262) $emerald 5
 Arrow 1125 262 1140 248 1158 234 1180 216 $emerald 5
 Panel 893 346 322 34 $emerald $false 6;Fit 'VALUE SHIFTS UP' 904 352 300 22 29 $WhiteColor 'SemiBold'
 Ink 'FAIR VALUE' 61 430 34 $navy 'SemiBold'
 $bars=@(101,137,181,239,191,145,104)
 for($b=0;$b -lt $bars.Count;$b++){Rect 76 (480+$b*13) $bars[$b] 9 (C 255 38 143 180)}
 Rect 76 519 239 11 $gold
 Arrow 379 480 375 499 350 514 328 524 $gold 5
 Panel 65 592 322 34 $navy $false 6;Fit 'MOST VOLUME' 76 598 300 22 29 $WhiteColor 'SemiBold'
 Ink 'MICRO-RANGE' 889 430 32 $navy 'SemiBold' 329
 Rect 944 503 145 47 (C 35 19 128 164)
 Stroke @(944,503,1089,503) $teal 3;Stroke @(944,550,1089,550) $teal 3
 Stroke @(894,564,944,515,972,541,1001,515,1029,541,1057,515,1081,536) $navy 5
 Arrow 1081 536 1103 515 1129 489 1159 469 $emerald 5
 Dot 1081 536 7 $emerald
 Panel 893 592 322 34 $teal $false 6;Fit 'BUILD THEN BREAK' 904 598 300 22 28 $WhiteColor 'SemiBold'
 PortraitHead 'Imre_direct_camera.png' 640 138 505 572 85 780
}
. (Join-Path $PSScriptRoot 'finish_v12.ps1')
$slugs=@('Price_Is_Not_Value','Why_Breakouts_Fail','What_Really_Drives_Price','Stop_Chasing_Price','Master_Auction_Market_Theory','Read_The_Market','Smart_Money_Myths','Price_To_Value')
foreach($i in 1..7){
 $script:id='{0:00}' -f $i
 $script:canvas=New-Object System.Drawing.Bitmap(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $script:g=[System.Drawing.Graphics]::FromImage($canvas);$g.Clear((C 255 20 21 22));$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
 switch($i){
  1 {
   DiagramBackdrop;AuctionDiagram
   PortraitHead 'Imre_direct_camera.png' 1030 28 545 572 85 780
   Ink 'PRICE IS NOT' 28 24 99 $WhiteColor 'SemiBold' 740 $true
   $null=Badge 'VALUE' 28 117 117 $WhiteColor $BlackColor 'Bold' 14 11
   $null=Badge 'Auction Market Theory' 245 641 47 $YellowColor $BlackColor 'Medium' 17 11 690
   Arrow 754 628 798 559 792 484 755 450 $YellowColor 7
  }
  2 {
   DiagramBackdrop;RegimeDiagram
   PortraitHead 'Imre_direct_camera.png' 1030 28 545 572 85 780
   CompactRow 'WHY' 'BREAKOUTS' 28 20 90 $WhiteColor $BlackColor $true 740 $false 13
   Ink 'FAIL' 28 128 113 $WhiteColor 'SemiBold' 720 $true
   $null=Badge 'Read the Market Regime' 245 641 44 $YellowColor $BlackColor 'Medium' 17 11 690
   Arrow 754 628 791 555 791 479 739 434 $YellowColor 7
  }
  3 {
   PhotoExtendedTop '03_plate.png' 30
   CompactRow 'WHAT' 'REALLY' 30 12 105 $WhiteColor $BlackColor $true 1220 $true 14
   Panel 479 159 327 159 $YellowColor $true 11
   Fit 'DRIVES' 493 173 299 57 78 $BlackColor 'Bold';Fit 'PRICE' 493 239 299 63 84 $BlackColor 'Bold'
   Panel 755 482 469 65 $GreenColor $false 9;Fit '2 MARKET STATES' 769 493 441 43 44 $WhiteColor 'SemiBold' $true
   Arrow 644 334 595 414 593 542 637 615 $YellowColor 8;Arrow 837 468 816 419 849 388 879 377 $YellowColor 7
  }
  4 {
   DiagramBackdrop;PriceValueDiagram
   PortraitHead 'Imre_direct_camera.png' 240 20 542 572 85 780
   PortraitHead 'Riz_original_cutout.png' 1030 18 540 700 10 790
   $null=Badge 'PRICE vs VALUE' 459 26 39 $YellowColor $BlackColor 'SemiBold' 15 10 364
   Arrow 616 90 614 133 635 167 670 189 $YellowColor 7
   Gradient 0 370 1280 350 (C 0 0 0 0) (C 255 0 0 0)
   Fit 'STOP CHASING' 251 521 778 70 94 $WhiteColor 'SemiBold' $true
   $bb=MeasureInk 'PRICE' 107 'Bold';$null=Badge 'PRICE' ((1280-$bb.Width-34)/2) 608 107 $WhiteColor $BlackColor 'Bold' 17 12
  }
  5 {
   Photo '05_plate.png'
   CompactRow 'MASTER' 'AUCTION' 28 15 123 $WhiteColor $YellowColor $false 1224 $false 17
   Fit 'MARKET THEORY' 849 133 398 62 60 $WhiteColor 'Bold' $true;Stroke @(851,204,1238,204) $YellowColor 4
   Panel 47 230 282 113 (C 230 16 16 16) $false 12
   Fit '2 MARKET' 62 245 252 37 43 $WhiteColor 'SemiBold' $true;Fit 'STATES' 62 293 252 34 43 $WhiteColor 'SemiBold' $true
   Arrow 304 354 302 397 350 414 399 400 $YellowColor 7
   Panel 919 433 320 57 (C 225 20 20 20) $false 27;Fit 'IMRE GAMS' 933 445 292 32 37 $WhiteColor 'Medium' $true
   Panel 441 508 477 77 (C 247 15 15 15) $false 13;Fit 'STEP BY STEP' 457 520 445 49 55 $WhiteColor 'Bold' $true
   Arrow 616 601 604 623 564 640 529 643 $YellowColor 7
  }
  6 {Image06}
  7 {
   Photo '07_plate.png'
   $null=Badge 'SMART MONEY MYTHS' 325 28 57 $RedColor $WhiteColor 'SemiBold' 17 13 716
   Fit 'EXPLAINED' 428 116 516 66 66 $WhiteColor 'Regular' $true
   $null=Badge 'RIZ' 31 96 29 (C 255 10 61 90) $WhiteColor 'SemiBold' 15 10;$null=Badge 'IMRE' 1129 89 29 (C 255 10 61 90) $WhiteColor 'SemiBold' 15 10
   Arrow 74 151 65 186 96 211 138 213 $WhiteColor 3.5;Arrow 1173 144 1189 176 1171 205 1136 219 $WhiteColor 3.5
   Youtube 525 270 188
  }
 }
 $g.Dispose();$name=$id+'_'+$slugs[$i-1]
 $canvas.Save((Join-Path $assets ($name+'_master.png')),[System.Drawing.Imaging.ImageFormat]::Png)
 $canvas.Save((Join-Path $exports ($name+'_3840x2160.png')),[System.Drawing.Imaging.ImageFormat]::Png)
 foreach($size in @(1280,640,320)){$small=New-Object System.Drawing.Bitmap($size,[int]($size*9/16));$sg=[System.Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$small.Width,$small.Height);$sg.Dispose();$small.Save((Join-Path $preview ($id+'_'+$size+'.jpg')),$jpeg,$quality);$small.Dispose()}
 $canvas.Dispose();Write-Output ('Rendered '+$id)
}
$metrics.ToArray() | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Typography_geometry.csv')
foreach($tw in @(640,320)){
 $th=[int]($tw*9/16);$sheet=New-Object System.Drawing.Bitmap(($tw*2),(($th+26)*4));$sg=[System.Drawing.Graphics]::FromImage($sheet);$sg.Clear((C 255 20 20 20));$sg.InterpolationMode='HighQualityBicubic';$font=New-Object System.Drawing.Font('Arial',12,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
 for($j=0;$j -lt 8;$j++){$label='{0:00}' -f ($j+1);$im=[System.Drawing.Image]::FromFile((Join-Path $preview ($label+'_1280.jpg')));$x=($j%2)*$tw;$y=[int][math]::Floor($j/2)*($th+26);$sg.DrawImage($im,$x,$y,$tw,$th);$sg.DrawString(('IMRE GAMS / '+$label),$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+$th+6));$im.Dispose()};$sg.Dispose();$font.Dispose();$sheet.Save((Join-Path $preview ('Planche_V12_'+$tw+'.jpg')),$jpeg,$quality);$sheet.Dispose()
}












$arrows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Arrow_geometry.csv')
foreach($im in $photoCache.Values){$im.Dispose()}

$quality.Dispose()

