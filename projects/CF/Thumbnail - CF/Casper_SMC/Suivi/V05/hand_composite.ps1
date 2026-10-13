$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V05'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class LocalHandV5{
static byte[] Get(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
static void Put(Bitmap b,byte[] v){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
public static int[] Composite(Bitmap a,Bitmap b){var av=Get(a);var bv=Get(b);double[,] mask={{1294,763,107,35},{1367,751,40,25}};int count=0,x0=a.Width,y0=a.Height,x1=-1,y1=-1;for(int y=704;y<805;y++)for(int x=1180;x<1410;x++){double t=0;for(int j=0;j<2;j++){double dx=(x-mask[j,0])/mask[j,2],dy=(y-mask[j,1])/mask[j,3],r=Math.Sqrt(dx*dx+dy*dy);double q=Math.Max(0,Math.Min(1,(1-r)/.28));t=Math.Max(t,q*q*(3-2*q));}if(t==0)continue;int p=(y*a.Width+x)*4;for(int c=0;c<3;c++)av[p+c]=(byte)Math.Round(av[p+c]*(1-t)+bv[p+c]*t);count++;x0=Math.Min(x0,x);x1=Math.Max(x1,x);y0=Math.Min(y0,y);y1=Math.Max(y1,y);}Put(a,av);return new int[]{count,x0,y0,x1,y1};}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$a=[System.Drawing.Bitmap]::FromFile((Join-Path $assets '03_scene_generated.png'))
# The selected context crop removes the spurious pattern; only the dorsal hand masks are composited.
$im=[System.Drawing.Bitmap]::FromFile((Join-Path $assets '03_hand_detail_generated.png'));$b=[System.Drawing.Bitmap]::new($a.Width,$a.Height,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.InterpolationMode='HighQualityBicubic';$g.DrawImage($im,[System.Drawing.Rectangle]::new(1060,520,612,420));$g.Dispose();$im.Dispose()
$r=[LocalHandV5]::Composite($a,$b);$a.Save((Join-Path $assets '03_scene_retouch.png'))
$crop=$a.Clone([System.Drawing.Rectangle]::new(1120,690,430,150),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $root 'Apercus\V05\03_hand_patch.png'));$crop.Dispose();$a.Dispose();$b.Dispose()
[pscustomobject]@{MaskPixelCount=$r[0];Bounds=($r[1..4]-join ',');SourceDimensions='1672x940';Description='Selected ImageGen detail crop composited only into dorsal hand and bare wrist masks. All pixels outside those masks are preserved, including finger silhouettes and remaining scene.'}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot '03_hand_patch_manifest.json') -Encoding utf8


