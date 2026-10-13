param([switch]$NoReferenceRiz)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
. (Join-Path $PSScriptRoot 'soft_glow.ps1')
$root=Split-Path (Split-Path $PSScriptRoot)
$assets=Join-Path $root 'Masters\V11_Test08'
$exports=Join-Path $root 'Exports\V11_Test08'
$previews=Join-Path $root 'Apercus\V11_Test08'
$canvas=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($canvas)
$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';$g.CompositingQuality='HighQuality'
$white=[System.Drawing.Color]::White
$red=[System.Drawing.Color]::FromArgb(255,0,14)
$metrics=[System.Collections.Generic.List[object]]::new()
function Col($a,$r,$green,$b){[System.Drawing.Color]::FromArgb([int]$a,[int]$r,[int]$green,[int]$b)}
function RoundPath($x,$y,$w,$h,$r){
 $p=[System.Drawing.Drawing2D.GraphicsPath]::new();$d=2*$r
 $p.AddArc([single]$x,[single]$y,[single]$d,[single]$d,180,90);$p.AddArc([single]($x+$w-$d),[single]$y,[single]$d,[single]$d,270,90)
 $p.AddArc([single]($x+$w-$d),[single]($y+$h-$d),[single]$d,[single]$d,0,90);$p.AddArc([single]$x,[single]($y+$h-$d),[single]$d,[single]$d,90,90);$p.CloseFigure();return $p
}
function FillPath($path,$color){$brush=[System.Drawing.SolidBrush]::new($color);$g.FillPath($brush,$path);$brush.Dispose()}
function SoftGlow($path,$color,$sigma,$opacity){
 $bounds=$path.GetBounds();$pad=[int][math]::Ceiling(3*$sigma)+2
 $x=[int][math]::Floor($bounds.X)-$pad;$y=[int][math]::Floor($bounds.Y)-$pad
 $w=[int][math]::Ceiling($bounds.Width)+2*$pad;$h=[int][math]::Ceiling($bounds.Height)+2*$pad
 $mask=[System.Drawing.Bitmap]::new($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $mg=[System.Drawing.Graphics]::FromImage($mask);$mg.SmoothingMode='AntiAlias';$mg.TranslateTransform(-$x,-$y);$mg.FillPath([System.Drawing.Brushes]::White,$path);$mg.Dispose()
 $halo=[CFSoftGlow]::Blur($mask,$sigma,$color,$opacity)
 $g.DrawImage($halo,[single]$x,[single]$y,[single]$w,[single]$h)
 $halo.Dispose();$mask.Dispose()
}
function Glyph($text,$size,$weight='SemiBold'){
 $family=if($weight -eq 'Bold'){'Poppins'}else{'Poppins '+$weight};$style=if($weight -eq 'Bold'){1}else{0}
 $ff=[System.Drawing.FontFamily]::new($family);$p=[System.Drawing.Drawing2D.GraphicsPath]::new()
 $p.AddString($text,$ff,$style,[single]$size,[System.Drawing.PointF]::new(0,0),[System.Drawing.StringFormat]::GenericTypographic);$ff.Dispose();return $p
}
function MeasureInk($text,$size,$weight='SemiBold'){$p=Glyph $text $size $weight;$b=$p.GetBounds();$p.Dispose();return $b}
function Ink($text,$x,$y,$size,$color,$weight='SemiBold',$luminous=$false){
 $p=Glyph $text $size $weight;$b=$p.GetBounds();$m=[System.Drawing.Drawing2D.Matrix]::new();$m.Translate([single]($x-$b.X),[single]($y-$b.Y));$p.Transform($m);$m.Dispose()
 if($luminous){SoftGlow $p $white 5 0.23}
 FillPath $p $color
 $metrics.Add([pscustomobject]@{Text=$text;X=$x;Y=$y;Width=$b.Width;Height=$b.Height;Font=$size})
 $p.Dispose()
}
function ReferenceRiz(){
 # Actual pixels from the supplied reference, mirrored to the right chair.
 $im=[System.Drawing.Bitmap]::FromFile((Join-Path $assets 'Reference_composition_Riz.jpg'))
 $im.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
 $outline=@(0,529,27,482,42,438,43,403,46,382,52,362,63,350,87,346,178,345,217,322,209,308,196,291,190,273,191,257,184,241,179,221,177,201,182,183,195,167,218,152,242,141,269,130,285,130,313,139,335,155,348,178,352,195,357,214,358,232,365,250,369,269,369,287,366,310,368,318,397,326,431,335,466,347,490,361,508,382,522,411,535,436,549,465,558,493,570,521,577,548,580,581,578,612,565,619,0,628)
 $points=[System.Collections.Generic.List[System.Drawing.PointF]]::new()
 for($j=0;$j -lt $outline.Count;$j+=2){$points.Add([System.Drawing.PointF]::new([single](1280-$outline[$j]),[single]$outline[$j+1]))}
 $path=[System.Drawing.Drawing2D.GraphicsPath]::new();$path.AddPolygon($points.ToArray());$state=$g.Save();$g.SetClip($path);$g.DrawImage($im,0,0,1280,720);$g.Restore($state)
 $path.Dispose();$im.Dispose()
}
function PixelateImre(){
 # Follow the turned face rather than a rectangular frontal patch.
 $path=[System.Drawing.Drawing2D.GraphicsPath]::new()
 $path.AddPolygon([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(184,179),[System.Drawing.PointF]::new(305,181),[System.Drawing.PointF]::new(334,205),[System.Drawing.PointF]::new(346,275),[System.Drawing.PointF]::new(354,306),[System.Drawing.PointF]::new(335,352),[System.Drawing.PointF]::new(300,379),[System.Drawing.PointF]::new(249,383),[System.Drawing.PointF]::new(204,350),[System.Drawing.PointF]::new(179,290)))
 $matrix=[System.Drawing.Drawing2D.Matrix]::new();$matrix.Scale(1.0,[single](740.0/720.0));$path.Transform($matrix);$matrix.Dispose()
 $state=$g.Save();$g.SetClip($path)
 for($yy=173;$yy -lt 414;$yy+=17){for($xx=172;$xx -lt 365;$xx+=17){
  $color=$canvas.GetPixel([int](($xx+8)*3),[int](($yy+8)*3));$brush=[System.Drawing.SolidBrush]::new($color);$g.FillRectangle($brush,[single]$xx,[single]$yy,[single]17,[single]17);$brush.Dispose()
 }}
 $g.Restore($state);$path.Dispose()
}
function DashConnector($x1,$y1,$c1x,$c1y,$c2x,$c2y,$x2,$y2){
 # Flat caps; the line terminates before the separate sharp triangular head.
 $dx=$x2-$c2x;$dy=$y2-$c2y;$length=[math]::Sqrt($dx*$dx+$dy*$dy);$ux=$dx/$length;$uy=$dy/$length
 $baseX=$x2-10*$ux;$baseY=$y2-10*$uy
 $pen=[System.Drawing.Pen]::new((Col 240 255 255 255),2.5);$pen.StartCap='Flat';$pen.EndCap='Flat';$pen.DashCap='Flat';$pen.DashPattern=[single[]]@(3,2.4)
 $g.DrawBezier($pen,[single]$x1,[single]$y1,[single]$c1x,[single]$c1y,[single]($c2x-8*$ux),[single]($c2y-8*$uy),[single]$baseX,[single]$baseY);$pen.Dispose()
 $p=[System.Drawing.Drawing2D.GraphicsPath]::new();$p.AddPolygon([System.Drawing.PointF[]]@([System.Drawing.PointF]::new($x2,$y2),[System.Drawing.PointF]::new(($baseX-4.5*$uy),($baseY+4.5*$ux)),[System.Drawing.PointF]::new(($baseX+4.5*$uy),($baseY-4.5*$ux))));FillPath $p $white;$p.Dispose()
}
function BlueBox($lines,$x,$y,$w,$h,$font){
 $path=RoundPath $x $y $w $h 10
 SoftGlow $path (Col 255 0 147 244) 8 0.20
 $brush=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),(Col 255 15 73 107),(Col 255 8 39 60))
 $g.FillPath($brush,$path);$brush.Dispose()
 $pen=[System.Drawing.Pen]::new((Col 190 42 163 224),1.1);$g.DrawPath($pen,$path);$pen.Dispose();$path.Dispose()
 $heights=@();$total=0;foreach($line in $lines){$b=MeasureInk $line $font 'Bold';$heights+=$b;$total+=$b.Height};$total+=5*($lines.Count-1)
 $ty=$y+($h-$total)/2
 for($l=0;$l -lt $lines.Count;$l++){Ink $lines[$l] ($x+($w-$heights[$l].Width)/2) $ty $font $white 'Bold';$ty+=$heights[$l].Height+5}
}
function Title(){
 $size=108;$price=MeasureInk 'PRICE' $size 'SemiBold';$value=MeasureInk 'VALUE' $size 'Bold'
 $boxW=$value.Width+40;$boxH=$value.Height+26;$arrowW=173;$gap=58;$total=$price.Width+$boxW+$arrowW+2*$gap
 $start=(1280-$total)/2;$cy=69;$arrowX=$start+$price.Width+$gap;$boxX=$arrowX+$arrowW+$gap;$boxY=$cy-$boxH/2
 Ink 'PRICE' $start ($cy-$price.Height/2) $size $white 'SemiBold' $true
 $arrow=[System.Drawing.Drawing2D.GraphicsPath]::new();$tip=$arrowX+$arrowW;$neck=$tip-38
 $arrow.AddPolygon([System.Drawing.PointF[]]@([System.Drawing.PointF]::new($arrowX,($cy-10)),[System.Drawing.PointF]::new($neck,($cy-10)),[System.Drawing.PointF]::new($neck,($cy-28)),[System.Drawing.PointF]::new($tip,$cy),[System.Drawing.PointF]::new($neck,($cy+28)),[System.Drawing.PointF]::new($neck,($cy+10)),[System.Drawing.PointF]::new($arrowX,($cy+10))))
 SoftGlow $arrow $white 6 0.2;FillPath $arrow $white;$arrow.Dispose()
 $panel=RoundPath $boxX $boxY $boxW $boxH 15
 SoftGlow $panel $red 25 0.64;SoftGlow $panel $red 8 0.76
 $brush=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($boxX,$boxY),[System.Drawing.PointF]::new($boxX,($boxY+$boxH)),(Col 255 255 8 20),(Col 255 238 0 9))
 $g.FillPath($brush,$panel);$brush.Dispose();$panel.Dispose()
 Ink 'VALUE' ($boxX+20) ($cy-$value.Height/2) $size $white 'Bold'
 [pscustomobject]@{PriceEnd=$start+$price.Width;ArrowStart=$arrowX;ArrowEnd=$tip;ValueStart=$boxX;GapLeft=$gap;GapRight=$gap;CenterY=$cy;TotalWidth=$total} | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Title_alignment.csv')
}
function Youtube(){
 $x=565;$y=365;$w=151;$h=100;$p=RoundPath $x $y $w $h 23
 SoftGlow $p $red 28 0.64;SoftGlow $p $red 9 0.68
 $brush=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new($x,$y),[System.Drawing.PointF]::new($x,($y+$h)),(Col 255 255 5 21),(Col 255 242 0 12));$g.FillPath($brush,$p);$brush.Dispose();$p.Dispose()
 $tri=[System.Drawing.Drawing2D.GraphicsPath]::new();$tri.AddPolygon([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(624,390),[System.Drawing.PointF]::new(624,440),[System.Drawing.PointF]::new(668,415)));FillPath $tri $white;$tri.Dispose()
}
$plate=[System.Drawing.Image]::FromFile((Join-Path $assets '08_plate.png'));$g.DrawImage($plate,0,0,1280,740);$plate.Dispose()
$clean=[System.Drawing.Image]::FromFile((Join-Path $assets '08_clean_right.png'));$state=$g.Save();$g.SetClip([System.Drawing.RectangleF]::new(690,0,590,720));$g.DrawImage($clean,0,0,1280,740);$g.Restore($state);$clean.Dispose()
if(-not $NoReferenceRiz){ReferenceRiz}
PixelateImre
# Connectors pass behind both heads; the sharp tips stay clear of the boxes.
$state=$g.Save();$heads=[System.Drawing.Drawing2D.GraphicsPath]::new();$heads.AddEllipse(133,124,230,291);$heads.AddEllipse(896,125,226,280);$g.SetClip($heads,[System.Drawing.Drawing2D.CombineMode]::Exclude)
DashConnector 152 209 230 142 315 143 394 188
DashConnector 561 226 595 250 638 277 679 277
DashConnector 866 257 934 127 1023 127 1116 197
$g.Restore($state);$heads.Dispose()
BlueBox @('BALANCE') 12 190 151 61 27
BlueBox @('REGIME') 394 173 174 63 32
BlueBox @('MACRO','RANGE') 678 236 200 82 34
BlueBox @('CLOSE','THE GAP') 1117 181 150 78 29
Title
Youtube
$g.Dispose()
$name='08_Price_To_Value_V11_Test_Sans_Grain_3840x2160.png'
$canvas.Save((Join-Path $exports $name),[System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Save((Join-Path $assets '08_Price_To_Value_master.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$jpeg=[System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$quality=[System.Drawing.Imaging.EncoderParameters]::new(1);$quality.Param[0]=[System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality,[long]95)
foreach($width in @(1280,640,320)){
 $small=[System.Drawing.Bitmap]::new($width,([int]($width*9/16)));$sg=[System.Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$small.Width,$small.Height);$sg.Dispose();$small.Save((Join-Path $previews ('08_'+$width+'.jpg')),$jpeg,$quality);$small.Dispose()
}
$quality.Dispose();$canvas.Dispose()
$metrics | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Typography_geometry.csv')
Write-Output 'Rendered thumbnail 08 only; no grain pass; diffuse Gaussian glows and sharp arrows.'

