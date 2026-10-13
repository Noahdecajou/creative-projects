# Chart illustrations only; user references supply style, never trades or performance claims.
$ChartGreen=C 255 30 232 31
$ChartRed=C 255 255 61 69
function ScreenBase {
 Gradient 0 0 609 363 (C 255 15 18 19) (C 255 8 11 12)
 for($xx=18;$xx -lt 609;$xx+=29){Stroke @($xx,0,$xx,363) (C 40 73 83 86) .55}
 for($yy=18;$yy -lt 363;$yy+=29){Stroke @(0,$yy,609,$yy) (C 40 73 83 86) .55}
}
function ChartRing($x,$y,$radius,$color,$width=3){$pen=[System.Drawing.Pen]::new($color,[single]$width);$g.DrawEllipse($pen,[single]($x-$radius),[single]($y-$radius),[single]($radius*2),[single]($radius*2));$pen.Dispose()}
function DrawScreen01 {
 ScreenBase
 ChartSpot 297 187 129 127 $ChartGreen 36
 ChartSpot 495 51 89 109 $ChartGreen 24
 Rect 270 226 166 55 (C 64 4 198 108)
 Stroke @(270,226,435,226) (C 114 60 213 141) 1.1
 Stroke @(271,281,435,281) (C 70 60 213 141) 1
 Stroke @(27,132,261,132) (C 80 228 238 237) 1.1 $true
 Stroke @(27,218,261,218) (C 80 228 238 237) 1.1 $true
 Stroke @(395,159,573,159) (C 145 237 245 242) 1.5
 $path=@(31,218,86,137,142,211,196,142,253,229,307,179,361,257,422,155,466,186)
 Stroke $path (C 255 240 245 243) 4
 Arrow 466 186 492 149 522 107 549 70 (C 255 240 245 243) 4
 ChartRing 361 257 24 $YellowColor 3
 ChartRing 487 156 16 $ChartGreen 3
 Ink '1' 28 29 29 $YellowColor 'Bold';Ink 'CONDITION' 55 32 26 $WhiteColor 'SemiBold'
 Ink '2' 291 316 29 $YellowColor 'Bold';Ink 'ZONES' 320 319 26 $WhiteColor 'SemiBold'
 Ink '3' 411 29 29 $YellowColor 'Bold';Ink 'TRIGGER' 440 32 26 $WhiteColor 'SemiBold'
 Arrow 350 307 350 298 355 292 359 287 $WhiteColor 2
}
function DrawScreen02 {
 ScreenBase
 Ink 'VOLUME PROFILE' 23 21 33 $WhiteColor 'SemiBold'
 # Translucent value area and sparse price levels keep the large candles readable.
 Rect 24 122 526 150 (C 23 8 159 67)
 ChartSpot 276 225 101 91 $ChartGreen 33
 ChartSpot 474 62 91 110 $ChartGreen 24
 foreach($v in @(@('VAH',124),@('POC',184),@('VAL',271))){$col=if($v[0] -eq 'POC'){C 125 255 226 0}else{C 100 228 237 235};Stroke @(24,$v[1],549,$v[1]) $col $(if($v[0] -eq 'POC'){1.1}else{1.0}) $true;Ink $v[0] 557 ($v[1]-8) 17 $(if($v[0] -eq 'POC'){$YellowColor}else{$WhiteColor}) 'SemiBold'}
 # Bid/ask-like profile colours are a graphic illustration, not platform data.
 $bars=@(17,30,47,64,86,111,137,122,109,91,74,51,32,19)
 for($k=0;$k -lt $bars.Count;$k++){
  $yy=95+$k*14;$fraction=.44+.18*[math]::Sin($k*.7);$buy=$bars[$k]*$fraction
  Rect 25 $yy $buy 10 (C 230 26 190 36);Rect (25+$buy) $yy ($bars[$k]-$buy) 10 (C 225 221 53 61)
 }
 $closes=@(173,187,200,185,196,219,232,222,246,259,275,261,251,232,221,233,213,201,181,190,174,159,163,142,129,140,119,102,115,90)
 for($k=0;$k -lt $closes.Count;$k++){
  $xx=185+$k*12;$close=$closes[$k];$open=if($k -eq 0){160}else{$closes[$k-1]}
  $up=$close -lt $open;$col=if($up){$ChartGreen}else{$ChartRed};$top=[math]::Min($open,$close);$bottom=[math]::Max($open,$close);$body=[math]::Max(5,$bottom-$top)
  Stroke @($xx,($top-5-($k%4)*2),$xx,($bottom+6+(($k+2)%4)*2)) (C 210 $col.R $col.G $col.B) 1.1
  Rect ($xx-17.0/3) $top (34.0/3) $body $col
  Stroke @(($xx-5.1),($top+.55),($xx+5.1),($top+.55)) (C 155 230 255 247) .75
 }
 ChartRing 311 267 22 $YellowColor 2.8
 Arrow 367 322 350 323 334 311 322 292 $WhiteColor 2.3
 Ink 'BUYERS' 386 313 30 $ChartGreen 'Bold'
}
