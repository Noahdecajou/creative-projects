param([string]$Scene='09_scene_expression.png')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot)
$assets=Join-Path $root 'Masters\V10_Expression';$out=Join-Path $root 'Exports_4K\V10_Expression';$preview=Join-Path $root 'Apercus\V10_Expression'
$script:id='09';$metrics=[System.Collections.Generic.List[object]]::new()
. (Join-Path $PSScriptRoot 'drawing_functions.ps1')
$plate=[System.Drawing.Image]::FromFile((Join-Path $assets $Scene));$nativeWidth=$plate.Width;$nativeHeight=$plate.Height
$canvas=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($canvas);$g.ScaleTransform(3,3);$g.InterpolationMode='HighQualityBicubic';$g.SmoothingMode='AntiAlias';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
$g.DrawImage($plate,[single]0,[single]0,[single]1280,[single]720);$plate.Dispose()
$left='Trading in';$right='3 decisions.';$size=99;$gap=24
$a=MeasureInk $left $size 'Bold';$b=MeasureInk $right $size 'Bold';$limit=1160
if(($a.Width+$b.Width+$gap) -gt $limit){$size*=($limit-$gap)/($a.Width+$b.Width);$a=MeasureInk $left $size 'Bold';$b=MeasureInk $right $size 'Bold'}
$x=(1280-$a.Width-$b.Width-$gap)/2;$y=463;$baseline=$y-$a.Y
$p1=Glyph $left $size 'Bold';$p2=Glyph $right $size 'Bold'
$m=[System.Drawing.Drawing2D.Matrix]::new(1,0,0,1,[single]($x-$a.X),[single]$baseline);$p1.Transform($m);$m.Dispose()
$m=[System.Drawing.Drawing2D.Matrix]::new(1,0,0,1,[single]($x+$a.Width+$gap-$b.X),[single]$baseline);$p2.Transform($m);$m.Dispose()
# Soft offset shadow only: no text stroke and no glow.
foreach($p in @($p1,$p2)){
 $state=$g.Save();$g.TranslateTransform(1,4)
 foreach($sw in @(14,10,6,3)){$pen=[System.Drawing.Pen]::new((C 15 0 0 0),[single]$sw);$pen.LineJoin='Round';$g.DrawPath($pen,$p);$pen.Dispose()}
 $shadow=[System.Drawing.SolidBrush]::new((C 125 0 0 0));$g.FillPath($shadow,$p);$shadow.Dispose();$g.Restore($state)
}
$g.FillPath([System.Drawing.Brushes]::White,$p1)
$yb=$p2.GetBounds();$yellow=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new(0,$yb.Top),[System.Drawing.PointF]::new(0,$yb.Bottom),(C 255 255 248 91),(C 255 255 228 0));$g.FillPath($yellow,$p2);$yellow.Dispose()
$p1.Dispose();$p2.Dispose();$g.Dispose()
# The user's latest request explicitly removes grain. No noise or sharpening is applied.
$canvas.Save((Join-Path $assets '09_Trading_In_3_Decisions_Expression_master.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Save((Join-Path $out '09_Trading_In_3_Decisions_Expression_3840x2160.png'),[System.Drawing.Imaging.ImageFormat]::Png)
foreach($sizeOut in @(1280,640,320)){
 $s=[System.Drawing.Bitmap]::new($sizeOut,[int]($sizeOut*9/16));$sg=[System.Drawing.Graphics]::FromImage($s);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$s.Width,$s.Height);$sg.Dispose();$s.Save((Join-Path $preview ('09_'+$sizeOut+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$s.Dispose()
}
$canvas.Dispose()
[pscustomobject]@{Text='Trading in 3 decisions.';WhiteText=$left;YellowText=$right;Font='Poppins Bold';FontSize=$size;X=$x;Top=$y;TotalWidth=($a.Width+$b.Width+$gap);YellowTop='#FFF85B';YellowBottom='#FFE400';Shadow='Soft black, 1px right and 4px down at 1280';NoBox=$true;NoGlow=$true;NoStroke=$true;AddedGrain=$false;Sharpening=$false;Canvas='3840x2160';PhotoPlateWidth=$nativeWidth;PhotoPlateHeight=$nativeHeight;Enlarged=($nativeWidth -lt 3840)}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Typography_manifest.json') -Encoding utf8


