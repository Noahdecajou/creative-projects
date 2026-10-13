$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot)
$asset=Join-Path $root 'Masters\V03'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class PhotoMatteV3 {
 public static byte[] Get(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
 public static void Put(Bitmap b,byte[] v){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
 public static float[] Distance(byte[] v,int w,int h){var d=new float[w*h];for(int i=0;i<d.Length;i++)d[i]=v[i*4+3]>150?10000:0;for(int y=1;y<h;y++)for(int x=1;x<w-1;x++){int p=y*w+x;d[p]=Math.Min(d[p],Math.Min(Math.Min(d[p-1]+1,d[p-w]+1),Math.Min(d[p-w-1]+1.414f,d[p-w+1]+1.414f)));}for(int y=h-2;y>=0;y--)for(int x=w-2;x>0;x--){int p=y*w+x;d[p]=Math.Min(d[p],Math.Min(Math.Min(d[p+1]+1,d[p+w]+1),Math.Min(d[p+w+1]+1.414f,d[p+w-1]+1.414f)));}return d;}
 public static void CleanHead(Bitmap b,Bitmap mask){var v=Get(b);var m=Get(mask);var original=(byte[])v.Clone();int w=b.Width,h=b.Height;var dist=Distance(v,w,h);var md=Distance(m,w,h);
  for(int y=0;y<h;y++)for(int x=0;x<w;x++){int q=y*w+x,p=q*4;float a=(float)(v[p+3]/255.0*Math.Min(1,md[q]/55.0));if(a<=0){v[p+3]=0;continue;}
   float d=dist[q]; if(d<32 && y<1100 && v[p+3]>0){int best=-1;double score=1e9;for(int yy=-42;yy<=42;yy+=7)for(int xx=-42;xx<=42;xx+=7){int nx=x+xx,ny=y+yy;if(nx<0||ny<0||nx>=w||ny>=h)continue;int nq=ny*w+nx,np=nq*4;if(dist[nq]<22)continue;double s=(xx*xx+yy*yy)+Math.Max(0,(original[np]+original[np+1]+original[np+2])/3-130)*8;if(s<score){score=s;best=np;}}
    if(best>=0){double lum=(original[p]+original[p+1]+original[p+2])/3.0,inner=(original[best]+original[best+1]+original[best+2])/3.0;bool spill=original[p]>original[p+2]+4||original[p+1]>original[p+2]+4||lum>inner+25;double t=spill?Math.Min(.95,(32-d)/27.0):Math.Max(0,(12-d)/18.0);for(int c=0;c<3;c++)v[p+c]=(byte)(original[p+c]*(1-t)+original[best+c]*t);}
    a*=(float)Math.Min(1,Math.Max(0,(d-1.3)/2.5));
   }v[p+3]=(byte)(255*a);
  }Put(b,v);
 }
 public static void RestoreFront(Bitmap b,Bitmap src,Bitmap mask){var v=Get(b);var s=Get(src);var m=Get(mask);var d=Distance(s,b.Width,b.Height);var md=Distance(m,b.Width,b.Height);for(int q=0;q<d.Length;q++){int p=q*4;double t=Math.Min(1,md[q]/15.0)*Math.Min(1,Math.Max(0,(d[q]-18)/40.0));if(s[p+3]<240)t=0;for(int c=0;c<3;c++)v[p+c]=(byte)(v[p+c]*(1-t)+s[p+c]*t);}Put(b,v);}
 public static void Grade(Bitmap b,double contrast,double saturation){var v=Get(b);for(int p=0;p<v.Length;p+=4){if(v[p+3]==0)continue;double l=.0722*v[p]+.7152*v[p+1]+.2126*v[p+2];for(int c=0;c<3;c++){double z=l+(v[p+c]-l)*saturation;z=(z-118)*contrast+118;v[p+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(z)));}}Put(b,v);}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
function Bmp($path,$w=3840,$h=2160){$im=[System.Drawing.Image]::FromFile($path);$b=[System.Drawing.Bitmap]::new($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.CompositingMode='SourceCopy';$g.InterpolationMode='HighQualityBicubic';$g.DrawImage($im,0,0,$w,$h);$g.Dispose();$im.Dispose();return $b}
function Mask($shapes){$b=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.ScaleTransform(3,3);$g.SmoothingMode='AntiAlias';foreach($s in $shapes){$p=for($i=0;$i -lt $s.Count;$i+=2){[System.Drawing.PointF]::new($s[$i],$s[$i+1])};$g.FillPolygon([System.Drawing.Brushes]::White,[System.Drawing.PointF[]]$p)};$g.Dispose();return $b}
$head12=@(0,0,1280,0,1280,282,816,282,774,303,750,317,744,356,737,403,730,443,725,469,705,471,676,462,658,432,643,399,631,364,623,327,619,298,618,282,0,282)
$arm12left=@(487,715,480,689,481,662,505,649,530,650,577,669,629,686,683,709,714,720)
$arm12right=@(904,711,897,680,900,650,922,620,948,615,970,620,995,640,1020,680,1030,715)
$b=Bmp (Join-Path $asset 'Casper_front_cleanup_generated.png');$src=Bmp (Join-Path $root 'Masters\V02\Casper_front_photo.png');$mask=Mask @($head12,$arm12left,$arm12right);[PhotoMatteV3]::RestoreFront($b,$src,$mask);[PhotoMatteV3]::Grade($b,1.055,1.065);$b.Save((Join-Path $asset 'Casper_front_photo.png'));$b.Dispose();$src.Dispose();$mask.Dispose()
$b=Bmp (Join-Path $root 'Masters\V02\Riz_front_photo.png');$mask=Mask @(,@(0,0,1280,0,1280,720,0,720));[PhotoMatteV3]::CleanHead($b,$mask);$b.Save((Join-Path $asset 'Riz_front_photo.png'));$b.Dispose();$mask.Dispose()

# Source head layers kept separately so the scene plate can be reviewed against the original photography.
$head16=@(670,160,777,174,802,195,801,219,789,240,741,235,713,226,679,218,663,201)
$head20=@(645,112,704,99,746,126,757,168,733,179,699,173,665,174,637,163)
$headR=@(555,146,700,129,739,163,760,212,766,286,758,341,734,379,698,404,651,402,611,382,587,344,573,295,559,253)
$head09=@(470,143,551,151,578,179,581,209,562,221,529,216,501,218,476,209,466,184)
$defs=@(
 @('Casper05','Masters\V02\Casper_00-16-00_cutout.png',$head16),
 @('Casper03','Masters\V02\Casper_00-20-00_cutout.png',$head20),
 @('Riz03','Masters\V02\Riz_01-16-00_cutout.png',$headR),
 @('Casper07','Masters\V03\Casper_00-09-00_cutout.png',$head09),
 @('Riz07','Masters\V03\Riz_00-58-00_cutout.png',$headR)
)
foreach($j in $defs){$b=Bmp (Join-Path $root $j[1]);$m=Mask @(,$j[2]);[PhotoMatteV3]::CleanHead($b,$m);[PhotoMatteV3]::Grade($b,1.025,1.03);$b.Save((Join-Path $asset ($j[0]+'_head.png')));$b.Dispose();$m.Dispose()}
function Head($g,$name,$sx1,$sy1,$sx2,$sy2,$dx1,$dy1,$dx2,$dy2,$flip=$false){
 $im=[System.Drawing.Bitmap]::FromFile((Join-Path $asset ($name+'_head.png')))
 if($flip){$im.RotateFlip('RotateNoneFlipX');$sx1=2048-$sx1;$sx2=2048-$sx2}
 $ux=$sx2-$sx1;$uy=$sy2-$sy1;$vx=$dx2-$dx1;$vy=$dy2-$dy1;$d=$ux*$ux+$uy*$uy
 $a=($ux*$vx+$uy*$vy)/$d;$bb=($ux*$vy-$uy*$vx)/$d;$tx=$dx1-$a*$sx1+$bb*$sy1;$ty=$dy1-$bb*$sx1-$a*$sy1
 $ratio=3840.0/1672.0;$aa=$a*$ratio/1.875;$b2=$bb*$ratio/1.875
 $matrix=[System.Drawing.Drawing2D.Matrix]::new([single]$aa,[single]$b2,[single](-$b2),[single]$aa,[single]($tx*$ratio),[single]($ty*$ratio));$state=$g.Save();$g.Transform=$matrix;$g.DrawImageUnscaled($im,0,0);$g.Restore($state);$matrix.Dispose();$im.Dispose()
}
foreach($id in @('03','05','07','08')){
 $b=Bmp (Join-Path $asset ($id+'_scene_generated.png'));$g=[System.Drawing.Graphics]::FromImage($b);$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality'
 switch($id){
 '05'{Head $g 'Casper05' 1090 395 1218 411 812 306 891 315}
 '03'{Head $g 'Casper03' 1005 318 1094 337 1220 280 1281 293;Head $g 'Riz03' 1033 389 1167 367 391 311 462 287}
 '07'{Head $g 'Casper07' 768 366 858 365 1078 305 1128 302}
 '08'{Head $g 'Riz03' 1033 389 1167 367 1317 275 1255 267 $true}
 }
 $g.Dispose();$b.Save((Join-Path $asset ($id+'_scene_photo_test.png')));$small=[System.Drawing.Bitmap]::new(1672,941);$sg=[System.Drawing.Graphics]::FromImage($small);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($b,0,0,1672,941);$sg.Dispose();$small.Save((Join-Path $root ('Apercus\V03\'+$id+'_photo_test.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$small.Dispose();$b.Dispose()
}



