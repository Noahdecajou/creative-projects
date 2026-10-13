$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class LocalRect26 {
 public static void Apply(Bitmap target,Bitmap patch,Rectangle[] regions,int feather) {
  var b=target.LockBits(new Rectangle(0,0,target.Width,target.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  var p=patch.LockBits(new Rectangle(0,0,patch.Width,patch.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  byte[] dst=new byte[b.Stride*target.Height],src=new byte[p.Stride*patch.Height];Marshal.Copy(b.Scan0,dst,0,dst.Length);Marshal.Copy(p.Scan0,src,0,src.Length);
  foreach(var r in regions)for(int y=r.Top;y<r.Bottom;y++)for(int x=r.Left;x<r.Right;x++){
   double alpha=Math.Min(1.0,Math.Min(Math.Min(x-r.Left,r.Right-1-x),Math.Min(y-r.Top,r.Bottom-1-y))/(double)feather);
   for(int c=0;c<3;c++){int i=y*b.Stride+x*4+c;int j=y*p.Stride+x*4+c;dst[i]=(byte)Math.Round(dst[i]*(1-alpha)+src[j]*alpha);}
  }
  Marshal.Copy(dst,0,b.Scan0,dst.Length);target.UnlockBits(b);patch.UnlockBits(p);
 }
 public static bool SameOutside(Bitmap a,Bitmap b,Rectangle[] regions) {
  for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){bool inside=false;foreach(var r in regions)if(r.Contains(x,y)){inside=true;break;}if(!inside&&a.GetPixel(x,y)!=b.GetPixel(x,y))return false;}return true;
 }
}
'@ -ReferencedAssemblies @('System.Drawing.Common','System.Drawing.Primitives','System.Runtime.InteropServices')
$root=Split-Path $PSScriptRoot -Parent
$rows=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Local_corrections_generated.json') | ConvertFrom-Json
$report=@()
foreach($r in $rows){
 $master=Join-Path $root ('masters\Sampsa_'+$r.id+'.png')
 $beforePath=Join-Path $PSScriptRoot ('Before_local_'+$r.id+'.png')
 if(-not(Test-Path -LiteralPath $beforePath)){Copy-Item -LiteralPath $master -Destination $beforePath}
 $before=[Drawing.Bitmap]::new($beforePath)
 $patch=[Drawing.Bitmap]::new($r.generatedPath)
 if($before.Width-ne$patch.Width-or$before.Height-ne$patch.Height){throw ('Edit dimensions differ '+$r.id)}
 $out=[Drawing.Bitmap]::new($before.Width,$before.Height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($out);$g.DrawImageUnscaled($before,0,0);$g.Dispose()
 $rectangles=[Drawing.Rectangle[]]@($r.rects | ForEach-Object {[Drawing.Rectangle]::new($_[0],$_[1],$_[2],$_[3])})
 [LocalRect26]::Apply($out,$patch,$rectangles,3)
 $same=[LocalRect26]::SameOutside($before,$out,$rectangles)
 if(-not$same){throw ('Protected pixels changed '+$r.id)}
 $before.Dispose();$patch.Dispose();$out.Save($master,[Drawing.Imaging.ImageFormat]::Png);$out.Dispose()
 Copy-Item -LiteralPath $r.generatedPath -Destination (Join-Path $PSScriptRoot ('Local_generated_'+$r.id+'.png'))
 $report+=[pscustomobject]@{Id=$r.id;OutsideRegionsPixelIdentical=$same;Regions=$r.rects;Feather=3}
}
$report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Local_pixel_verification.json') -Encoding utf8
$report | Select-Object Id,OutsideRegionsPixelIdentical
