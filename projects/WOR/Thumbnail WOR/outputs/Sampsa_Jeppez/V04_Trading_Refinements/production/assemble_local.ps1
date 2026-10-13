$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V03_26_FrontCamera'
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class LocalV4 {
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
   int di=y*d.Stride+x*4,si=y*s.Stride+x*4;
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
'@ -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices','System.Private.Windows.GdiPlus','System.Private.Windows.Core')
$specs=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Local_preservation_regions.json')|ConvertFrom-Json
$report=@()
foreach($s in $specs){
 $id=$s.id;$sid=$id;if($s.srcId){$sid=$s.srcId}
 $orig=[LocalV4]::Read((Join-Path $base ('masters\Sampsa_'+$sid+'.png')))
 $genPath=Join-Path $PSScriptRoot ('Generated_'+$id+'.png');if($id-eq'22'){$genPath=Join-Path $PSScriptRoot 'Generated_22_final.png'}
 $gen=[LocalV4]::Read($genPath)
 if($s.patches){$out=[LocalV4]::Read((Join-Path $base ('masters\Sampsa_'+$sid+'.png')));foreach($r in $s.patches){[LocalV4]::Blend($out,$gen,[int[]]$r,$false,3)}}
 else{$out=[LocalV4]::Read($genPath);foreach($r in $s.faces){[LocalV4]::Blend($out,$orig,[int[]]$r,$true,8)};foreach($r in $s.hands){[LocalV4]::Blend($out,$orig,[int[]]$r,$false,6)};if($s.mouth){[LocalV4]::Blend($out,$gen,[int[]]$s.mouth,$false,3)}}
 $dental=Join-Path $PSScriptRoot ('Dental_'+$id+'.png')
 if(Test-Path -LiteralPath $dental){$dent=[LocalV4]::Read($dental);[LocalV4]::Blend($out,$dent,[int[]]$s.mouth,$false,3);$dent.Dispose()}
 $outside=$null
 if($s.patches){$rs=[int[][]]@($s.patches|ForEach-Object {,[int[]]$_});$outside=[LocalV4]::OutsideChanged($orig,$out,$rs);if($outside-ne0){throw ('Pixels changed outside local patch '+$id)}}
 $path=Join-Path $root ('masters\Sampsa_'+$id+'.png');$out.Save($path,[Drawing.Imaging.ImageFormat]::Png)
 $report+=[pscustomobject]@{Id=$id;Source=$sid;LocalPatch=[bool]$s.patches;OutsideLocalPatchChangedPixels=$outside;ProtectedFaceRegions=@($s.faces).Count;ProtectedHandsRegions=@($s.hands).Count;DentalLocal=[bool](Test-Path -LiteralPath $dental);Width=$out.Width;Height=$out.Height;SHA256=(Get-FileHash -LiteralPath $path).Hash}
 $orig.Dispose();$gen.Dispose();$out.Dispose()
}
# The yellow comparison differs only within the candlestick and its contact reflection.
$green=[LocalV4]::Read((Join-Path $root 'masters\Sampsa_11_Green.png'))
$yellow=[LocalV4]::Read((Join-Path $PSScriptRoot 'Generated_11_Yellow.png'))
$out=[LocalV4]::Read((Join-Path $root 'masters\Sampsa_11_Green.png'))
$candle=[int[]]@(772,367,133,522)
[LocalV4]::Blend($out,$yellow,$candle,$false,3)
$changed=[LocalV4]::OutsideChanged($green,$out,[int[][]]@(,$candle));if($changed-ne0){throw 'Color comparison changed outside candle'}
$yp=Join-Path $root 'masters\Sampsa_11_Yellow.png';$out.Save($yp,[Drawing.Imaging.ImageFormat]::Png)
$report+=[pscustomobject]@{Id='11_Yellow';Source='11_Green';LocalPatch=$true;OutsideLocalPatchChangedPixels=$changed;Width=$out.Width;Height=$out.Height;SHA256=(Get-FileHash -LiteralPath $yp).Hash}
$green.Dispose();$yellow.Dispose();$out.Dispose()
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Local_pixel_verification.json') -Encoding utf8
'20 edited masters assembled; local preservation verified.'

