# Editable chart layers. Screen-space OHLC values illustrate the episode's concepts;
# these are not historical prices, signals, results or trade recommendations.
$candleRecords=[System.Collections.Generic.List[object]]::new()
$bull=C 255 0 214 167
$bear=C 255 255 79 86
function ChartLine($x1,$y1,$x2,$y2,$color,$width=1.5,$dash=$false){
 $pen=[System.Drawing.Pen]::new($color,[single]$width)
 $pen.StartCap='Flat';$pen.EndCap='Flat'
 if($dash){$pen.DashPattern=[single[]]@(5,5)}
 $g.DrawLine($pen,[single]$x1,[single]$y1,[single]$x2,[single]$y2);$pen.Dispose()
}
function ChartGrid($x,$y,$w,$h){
 for($xx=$x;$xx -le ($x+$w);$xx+=32){ChartLine $xx $y $xx ($y+$h) (C 13 185 200 210) 0.75}
 for($yy=$y;$yy -le ($y+$h);$yy+=32){ChartLine $x $yy ($x+$w) $yy (C 13 185 200 210) 0.75}
}
function Candle($x,$cOpen,$cClose,$highY,$lowY,$width=15){
 $up=$cClose -lt $cOpen;$color=if($up){C 255 24 239 24}else{C 255 255 8 16}
 ChartLine $x $highY $x $lowY $color 1.8
 $top=[math]::Min($cOpen,$cClose);$bodyH=[math]::Max(3.0,[math]::Abs($cClose-$cOpen))
 $left=$x-$width/2
 $topColor=if($up){C 255 48 255 48}else{C 255 255 34 38}
 $brush=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($left,$top),[System.Drawing.PointF]::new($left,($top+$bodyH)),$topColor,$color)
 $g.FillRectangle($brush,[single]$left,[single]$top,[single]$width,[single]$bodyH);$brush.Dispose()
 ChartLine $left $top ($left+$width) $top (C 135 255 255 255) 1
 $candleRecords.Add([pscustomobject]@{Image=$script:id;X=$x;OpenY=$cOpen;CloseY=$cClose;HighY=$highY;LowY=$lowY;BodyWidth=$width;Illustrative=$true})
}
function CandleRun($start,$step,$rows,$width=15){
 for($n=0;$n -lt $rows.Count;$n++){Candle ($start+$n*$step) $rows[$n][0] $rows[$n][1] $rows[$n][2] $rows[$n][3] $width}
}
function FocusRing($x,$y,$radius=26){
 $pen=[System.Drawing.Pen]::new($YellowColor,4.5)
 $g.DrawEllipse($pen,[single]($x-$radius),[single]($y-$radius),[single]($radius*2),[single]($radius*2));$pen.Dispose()
}
function AuctionDiagram(){
 $saved=$g.CompositingQuality;$g.CompositingQuality='AssumeLinear'
 ChartGrid 54 298 690 256
 # Quiet auction range, thin boundaries and a narrow central value area.
 Rect 56 312 690 227 (C 12 166 187 199)
 Rect 56 408 690 35 (C 30 13 156 163)
 ChartLine 56 312 746 312 (C 185 231 235 238) 1.6
 ChartLine 56 539 746 539 (C 185 231 235 238) 1.6
 ChartLine 56 425 539 425 (C 150 232 240 245) 1.5 $true
 $rows=@(
  @(460,425,409,472),@(425,386,373,438),@(386,335,315,397),@(335,363,323,379),
  @(363,420,351,434),@(420,480,408,498),@(480,510,464,541),@(510,472,461,528),
  @(472,426,413,487),@(426,371,356,440),@(371,335,315,385),@(335,364,324,380),
  @(364,411,350,426),@(411,477,400,490),@(477,509,466,539),@(509,464,450,526),
  @(464,410,397,480),@(410,364,349,424),@(364,333,314,378),@(333,382,322,395),
  @(382,420,371,434),@(420,453,409,466)
 )
 CandleRun 78 22 $rows 14
 FocusRing 474 332 25
 FocusRing 386 522 24
 Arrow 592 302 561 295 535 300 506 322 $WhiteColor 4.5
 Arrow 565 563 500 574 459 569 417 542 $WhiteColor 4.5
 Ink 'SELLERS' 563 263 34 $bear 'SemiBold' 180
 Ink 'FAIR VALUE' 563 413 30 $WhiteColor 'SemiBold' 194
 Ink 'BUYERS' 574 555 34 $bull 'SemiBold' 170
 $g.CompositingQuality=$saved
}
function RegimeDiagram(){
 $saved=$g.CompositingQuality
 Ink 'AMT' 57 248 44 $WhiteColor 'SemiBold'
 Arrow 170 266 185 266 207 266 224 266 $YellowColor 5
 $null=Badge 'B/I' 243 237 43 $WhiteColor $BlackColor 'SemiBold' 15 11
 Arrow 336 266 354 266 375 266 394 266 $YellowColor 5
 Ink 'OPPORTUNITY' 413 251 35 $YellowColor 'SemiBold' 340
 Ink 'BALANCE' 58 326 33 $WhiteColor 'Medium'
 Ink 'IMBALANCE' 437 326 33 $WhiteColor 'Medium' 315
 $g.CompositingQuality='AssumeLinear'
 ChartGrid 54 367 690 216
 # The left sequence breaks above balance, then closes back inside the range.
 Rect 57 407 317 142 (C 17 148 171 187)
 ChartLine 57 407 374 407 (C 200 237 242 246) 1.7
 ChartLine 57 549 374 549 (C 160 237 242 246) 1.7
 ChartLine 57 479 374 479 (C 74 237 242 246) 1.0 $true
 $balanced=@(
  @(519,477,459,532),@(477,427,412,489),@(427,448,417,465),
  @(448,503,436,518),@(503,529,491,549),@(529,481,469,541),
  @(481,429,417,494),@(429,373,357,442),@(373,436,364,450),
  @(436,481,424,495),@(481,513,471,529)
 )
 CandleRun 75 27 $balanced 17
 FocusRing 277 385 37
 Arrow 364 358 352 344 329 345 311 359 $WhiteColor 4.5
 # On the right, acceptance shifts upward through successive value areas.
 Rect 435 539 86 28 (C 24 0 205 163)
 Rect 512 490 103 27 (C 24 0 205 163)
 Rect 598 431 116 27 (C 24 0 205 163)
 ChartLine 435 539 521 539 (C 86 186 225 216) 1.2
 ChartLine 512 490 615 490 (C 86 186 225 216) 1.2
 ChartLine 598 431 714 431 (C 86 186 225 216) 1.2
 $imbalanced=@(
  @(557,528,513,572),@(528,542,517,553),@(542,497,483,550),
  @(497,471,458,507),@(471,488,463,502),@(488,445,432,497),
  @(445,412,398,456),@(412,428,403,443),@(428,393,381,438),
  @(393,366,355,405),@(366,382,359,397)
 )
 CandleRun 439 26 $imbalanced 17
 $g.CompositingQuality=$saved
}



