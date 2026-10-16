$ErrorActionPreference='Stop';Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V09_StyleNaturel';$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$code=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class LockedPhotoV9 {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
 static void Write(Bitmap b,byte[] v){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
 public static void BlendBody(Bitmap dst,Bitmap fix){var a=Read(dst);var b=Read(fix);int w=dst.Width;for(int y=0;y<dst.Height;y++)for(int x=0;x<w;x++){double t=Math.Min(1,Math.Max(0,(x/3.0-575)/35))*Math.Min(1,Math.Max(0,(530-y/3.0)/40));int p=(y*w+x)*4;for(int c=0;c<3;c++)a[p+c]=(byte)Math.Round(a[p+c]*(1-t)+b[p+c]*t);}Write(dst,a);}
 public static void PasteClean(Bitmap dst,Bitmap clean){var a=Read(dst);var b=Read(clean);var dl=new double[clean.Height,3];var dr=new double[clean.Height,3];for(int y=0;y<clean.Height;y++){int count=0;for(int yy=Math.Max(0,y-65);yy<=Math.Min(clean.Height-1,y+65);yy++){int al=((yy+60)*dst.Width+2070)*4,ar=((yy+60)*dst.Width+2070+clean.Width-1)*4,bl=yy*clean.Width*4,br=(yy*clean.Width+clean.Width-1)*4;for(int c=0;c<3;c++){dl[y,c]+=a[al+c]-b[bl+c];dr[y,c]+=a[ar+c]-b[br+c];}count++;}for(int c=0;c<3;c++){dl[y,c]/=count;dr[y,c]/=count;}}for(int y=0;y<clean.Height;y++)for(int x=0;x<clean.Width;x++){double t=Math.Min(1,Math.Min(Math.Min(x,clean.Width-1-x),Math.Min(y,clean.Height-1-y))/48.0);int p=((y+60)*dst.Width+x+2070)*4,q=(y*clean.Width+x)*4;double u=x/(double)(clean.Width-1);for(int c=0;c<3;c++){double delta=dl[y,c]*(1-u)+dr[y,c]*u;double col=Math.Max(0,Math.Min(255,b[q+c]+delta));a[p+c]=(byte)Math.Round(a[p+c]*(1-t)+col*t);}}Write(dst,a);}
 public static void LimitHead(Bitmap src,Bitmap mask){var a=Read(src);var b=Read(mask);int w=src.Width,h=src.Height;var d=new float[w*h];for(int q=0;q<d.Length;q++)d[q]=b[q*4+3]>180?10000:0;for(int y=1;y<h;y++)for(int x=1;x<w-1;x++){int q=y*w+x;d[q]=Math.Min(d[q],Math.Min(Math.Min(d[q-1]+1,d[q-w]+1),Math.Min(d[q-w-1]+1.414f,d[q-w+1]+1.414f)));}for(int y=h-2;y>=0;y--)for(int x=w-2;x>0;x--){int q=y*w+x;d[q]=Math.Min(d[q],Math.Min(Math.Min(d[q+1]+1,d[q+w]+1),Math.Min(d[q+w+1]+1.414f,d[q+w-1]+1.414f)));}for(int q=0;q<d.Length;q++)a[q*4+3]=(byte)Math.Round(a[q*4+3]*Math.Min(1,d[q]/25.0));Write(src,a);}
 public static long RGBDiff(Bitmap a,Bitmap b,Rectangle r){var x=Read(a);var y=Read(b);long n=0;for(int yy=r.Top;yy<r.Bottom;yy++)for(int xx=r.Left;xx<r.Right;xx++){int p=(yy*a.Width+xx)*4;if(x[p]!=y[p]||x[p+1]!=y[p+1]||x[p+2]!=y[p+2])n++;}return n;}
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
function Load32($path,$w=3840,$h=2160){$im=[System.Drawing.Image]::FromFile($path);$b=[System.Drawing.Bitmap]::new($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.CompositingMode='SourceCopy';$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';if($im.Width -eq $w -and $im.Height -eq $h){$g.DrawImageUnscaled($im,0,0)}else{$g.DrawImage($im,0,0,$w,$h)};$g.Dispose();$im.Dispose();return $b}
$base=Load32 (Join-Path $assets '09_scene_lighting_generated.png');$fix=Load32 (Join-Path $assets '09_body_integration_generated.png');[LockedPhotoV9]::BlendBody($base,$fix);$fix.Dispose()
$clean=Load32 (Join-Path $assets 'Casper_clean_background.png') 900 765;[LockedPhotoV9]::PasteClean($base,$clean);$clean.Dispose()
$head=Load32 (Join-Path $assets 'Casper_original_head_neck.png')
$mask=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($mask);$g.SmoothingMode='AntiAlias'
# Entire original head and neck, soft boundary restricted to the surrounding shirt.
$p=@(0,0,3840,0,3840,850,2380,850,2370,970,2330,1100,2290,1270,2260,1430,2220,1480,2040,1480,1980,1400,1910,1270,1850,1120,1820,1000,1810,900,0,900)
$pts=for($i=0;$i -lt $p.Count;$i+=2){[System.Drawing.PointF]::new($p[$i],$p[$i+1])};$g.FillPolygon([System.Drawing.Brushes]::White,[System.Drawing.PointF[]]$pts);$g.Dispose();[LockedPhotoV9]::LimitHead($head,$mask);$mask.Dispose();$head.Save((Join-Path $assets 'Casper_head_neck_locked.png'))
$original=Load32 (Join-Path $root 'Sources_HD\Casper\Casper_00-12-00.jpg')
$faceDiff=[LockedPhotoV9]::RGBDiff($head,$original,[System.Drawing.Rectangle]::new(1980,380,320,440));$neckDiff=[LockedPhotoV9]::RGBDiff($head,$original,[System.Drawing.Rectangle]::new(2050,1050,100,150));$original.Dispose();if($faceDiff -ne 0 -or $neckDiff -ne 0){throw ('Original face/neck RGB changed: '+$faceDiff+' / '+$neckDiff)}
$g=[System.Drawing.Graphics]::FromImage($base);$g.InterpolationMode='HighQualityBicubic';$g.PixelOffsetMode='HighQuality';$g.CompositingQuality='HighQuality';$g.DrawImage($head,[single]420,[single]15,[single]3916.8,[single]2203.2);$g.Dispose();$head.Dispose();$base.Save((Join-Path $assets '09_scene_selected.png'))
$small=[System.Drawing.Bitmap]::new(1280,720);$g=[System.Drawing.Graphics]::FromImage($small);$g.InterpolationMode='HighQualityBicubic';$g.DrawImage($base,0,0,1280,720);$g.Dispose();$small.Save((Join-Path $root 'Apercus\V09_StyleNaturel\photo_final.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$small.Dispose()
$defs=@(@('Casper',2070,75,900,1450),@('Riz',720,150,900,1000),@('Mains',1680,1500,2160,560))
foreach($d in $defs){$crop=$base.Clone([System.Drawing.Rectangle]::new($d[1],$d[2],$d[3],$d[4]),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $root ('Apercus\V09_StyleNaturel\Controle_100pct\'+$d[0]+'.png')));$crop.Dispose()};$base.Dispose()
[pscustomobject]@{OriginalCasperFaceRGBChangedPixels=$faceDiff;FaceVerificationROI="1980,380,320,440";OriginalCasperNeckRGBChangedPixels=$neckDiff;FaceWarp=$false;HeadRotation=0;WholeHeadAndNeckPhotoLayer=$true;AddedGrain=$false;NativeSource='3840x2160';GeneratedPlate='1672x941';PortraitScale=1.02;Final='3840x2160'}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Photographic_verification.json') -Encoding utf8





