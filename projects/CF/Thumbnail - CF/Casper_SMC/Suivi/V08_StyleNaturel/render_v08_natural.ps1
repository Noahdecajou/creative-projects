param([string]$Scene='09_scene_photo_final.png')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V08_StyleNaturel';$out=Join-Path $root 'Exports_4K\V08_StyleNaturel';$preview=Join-Path $root 'Apercus\V08_StyleNaturel'
$script:id='09';$metrics=[System.Collections.Generic.List[object]]::new()
. (Join-Path $PSScriptRoot 'drawing_functions.ps1')
$WhiteColor=[System.Drawing.Color]::White;$YellowColor=[System.Drawing.Color]::FromArgb(255,239,0)
$canvas=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($canvas);$g.ScaleTransform(3,3);$g.InterpolationMode='HighQualityBicubic';$g.SmoothingMode='AntiAlias';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
Photo $Scene 0 0 1280 720
# A transparent shadow bed supports white copy over the beige polo, without a visible box.
$shade=[System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.PointF]::new(0,405),[System.Drawing.PointF]::new(0,600),(C 0 0 0 0),(C 0 0 0 0))
$blend=[System.Drawing.Drawing2D.ColorBlend]::new(5);$blend.Positions=[single[]]@(0,.30,.56,.75,1);$blend.Colors=[System.Drawing.Color[]]@((C 0 0 0 0),(C 40 0 0 0),(C 62 0 0 0),(C 39 0 0 0),(C 0 0 0 0));$shade.InterpolationColors=$blend;$g.FillRectangle($shade,0,405,1280,195);$shade.Dispose()
$left='Trading in';$right='3 decisions.';$size=99;$gap=24
$a=MeasureInk $left $size 'Bold';$b=MeasureInk $right $size 'Bold';$limit=1160
if(($a.Width+$b.Width+$gap) -gt $limit){$size*=($limit-$gap)/($a.Width+$b.Width);$a=MeasureInk $left $size 'Bold';$b=MeasureInk $right $size 'Bold'}
$x=(1280-$a.Width-$b.Width-$gap)/2;$y=463
# Align glyph paths to a common baseline; the descender of 'Trading' extends below it.
$baseline=$y-$a.Y
$p1=Glyph $left $size 'Bold';$p2=Glyph $right $size 'Bold'
$m1=[System.Drawing.Drawing2D.Matrix]::new(1,0,0,1,[single]($x-$a.X),[single]$baseline);$p1.Transform($m1);$m1.Dispose()
$m2=[System.Drawing.Drawing2D.Matrix]::new(1,0,0,1,[single]($x+$a.Width+$gap-$b.X),[single]$baseline);$p2.Transform($m2);$m2.Dispose()
foreach($p in @($p1,$p2)){$state=$g.Save();$g.TranslateTransform(0,3);foreach($width in @(12,8,4)){$pen=[System.Drawing.Pen]::new((C 12 0 0 0),[single]$width);$pen.LineJoin='Round';$g.DrawPath($pen,$p);$pen.Dispose()};$shadow=[System.Drawing.SolidBrush]::new((C 110 0 0 0));$g.FillPath($shadow,$p);$shadow.Dispose();$g.Restore($state)}
$g.FillPath([System.Drawing.Brushes]::White,$p1);$yellow=[System.Drawing.SolidBrush]::new($YellowColor);$g.FillPath($yellow,$p2);$yellow.Dispose();$p1.Dispose();$p2.Dispose();$g.Dispose()
$canvas.Save((Join-Path $assets '09_Trading_In_3_Decisions_Natural_master.png'))
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$code=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class GrainV8Natural{public static void Add(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);var r=new Random(20261024);for(int p=0;p<v.Length;p+=4){double n=(r.NextDouble()*2-1)*12.75;for(int c=0;c<3;c++)v[p+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(v[p+c]+n)));}Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
[GrainV8Natural]::Add($canvas);$canvas.Save((Join-Path $out '09_Trading_In_3_Decisions_Natural_3840x2160.png'))
foreach($sizeOut in @(1280,640,320)){$s=[System.Drawing.Bitmap]::new($sizeOut,[int]($sizeOut*9/16));$sg=[System.Drawing.Graphics]::FromImage($s);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($canvas,0,0,$s.Width,$s.Height);$sg.Dispose();$s.Save((Join-Path $preview ('09_'+$sizeOut+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$s.Dispose()};$canvas.Dispose()
[pscustomobject]@{Text='Trading in 3 decisions.';WhiteText=$left;YellowText=$right;Font='Poppins Bold';FontSize=$size;X=$x;Top=$y;TotalWidth=($a.Width+$b.Width+$gap);NoBox=$true;NoGlow=$true;Canvas='3840x2160';NativePhotoPlate='1672x941';Enlarged=$true}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Typography_manifest.json') -Encoding utf8
