$ErrorActionPreference='Stop'
$p=Join-Path $PSScriptRoot 'render_v04.ps1'
$content=Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'V03\render_v03.ps1') -Raw
$content=$content.Replace('V03','V04').Replace('V3Grain','V4Grain')
$electric=@'
function ElectricPanel($x,$y,$w,$h,$radius=10){
 for($n=30;$n -ge 1;$n--){$a=[int][math]::Round(6*[math]::Exp(-$n*$n/245));if($a -gt 0){Rounded ($x-$n) ($y-$n) ($w+2*$n) ($h+2*$n) (C $a 0 153 255) ($radius+$n)}}
 $p=RoundPath $x $y $w $h $radius
 $brush=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),(C 255 7 125 255),(C 255 0 68 238))
 $g.FillPath($brush,$p);$brush.Dispose()
 $pen=[System.Drawing.Pen]::new((C 235 112 228 255),1.35);$g.DrawPath($pen,$p);$pen.Dispose();$p.Dispose()
}
'@
$content=$content.Replace('function Glow {}',('function Glow {}'+[Environment]::NewLine+$electric))
$start=$content.IndexOf('function LightBoard {')
$end=$content.IndexOf('$cs=@', $start)
$newboard=@'
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
 Photo 'chart_trend.png' 69 391 291 70
 Stage '3' 'TRIGGER' 65 491 322
 Photo 'chart_trigger.png' 67 537 305 69
 Ink '2-MIN STRUCTURE BREAK' 67 624 20 $Blue 'Medium'
 Stage '2' 'ZONES' 905 173 308
 Ink 'VOLUME AT PRICE' 908 227 23 $Blue 'SemiBold'
 Photo 'chart_profile.png' 902 259 307 188
 foreach($item in @(@('VAH',280),@('POC',346),@('VAL',411))){Ink $item[0] 1170 ($item[1]-9) 22 $Blue 'SemiBold'}
 Ink 'VALUE AREA' 908 463 24 $Blue 'SemiBold'
 Photo 'chart_accept.png' 908 500 300 104
 Ink 'ACCEPT / REJECT' 986 624 21 $Blue 'Medium'
 Person 'Casper_front_photo.png' 638 160 359
 ElectricPanel 414 625 453 63 9;Fit 'CONDITION / ZONES / TRIGGER' 427 642 427 29 27 $WhiteColor 'Medium'
}
'@
$content=$content.Substring(0,$start)+$newboard+[Environment]::NewLine+$content.Substring($end)
$content=$content.Replace('Panel 20 198 184 52 $Blue $false 10','ElectricPanel 20 198 184 52 10').Replace('Panel 441 249 170 55 $Blue $false 10','ElectricPanel 441 249 170 55 10').Replace('Panel 682 172 184 53 $Blue $false 10','ElectricPanel 682 172 184 53 10')
Set-Content -LiteralPath $p -Value $content -Encoding utf8
