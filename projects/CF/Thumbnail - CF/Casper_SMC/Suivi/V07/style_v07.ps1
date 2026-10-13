# V07: borderless text boxes, colour-matched glow, clean arrowheads.
function Glow($x,$y,$w,$h,$color,$radius=11){
 for($n=26;$n -ge 1;$n--){$a=[int][math]::Round(5*[math]::Exp(-$n*$n/175));if($a -gt 0){Rounded ($x-$n) ($y-$n) ($w+2*$n) ($h+2*$n) (C $a $color.R $color.G $color.B) ($radius+$n)}}
}
function Panel($x,$y,$w,$h,$color,$glow=$true,$radius=11){
 Glow $x $y $w $h $color $radius
 $top=$color;$bottom=$color
 if($color.ToArgb() -eq $WhiteColor.ToArgb()){$bottom=C 255 235 235 235}
 elseif($color.ToArgb() -eq $YellowColor.ToArgb()){$top=C 255 255 239 65}
 elseif($color.ToArgb() -eq $RedColor.ToArgb()){$bottom=C 255 223 0 0}
 $p=RoundPath $x $y $w $h $radius
 $br=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),$top,$bottom)
 $g.FillPath($br,$p);$br.Dispose();$p.Dispose()
}
function ElectricPanel($x,$y,$w,$h,$radius=10){
 for($n=30;$n -ge 1;$n--){$a=[int][math]::Round(6*[math]::Exp(-$n*$n/245));if($a -gt 0){Rounded ($x-$n) ($y-$n) ($w+2*$n) ($h+2*$n) (C $a 0 153 255) ($radius+$n)}}
 $p=RoundPath $x $y $w $h $radius
 $br=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),(C 255 7 125 255),(C 255 0 68 238))
 $g.FillPath($br,$p);$br.Dispose();$p.Dispose()
}
function Arrow($x1,$y1,$c1x,$c1y,$c2x,$c2y,$x2,$y2,$color,$width=6,$dash=$false){
 $dx=$x2-$c2x;$dy=$y2-$c2y;$len=[math]::Sqrt($dx*$dx+$dy*$dy);$ux=$dx/$len;$uy=$dy/$len
 $head=[math]::Max(12,$width*3.5);$half=$head*.43
 $points=[System.Collections.Generic.List[System.Drawing.PointF]]::new()
 for($k=0;$k -le 160;$k++){$t=$k/160.0;$u=1-$t;$xx=$u*$u*$u*$x1+3*$u*$u*$t*$c1x+3*$u*$t*$t*$c2x+$t*$t*$t*$x2;$yy=$u*$u*$u*$y1+3*$u*$u*$t*$c1y+3*$u*$t*$t*$c2y+$t*$t*$t*$y2;if([math]::Sqrt(($xx-$x2)*($xx-$x2)+($yy-$y2)*($yy-$y2)) -lt $head*.7){break};$points.Add([System.Drawing.PointF]::new($xx,$yy))}
 $p=[System.Drawing.Pen]::new($color,[single]$width);$p.StartCap='Round';$p.EndCap='Flat';$p.LineJoin='Round';if($dash){$p.DashPattern=[single[]]@(3,2)}
 if($points.Count -gt 1){$g.DrawLines($p,$points.ToArray())};$p.Dispose()
 $pts=[System.Drawing.PointF[]]@([System.Drawing.PointF]::new($x2,$y2),[System.Drawing.PointF]::new(($x2-$ux*$head-$uy*$half),($y2-$uy*$head+$ux*$half)),[System.Drawing.PointF]::new(($x2-$ux*$head+$uy*$half),($y2-$uy*$head-$ux*$half)))
 $br=[System.Drawing.SolidBrush]::new($color);$g.FillPolygon($br,$pts);$br.Dispose()
}
function Youtube($x,$y,$w){
 $h=$w*.68;Glow $x $y $w $h $RedColor 22
 $p=[System.Drawing.Drawing2D.GraphicsPath]::new()
 $p.AddBezier([single]($x+22),[single]$y,[single]($x+$w*.33),[single]($y-4),[single]($x+$w*.67),[single]($y-4),[single]($x+$w-22),[single]$y)
 $p.AddBezier([single]($x+$w-22),[single]$y,[single]($x+$w+2),[single]$y,[single]($x+$w+2),[single]($y+$h),[single]($x+$w-22),[single]($y+$h))
 $p.AddBezier([single]($x+$w-22),[single]($y+$h),[single]($x+$w*.67),[single]($y+$h+4),[single]($x+$w*.33),[single]($y+$h+4),[single]($x+22),[single]($y+$h))
 $p.AddBezier([single]($x+22),[single]($y+$h),[single]($x-2),[single]($y+$h),[single]($x-2),[single]$y,[single]($x+22),[single]$y);$p.CloseFigure()
 $br=[System.Drawing.SolidBrush]::new($RedColor);$g.FillPath($br,$p);$br.Dispose();$p.Dispose()
 $tri=[System.Drawing.PointF[]]@([System.Drawing.PointF]::new(($x+$w*.40),($y+$h*.25)),[System.Drawing.PointF]::new(($x+$w*.40),($y+$h*.75)),[System.Drawing.PointF]::new(($x+$w*.68),($y+$h*.5)))
 $g.FillPolygon([System.Drawing.Brushes]::White,$tri)
}
function InkYellowGradient($s,$x,$y,$size,$weight='SemiBold'){
 $p=Glyph $s $size $weight;$bb=$p.GetBounds();$m=[System.Drawing.Drawing2D.Matrix]::new(1,0,0,1,[single]($x-$bb.X),[single]($y-$bb.Y));$p.Transform($m);$m.Dispose()
 for($sw=32;$sw -ge 2;$sw-=2){$alpha=[int][math]::Round(2.2*[math]::Exp(-$sw*$sw/560));if($alpha -gt 0){$pen=[System.Drawing.Pen]::new((C $alpha 255 224 0),[single]$sw);$pen.LineJoin='Round';$g.DrawPath($pen,$p);$pen.Dispose()}}
 $br=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$bb.Height)),(C 255 255 249 148),$YellowColor);$g.FillPath($br,$p);$br.Dispose();$p.Dispose()
 $metrics.Add([pscustomobject]@{Image=$script:id;Text=$s;X=$x;Y=$y;Width=[math]::Round($bb.Width,2);Height=[math]::Round($bb.Height,2);Font=$size;Weight=$weight})
}
function Headline05 {
 $size=85;$gap=29;$a=MeasureInk 'MASTER' $size;$b=MeasureInk 'VOLUME' $size;$c=MeasureInk 'PROFILE' $size
 if(($a.Width+$b.Width+$c.Width+2*$gap) -gt 1192){$size*=(1192-2*$gap)/($a.Width+$b.Width+$c.Width);$a=MeasureInk 'MASTER' $size;$b=MeasureInk 'VOLUME' $size;$c=MeasureInk 'PROFILE' $size}
 $x=(1280-$a.Width-$b.Width-$c.Width-2*$gap)/2;$y=28
 Ink 'MASTER' $x $y $size $WhiteColor 'SemiBold' 9999 $true
 InkYellowGradient 'VOLUME' ($x+$a.Width+$gap) $y $size
 Ink 'PROFILE' ($x+$a.Width+$gap+$b.Width+$gap) $y $size $WhiteColor 'SemiBold' 9999 $true
}
function CenterBadge($text,$y,$size,$bg,$fg,$weight='Bold',$max=1150){
 $bb=MeasureInk $text $size $weight;if($bb.Width+36 -gt $max){$size*=($max-36)/$bb.Width;$bb=MeasureInk $text $size $weight}
 $null=Badge $text ((1280-$bb.Width-36)/2) $y $size $bg $fg $weight 18 13 $max
}
function Header08{
 $s1=91;$s2=81;$a=MeasureInk 'PRICE' $s1;$b=MeasureInk 'ORDER FLOW' $s2
 $gap=25;$arrow=145;$boxW=$b.Width+38;$total=$a.Width+$gap+$arrow+$gap+$boxW;$x=(1280-$total)/2;$h=$b.Height+28;$y=23
 Ink 'PRICE' $x ($y+($h-$a.Height)/2) $s1 $WhiteColor 'SemiBold' 9999 $true
 $ax=$x+$a.Width+$gap;$ay=$y+$h/2
 Arrow $ax $ay ($ax+$arrow/3) $ay ($ax+2*$arrow/3) $ay ($ax+$arrow) $ay $WhiteColor 9
 $null=Badge 'ORDER FLOW' ($ax+$arrow+$gap) $y $s2 $RedColor $WhiteColor 'SemiBold' 19 14
}
function BehindCasperArrow08{
 $head=[System.Drawing.Drawing2D.GraphicsPath]::new()
 $head.AddPolygon([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(201,193),[System.Drawing.PointF]::new(199,163),[System.Drawing.PointF]::new(209,126),[System.Drawing.PointF]::new(228,102),[System.Drawing.PointF]::new(257,93),[System.Drawing.PointF]::new(308,96),[System.Drawing.PointF]::new(346,115),[System.Drawing.PointF]::new(366,142),[System.Drawing.PointF]::new(369,183),[System.Drawing.PointF]::new(370,221),[System.Drawing.PointF]::new(355,251),[System.Drawing.PointF]::new(347,285),[System.Drawing.PointF]::new(330,321),[System.Drawing.PointF]::new(294,336),[System.Drawing.PointF]::new(262,331),[System.Drawing.PointF]::new(231,305),[System.Drawing.PointF]::new(216,257)))
 $state=$g.Save();$g.SetClip($head,[System.Drawing.Drawing2D.CombineMode]::Exclude)
 Arrow 196 207 280 128 371 174 448 250 $WhiteColor 3 $true
 $g.Restore($state);$head.Dispose()
}
function ScreenBase{
 Gradient 0 0 609 363 (C 255 13 23 30) (C 255 4 11 16)
 Rect 0 0 609 29 (C 255 31 42 48)
 foreach($d in @(@(15,231,84,70),@(32,236,187,61),@(49,70,186,100))){$br=[System.Drawing.SolidBrush]::new((C 255 $d[1] $d[2] $d[3]));$g.FillEllipse($br,[single]$d[0],10,8,8);$br.Dispose()}
}
function DrawScreen01{
 ScreenBase
 $mint=C 255 159 244 151
 Fit 'ICT / OB / FVG / STRUCTURE' 17 43 575 25 29 $mint 'SemiBold'
 Stroke @(19,80,590,80) (C 255 66 89 83) 1
 $labels=@('CONDITION','ZONES','TRIGGER')
 for($n=0;$n -lt 3;$n++){$yy=99+$n*74;Rounded 20 $yy 321 61 (C 255 22 48 40) 7;Fit ([string]($n+1)) 31 ($yy+10) 36 40 45 $mint 'Bold';Ink $labels[$n] 88 ($yy+17) 37 $WhiteColor 'SemiBold' 240}
 Stroke @(355,99,355,309) (C 255 51 75 70) 1.2
 Ink 'LET YOUR' 379 105 26 $mint 'Medium'
 Ink 'WINNERS' 379 143 38 $mint 'Bold' 211
 Ink 'RUN' 379 190 39 $mint 'Bold'
 Ink 'CUT YOUR' 379 247 25 $WhiteColor 'Medium'
 Ink 'LOSSES FAST' 379 283 27 $WhiteColor 'SemiBold' 215
 Ink 'TP' 552 329 23 (C 255 125 142 149) 'SemiBold';Stroke @(549,331,584,351) (C 255 237 80 79) 3
}
function DrawScreen02{
 ScreenBase
 Ink 'VOLUME PROFILE' 21 43 33 $WhiteColor 'SemiBold'
 Ink 'WHERE OTHER TRADERS ARE POSITIONED' 21 91 22 $YellowColor 'Medium' 566
 Rect 22 166 534 94 (C 36 1 135 210)
 foreach($v in @(@('VAH',168),@('POC',214),@('VAL',258))){Stroke @(22,$v[1],553,$v[1]) (C 143 124 166 189) 1.3 $true;Ink $v[0] 557 ($v[1]-8) 18 $WhiteColor 'SemiBold'}
 $bars=@(24,42,67,98,123,151,141,112,77,48,27)
 for($k=0;$k -lt $bars.Count;$k++){Rect 24 (133+$k*15) $bars[$k] 11 $(if($k -eq 5){$YellowColor}else{C 255 26 172 226})}
 Ink 'AT PRICE' 27 312 22 (C 255 53 202 249) 'SemiBold'
 # 28 candle bodies, 30 px wide with 2 px between them in the actual 3840 export.
 $ys=@(250,245,235,239,242,232,224,215,220,211,205,219,225,216,209,199,190,196,204,194,184,175,181,171,164,169,159,150)
 $vh=@(10,13,17,12,14,18,21,26,19,23,28,16,12,19,24,29,31,22,16,21,26,34,25,29,38,24,31,35)
 for($k=0;$k -lt $ys.Count;$k++){$xx=233+$k*(32.0/3);$up=($k -eq 0 -or $ys[$k] -lt $ys[$k-1]);$col=if($up){C 255 49 211 165}else{C 255 234 87 91};Stroke @($xx,($ys[$k]-10),$xx,($ys[$k]+22)) $col 1.5;Rect ($xx-5) $ys[$k] 10 14 $col;Rect ($xx-5) (329-$vh[$k]) 10 $vh[$k] $col}
 Ink 'VOLUME AT TIME' 302 340 18 (C 255 169 190 201) 'Medium'
}
function RenderScreens{
 foreach($n in @(1,2)){
  $script:id='SCREEN_'+$n;$script:canvas=[System.Drawing.Bitmap]::new(1827,1089,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$script:g=[System.Drawing.Graphics]::FromImage($canvas);$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';$g.PixelOffsetMode='HighQuality'
  if($n -eq 1){DrawScreen01}else{DrawScreen02};$g.Dispose();$canvas.Save((Join-Path $assets ('screen_0'+$n+'.png')));$canvas.Dispose()
 }
}


