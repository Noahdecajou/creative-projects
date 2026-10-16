param([string]$Plate='09_scene_lighting_generated.png',[string]$Output='09_photo_guide.png')
$ErrorActionPreference='Stop';Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V09_StyleNaturel';$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$code=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class OriginalHeadV9 {
 static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
 static void Write(Bitmap b,byte[] v){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
 public static void Matte(Bitmap src,Bitmap alpha){var s=Read(src);var a=Read(alpha);int w=src.Width,h=src.Height;var d=new float[w*h];for(int q=0;q<d.Length;q++)d[q]=a[q*4+3]>180?10000:0;
 for(int y=1;y<h;y++)for(int x=1;x<w-1;x++){int q=y*w+x;d[q]=Math.Min(d[q],Math.Min(Math.Min(d[q-1]+1,d[q-w]+1),Math.Min(d[q-w-1]+1.414f,d[q-w+1]+1.414f)));}
 for(int y=h-2;y>=0;y--)for(int x=w-2;x>0;x--){int q=y*w+x;d[q]=Math.Min(d[q],Math.Min(Math.Min(d[q+1]+1,d[q+w]+1),Math.Min(d[q+w+1]+1.414f,d[q+w-1]+1.414f)));}
 var orig=(byte[])s.Clone();
 for(int y=0;y<h;y++)for(int x=0;x<w;x++){int q=y*w+x,p=q*4;double v=d[q]>20?1:a[p+3]/255.0;v*=Math.Min(1,Math.Max(0,(d[q]-1.2)/2.5));
 // Preserve the complete head, neck and original collar; fade only on clothing.
 double bottom=Math.Min(1,Math.Max(0,(1530-y)/100.0));v*=bottom;
 // Keep the microphone outside the retained source layer.
 if(y>1120 && x>2400) v*=Math.Min(1,Math.Max(0,(2450-x)/50.0));
 if(v>0 && y<810 && d[q]<15 && (s[p]>s[p+2]+4||s[p+1]>s[p+2]+6)){
 int best=-1;double score=1e10;for(int dy=-25;dy<=25;dy+=5)for(int dx=-25;dx<=25;dx+=5){int xx=x+dx,yy=y+dy;if(xx<0||xx>=w||yy<0||yy>=h)continue;int k=yy*w+xx;if(d[k]<17)continue;double sc=dx*dx+dy*dy;if(sc<score){score=sc;best=k*4;}}
 if(best>=0){double t=Math.Min(.94,(15-d[q])/12.0);for(int c=0;c<3;c++)s[p+c]=(byte)Math.Round(s[p+c]*(1-t)+orig[best+c]*t);}
 }
 s[p+3]=(byte)Math.Round(v*255);
 }Write(src,s);}
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
function Load32($path){$im=[System.Drawing.Image]::FromFile($path);$b=[System.Drawing.Bitmap]::new($im.Width,$im.Height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.CompositingMode='SourceCopy';$g.DrawImageUnscaled($im,0,0);$g.Dispose();$im.Dispose();return $b}
$head=Load32 (Join-Path $root 'Sources_HD\Casper\Casper_00-12-00.jpg');$alpha=Load32 (Join-Path $root 'Masters\V01\Casper_00-12-00_cutout.png');[OriginalHeadV9]::Matte($head,$alpha);$alpha.Dispose();$head.Save((Join-Path $assets 'Casper_original_head_neck.png'))
$plateImage=[System.Drawing.Image]::FromFile((Join-Path $assets $Plate));$b=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality';$g.SmoothingMode='AntiAlias';$g.DrawImage($plateImage,0,0,3840,2160);$plateImage.Dispose()
# Uniform scale and translation only. No head rotation, warping or isolated face patch.
$s=.34*3;$tx=140*3;$ty=5*3;$g.DrawImage($head,[single]$tx,[single]$ty,[single]($head.Width*$s),[single]($head.Height*$s));$g.Dispose();$head.Dispose();$b.Save((Join-Path $assets $Output))
$small=[System.Drawing.Bitmap]::new(1280,720);$g=[System.Drawing.Graphics]::FromImage($small);$g.InterpolationMode='HighQualityBicubic';$g.DrawImage($b,0,0,1280,720);$g.Dispose();$small.Save((Join-Path $root 'Apercus\V09_StyleNaturel\photo_guide.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$small.Dispose();$b.Dispose()
[pscustomobject]@{Source='Sources_HD/Casper/Casper_00-12-00.jpg';AlphaSource='Masters/V01/Casper_00-12-00_cutout.png';SourceWidth=3840;SourceHeight=2160;ScaleAt4K=$s;TranslateX=$tx;TranslateY=$ty;Rotation=0;FaceWarp=$false;OriginalFaceAndNeckRGB=$true;EdgeOnlyDecontamination=$true;ClothingFadeStartY=1430;ClothingFadeEndY=1530}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Original_head_assembly.json') -Encoding utf8

