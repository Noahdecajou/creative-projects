$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V04_Trading_Refinements'
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class LocalV5 { public static bool SkipCyan=false;
 public static Bitmap Read(string path) { using(var im=Image.FromFile(path)){var b=new Bitmap(im.Width,im.Height,PixelFormat.Format32bppArgb);using(var g=Graphics.FromImage(b)){g.DrawImageUnscaled(im,0,0);}return b;} }
 public static void Blend(Bitmap dst,Bitmap src,int[] r,bool ellipse,int feather) {
  if(dst.Width!=src.Width||dst.Height!=src.Height)throw new Exception("Unaligned inputs");
  var rect=new Rectangle(0,0,dst.Width,dst.Height);
  var d=dst.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var s=src.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  var db=new byte[d.Stride*dst.Height];var sb=new byte[s.Stride*src.Height];
  Marshal.Copy(d.Scan0,db,0,db.Length);Marshal.Copy(s.Scan0,sb,0,sb.Length);
  for(int y=r[1];y<Math.Min(dst.Height,r[1]+r[3]);y++)for(int x=r[0];x<Math.Min(dst.Width,r[0]+r[2]);x++){
   if(x<0||y<0)continue;
   double a;
   if(ellipse){double nx=(x-(r[0]+r[2]/2.0))/(r[2]/2.0),ny=(y-(r[1]+r[3]/2.0))/(r[3]/2.0);a=(1-Math.Sqrt(nx*nx+ny*ny))*Math.Min(r[2],r[3])/2.0/feather;}
   else{a=(double)Math.Min(Math.Min(x-r[0],r[0]+r[2]-1-x),Math.Min(y-r[1],r[1]+r[3]-1-y))/feather;}
   a=Math.Max(0,Math.Min(1,a)); if(a==0)continue;
   int di=y*d.Stride+x*4,si=y*s.Stride+x*4; if(SkipCyan && sb[si+1]>70 && sb[si]>70 && sb[si+1]>sb[si+2]*1.35 && sb[si]>sb[si+2]*1.4)continue;
   for(int c=0;c<3;c++)db[di+c]=(byte)Math.Round(db[di+c]*(1-a)+sb[si+c]*a);
  }
  Marshal.Copy(db,0,d.Scan0,db.Length);src.UnlockBits(s);dst.UnlockBits(d);
 }
 public static long OutsideChanged(Bitmap a,Bitmap b,int[][] rs){
  var rect=new Rectangle(0,0,a.Width,a.Height);var ad=a.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var bd=b.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  var aa=new byte[ad.Stride*a.Height];var bb=new byte[bd.Stride*b.Height];Marshal.Copy(ad.Scan0,aa,0,aa.Length);Marshal.Copy(bd.Scan0,bb,0,bb.Length);long count=0;
  for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){bool inside=false;foreach(var r in rs){if(x>=r[0]&&x<r[0]+r[2]&&y>=r[1]&&y<r[1]+r[3]){inside=true;break;}}if(inside)continue;int ai=y*ad.Stride+x*4,bi=y*bd.Stride+x*4;if(aa[ai]!=bb[bi]||aa[ai+1]!=bb[bi+1]||aa[ai+2]!=bb[bi+2])count++;}
  a.UnlockBits(ad);b.UnlockBits(bd);return count;
 }
}
public static class ExtraV5 {
 public static void Mix(Bitmap dst,Bitmap src,double a) {
  var r=new Rectangle(0,0,dst.Width,dst.Height); var d=dst.LockBits(r,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);var s=src.LockBits(r,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  byte[] db=new byte[d.Stride*dst.Height],sb=new byte[s.Stride*src.Height];Marshal.Copy(d.Scan0,db,0,db.Length);Marshal.Copy(s.Scan0,sb,0,sb.Length);
  for(int y=0;y<dst.Height;y++)for(int x=0;x<dst.Width;x++){int i=y*d.Stride+x*4;for(int c=0;c<3;c++)db[i+c]=(byte)Math.Round(db[i+c]*(1-a)+sb[i+c]*a);}
  Marshal.Copy(db,0,d.Scan0,db.Length);src.UnlockBits(s);dst.UnlockBits(d);
 }
 public static void Polygon(Bitmap dst,Bitmap src,int[] xy){
  Point[] pts=new Point[xy.Length/2];for(int i=0;i<pts.Length;i++)pts[i]=new Point(xy[i*2],xy[i*2+1]);
  using(var p=new System.Drawing.Drawing2D.GraphicsPath()){p.AddPolygon(pts);using(var g=Graphics.FromImage(dst)){g.SetClip(p);g.DrawImageUnscaled(src,0,0);}}
 }
}

'@ -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices','System.Private.Windows.GdiPlus','System.Private.Windows.Core')

$specs=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Local_regions.json')|ConvertFrom-Json
$report=@()
foreach($s in $specs){
 $id=$s.id
 $op=Join-Path $base ('masters\Sampsa_'+$id+'.png')
 $gp=Join-Path $PSScriptRoot ('Generated_'+$id+'.png')
 $orig=[LocalV5]::Read($op);$gen=[LocalV5]::Read($gp)
 if($s.patches){$out=[LocalV5]::Read($op);$feather=3;if($s.feather){$feather=$s.feather};foreach($r in $s.patches){[LocalV5]::Blend($out,$gen,[int[]]$r,$false,$feather)}}
 else{$out=[LocalV5]::Read($gp);[LocalV5]::SkipCyan=($id -in @("02","02_Duo"));foreach($r in $s.faces){[LocalV5]::Blend($out,$orig,[int[]]$r,$true,8)};[LocalV5]::SkipCyan=$false;foreach($r in $s.hands){[LocalV5]::Blend($out,$orig,[int[]]$r,$false,6)};foreach($p in $s.polygons){$xy=[int[]]@($p|ForEach-Object {$_[0];$_[1]});[ExtraV5]::Polygon($out,$orig,$xy)}}
 $outside=$null
 if($s.patches){$rs=[int[][]]@($s.patches|ForEach-Object {,[int[]]$_});$outside=[LocalV5]::OutsideChanged($orig,$out,$rs);if($outside-ne0){throw 'Unexpected external pixel change'}}
 $out.Save((Join-Path $root ('masters\Sampsa_'+$id+'.png')),[Drawing.Imaging.ImageFormat]::Png)
 $report+=[pscustomobject]@{Id=$id;OutsideLocalPatchChangedPixels=$outside;Width=$out.Width;Height=$out.Height}
 $orig.Dispose();$gen.Dispose();$out.Dispose()
}
# Yellow only changes candle, finger light and reflection; portraits stay exactly green version.
$green=[LocalV5]::Read((Join-Path $root 'masters\Sampsa_11_Green.png'))
$yellow=[LocalV5]::Read((Join-Path $PSScriptRoot 'Generated_11_Yellow.png'))
$out=[LocalV5]::Read((Join-Path $root 'masters\Sampsa_11_Green.png'))
$rect=[int[]]@(782,375,291,566)
[LocalV5]::Blend($out,$yellow,$rect,$false,10)
$outside=[LocalV5]::OutsideChanged($green,$out,[int[][]]@(,$rect));if($outside-ne0){throw 'Yellow changed outside candle region'}
$out.Save((Join-Path $root 'masters\Sampsa_11_Yellow.png'),[Drawing.Imaging.ImageFormat]::Png)
$report+=[pscustomobject]@{Id='11_Yellow';OutsideLocalPatchChangedPixels=$outside;Width=$out.Width;Height=$out.Height}
$green.Dispose();$yellow.Dispose();$out.Dispose()
# Blur comparison: endpoint mixed at precisely 10% and 15%. Foreground restored from original.
$orig=[LocalV5]::Read((Join-Path $base 'masters\Sampsa_13.png'))
$blur=[LocalV5]::Read((Join-Path $PSScriptRoot 'Generated_13_Blur.png'))
$polys=@(
 @(172,837,214,667,239,528,316,435,382,415,387,316,439,267,501,254,551,278,570,321,578,368,591,391,576,426,624,452,652,530,698,626,723,705,665,758,432,817),
 @(985,734,1005,639,1035,574,1081,518,1174,467,1180,437,1174,402,1188,350,1192,306,1230,277,1304,267,1348,296,1366,355,1355,423,1322,463,1422,511,1488,567,1505,667,1486,775),
 @(151,940,151,856,274,811,385,755,526,715,632,690,689,689,739,691,927,691,1009,692,1110,712,1262,732,1376,770,1569,849,1575,940)
)
foreach($pct in @(10,15)){
 $out=[LocalV5]::Read((Join-Path $base 'masters\Sampsa_13.png'))
 [ExtraV5]::Mix($out,$blur,($pct/100.0))
 foreach($poly in $polys){[ExtraV5]::Polygon($out,$orig,[int[]]$poly)}
 # Keep headline region and both main facial/hand regions fully original.
 [LocalV5]::Blend($out,$orig,[int[]]@(145,80,1400,158),$false,3)
 [LocalV5]::Blend($out,$orig,[int[]]@(390,285,210,217),$true,3)
 [LocalV5]::Blend($out,$orig,[int[]]@(1172,290,194,235),$true,3)
 $out.Save((Join-Path $root ('masters\Sampsa_13_Blur'+$pct+'.png')),[Drawing.Imaging.ImageFormat]::Png)
 $report+=[pscustomobject]@{Id=('13_Blur'+$pct);BlurEndpointOpacity=$pct;Width=$out.Width;Height=$out.Height}
 $out.Dispose()
}
$orig.Dispose();$blur.Dispose()
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Local_pixel_verification.json') -Encoding utf8
'15 edited masters assembled.'



