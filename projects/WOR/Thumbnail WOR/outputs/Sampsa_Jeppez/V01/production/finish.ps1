$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class PhotoFinish {
 public static void AlphaMask(Bitmap image, Bitmap mask, int radius) {
  var rect=new Rectangle(0,0,image.Width,image.Height);
  var md=mask.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  var id=image.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var mb=new byte[md.Stride*image.Height];var ib=new byte[id.Stride*image.Height];
  Marshal.Copy(md.Scan0,mb,0,mb.Length);Marshal.Copy(id.Scan0,ib,0,ib.Length);
  int w=image.Width,h=image.Height;var a=new float[w*h];var b=new float[w*h];
  for(int y=0;y<h;y++)for(int x=0;x<w;x++)a[y*w+x]=mb[y*md.Stride+x*4];
  for(int pass=0;pass<3;pass++) {
   for(int y=0;y<h;y++){float sum=0;for(int dx=-radius;dx<=radius;dx++)sum+=a[y*w+Math.Max(0,Math.Min(w-1,dx))];
    for(int x=0;x<w;x++){b[y*w+x]=sum/(2*radius+1);sum+=a[y*w+Math.Min(w-1,x+radius+1)]-a[y*w+Math.Max(0,x-radius)];}}
   for(int x=0;x<w;x++){float sum=0;for(int dy=-radius;dy<=radius;dy++)sum+=b[Math.Max(0,Math.Min(h-1,dy))*w+x];
    for(int y=0;y<h;y++){a[y*w+x]=sum/(2*radius+1);sum+=b[Math.Min(h-1,y+radius+1)*w+x]-b[Math.Max(0,y-radius)*w+x];}}
  }
  for(int y=0;y<h;y++)for(int x=0;x<w;x++)ib[y*id.Stride+x*4+3]=(byte)Math.Max(0,Math.Min(255,a[y*w+x]));
  Marshal.Copy(ib,0,id.Scan0,ib.Length);image.UnlockBits(id);mask.UnlockBits(md);
 }
 public static void Grain(Bitmap image,double amount,int seed) {
  var rect=new Rectangle(0,0,image.Width,image.Height);var d=image.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var bytes=new byte[d.Stride*image.Height];Marshal.Copy(d.Scan0,bytes,0,bytes.Length);var rng=new Random(seed);
  for(int y=0;y<image.Height;y++)for(int x=0;x<image.Width;x++){double n=(rng.NextDouble()*2-1)*255*amount;int i=y*d.Stride+x*4;for(int k=0;k<3;k++)bytes[i+k]=(byte)Math.Max(0,Math.Min(255,Math.Round(bytes[i+k]+n)));}
  Marshal.Copy(bytes,0,d.Scan0,bytes.Length);image.UnlockBits(d);
 }
}
'@ -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices')

$base=[Drawing.Bitmap]::new((Join-Path $root 'masters\Sampsa_Jeppez_V01_base_generated.png'))
$g=[Drawing.Graphics]::FromImage($base)
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
function Restore-PhotoFace($file,$coords,$matrix,$name){
 $source=[Drawing.Bitmap]::new((Join-Path $root $file))
 $cut=[Drawing.Bitmap]::new($source.Width,$source.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $cg=[Drawing.Graphics]::FromImage($cut);$cg.DrawImageUnscaled($source,0,0);$cg.Dispose()
 $mask=[Drawing.Bitmap]::new($source.Width,$source.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $mg=[Drawing.Graphics]::FromImage($mask);$mg.Clear([Drawing.Color]::Black);$mg.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
 $pts=[Drawing.PointF[]]@(for($i=0;$i -lt $coords.Count;$i+=2){[Drawing.PointF]::new($coords[$i],$coords[$i+1])})
 $path=[Drawing.Drawing2D.GraphicsPath]::new();$path.AddClosedCurve($pts,0.18);$mg.FillPath([Drawing.Brushes]::White,$path);$mg.Dispose()
 [PhotoFinish]::AlphaMask($cut,$mask,7)
 $cut.Save((Join-Path $root ('masters\'+$name+'_original_face_layer.png')),[Drawing.Imaging.ImageFormat]::Png)
 $g.Transform=[Drawing.Drawing2D.Matrix]::new($matrix[0],$matrix[1],$matrix[2],$matrix[3],$matrix[4],$matrix[5])
 $g.DrawImage($cut,0,0,$source.Width,$source.Height);$g.ResetTransform()
 $path.Dispose();$mask.Dispose();$cut.Dispose();$source.Dispose()
}
# Affine alignment of the original camera face pixels. Only mask edges are feathered;
# no face smoothing, sharpening, invented texture or local colour processing.
Restore-PhotoFace 'sources_HD\Sampsa\Sampsa_00-04-25.jpg' @(870,239,950,211,1045,188,1150,185,1228,226,1251,307,1255,391,1267,475,1255,571,1213,683,1133,730,1031,744,956,709,902,642,869,555,854,450,856,351) @(.68755,-.0125,.00319,.6773,586.91,2.75) 'Sampsa'
Restore-PhotoFace 'sources_HD\Riz\Riz_00-03-00.jpg' @(704,175,780,148,866,127,904,143,920,188,930,257,929,322,911,377,877,415,825,425,766,397,721,369,694,323,691,252) @(.9457,-.05,.025,.958,-454.47,44.444) 'Riz'
$g.Dispose()
$base.Save((Join-Path $root 'masters\Sampsa_Jeppez_V01_base_photo.png'),[Drawing.Imaging.ImageFormat]::Png)

$w=3840;$h=2160
$out=[Drawing.Bitmap]::new($w,$h,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[Drawing.Graphics]::FromImage($out);$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality;$g.DrawImage($base,0,0,$w,$h);$base.Dispose()
$g.TextRenderingHint=[Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$fonts=[Drawing.Text.PrivateFontCollection]::new()
$fonts.AddFontFile('C:\Users\notti\AppData\Local\Microsoft\Windows\Fonts\Poppins-Bold.ttf')
$family=$fonts.Families[0]
$font=[Drawing.Font]::new($family,390,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Pixel)
$small=[Drawing.Font]::new($family,150,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Pixel)
$fmt=[Drawing.StringFormat]::GenericTypographic.Clone()
$titleA='$12K';$titleB='TO';$titleC='$5M'
$a=$g.MeasureString($titleA,$font,10000,$fmt).Width
$b=$g.MeasureString($titleB,$small,10000,$fmt).Width
$c=$g.MeasureString($titleC,$font,10000,$fmt).Width
$gap=70;$pad=65;$total=$a+$b+$c+2*$gap+2*$pad
$x=($w-$total)/2;$y=1560
$red=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(237,10,22))
$g.FillRectangle($red,($x+$a+$gap+$b+$gap),($y+18),($c+2*$pad),490)
$g.DrawString($titleA,$font,[Drawing.Brushes]::White,$x,$y,$fmt)
$g.DrawString($titleB,$small,[Drawing.Brushes]::White,($x+$a+$gap),($y+195),$fmt)
$g.DrawString($titleC,$font,[Drawing.Brushes]::White,($x+$a+$gap+$b+$gap+$pad),$y,$fmt)
$g.Dispose();$font.Dispose();$small.Dispose();$red.Dispose();$fonts.Dispose();$fmt.Dispose()
$out.Save((Join-Path $root 'masters\Sampsa_Jeppez_V01_typography_no_grain_3840x2160.png'),[Drawing.Imaging.ImageFormat]::Png)
[PhotoFinish]::Grain($out,0.04,20261012)
$out.Save((Join-Path $root 'exports_4K\Sampsa_Jeppez_V01_12K_to_5M_Grain4_3840x2160.png'),[Drawing.Imaging.ImageFormat]::Png)
foreach($width in @(1280,320)){
 $height=[int]($width*9/16);$preview=[Drawing.Bitmap]::new($width,$height);$pg=[Drawing.Graphics]::FromImage($preview);$pg.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$pg.DrawImage($out,0,0,$width,$height)
 $preview.Save((Join-Path $root ('apercus\Sampsa_Jeppez_V01_'+$width+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$pg.Dispose();$preview.Dispose()
}
$out.Dispose()
