$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$drawingDir=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Rectangle].Assembly.Location,(Join-Path $drawingDir 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingDir 'System.Private.Windows.Core.dll')) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class LocalFace {
 public static long Apply(string original,string generated,string output,int x,int y,int w,int h) {
  using(var a=new Bitmap(original)) using(var b=new Bitmap(generated)) {
   if(a.Width!=b.Width || a.Height!=b.Height) throw new Exception("Dimension mismatch");
   var all=new Rectangle(0,0,a.Width,a.Height);
   var da=a.LockBits(all,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
   var db=b.LockBits(all,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
   int size=da.Stride*a.Height; var old=new byte[size]; var edited=new byte[size];
   Marshal.Copy(da.Scan0,old,0,size); Marshal.Copy(db.Scan0,edited,0,size);
   var result=(byte[])old.Clone();
   for(int yy=y;yy<y+h;yy++) for(int xx=x;xx<x+w;xx++) {
    double edge=Math.Min(x==0?1000:xx-x,Math.Min(y==0?1000:yy-y,Math.Min(x+w-1-xx,y+h-1-yy)));
    double alpha=Math.Max(0,Math.Min(1,edge/14.0)); alpha=alpha*alpha*(3-2*alpha);
    int i=yy*da.Stride+xx*4;
    for(int c=0;c<3;c++) result[i+c]=(byte)Math.Round(old[i+c]*(1-alpha)+edited[i+c]*alpha);
   }
   long changedOutside=0;
   for(int yy=0;yy<a.Height;yy++) for(int xx=0;xx<a.Width;xx++) {
    if(xx>=x && xx<x+w && yy>=y && yy<y+h) continue;
    int i=yy*da.Stride+xx*4;
    if(result[i]!=old[i] || result[i+1]!=old[i+1] || result[i+2]!=old[i+2]) changedOutside++;
   }
   Marshal.Copy(result,0,da.Scan0,size); a.UnlockBits(da); b.UnlockBits(db);
   if(changedOutside!=0) throw new Exception("Outside region modified");
   a.Save(output,ImageFormat.Png); return changedOutside;
  }
 }
}
'@
$root=Split-Path $PSScriptRoot -Parent
$items=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'face_manifest.json') -Raw | ConvertFrom-Json
$checks=@()
foreach($item in $items){
 $out=Join-Path (Join-Path $root 'face_edits') (Split-Path $item.original -Leaf)
 $r=$item.rect
 $outside=[LocalFace]::Apply($item.original,$item.generated,$out,$r[0],$r[1],$r[2],$r[3])
 $checks+=[pscustomobject]@{Number=$item.n;File=$out;EditBounds=$r;ChangedPixelsOutsideFaceRegion=$outside;Method='Built-in imagegen identity correction using two original photographs; feathered local insertion preserving V05 outside face region'}
}
$checks | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'face_preservation_verification.json') -Encoding utf8
$checks | Select-Object Number,ChangedPixelsOutsideFaceRegion | ConvertTo-Json
