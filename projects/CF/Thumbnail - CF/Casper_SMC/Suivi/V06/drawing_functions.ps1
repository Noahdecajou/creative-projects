function C($a,$r,$gg,$bb){return [System.Drawing.Color]::FromArgb([int]$a,[int]$r,[int]$gg,[int]$bb)}
function Rect($x,$y,$w,$h,$color){$br=New-Object System.Drawing.SolidBrush($color);$g.FillRectangle($br,[single]$x,[single]$y,[single]$w,[single]$h);$br.Dispose()}
function RoundPath($x,$y,$w,$h,$radius=12){$p=New-Object System.Drawing.Drawing2D.GraphicsPath;$d=$radius*2;$p.AddArc([single]$x,[single]$y,[single]$d,[single]$d,180,90);$p.AddArc([single]($x+$w-$d),[single]$y,[single]$d,[single]$d,270,90);$p.AddArc([single]($x+$w-$d),[single]($y+$h-$d),[single]$d,[single]$d,0,90);$p.AddArc([single]$x,[single]($y+$h-$d),[single]$d,[single]$d,90,90);$p.CloseFigure();return $p}
function Rounded($x,$y,$w,$h,$color,$r=12){$p=RoundPath $x $y $w $h $r;$br=New-Object System.Drawing.SolidBrush($color);$g.FillPath($br,$p);$p.Dispose();$br.Dispose()}
function Gradient($x,$y,$w,$h,$top,$bottom){$br=New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.PointF([single]$x,[single]$y)),(New-Object System.Drawing.PointF([single]$x,[single]($y+$h))),$top,$bottom);$g.FillRectangle($br,[single]$x,[single]$y,[single]$w,[single]$h);$br.Dispose()}
function Glow($x,$y,$w,$h,$color){for($n=16;$n -ge 1;$n--){$a=[int][math]::Round(3*[math]::Exp(-$n*$n/70));if($a -gt 0){Rounded ($x-$n) ($y-$n) ($w+2*$n) ($h+2*$n) (C $a $color.R $color.G $color.B) (12+$n)}}}
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

