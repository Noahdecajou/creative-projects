$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V04'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class GazeV4{
 public static byte[] Get(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
 public static void Put(Bitmap b,byte[] v){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
 public static void Patch(Bitmap b,Bitmap eyes){var v=Get(b);var s=Get(eyes);double[,] masks={{383,452,70,33},{595,463,58,33}};for(int y=0;y<eyes.Height;y++)for(int x=0;x<eyes.Width;x++){double a=0;for(int j=0;j<2;j++){double u=(x-masks[j,0])/masks[j,2],z=(y-masks[j,1])/masks[j,3],r=Math.Sqrt(u*u+z*z);double t=Math.Max(0,Math.Min(1,(1-r)/.24));a=Math.Max(a,t*t*(3-2*t));}if(a<=0)continue;int p=((y+85)*b.Width+x+1670)*4,q=(y*eyes.Width+x)*4;double l=.0722*s[q]+.7152*s[q+1]+.2126*s[q+2];for(int c=0;c<3;c++){double col=l+(s[q+c]-l)*1.065;col=(col-118)*1.055+118;col=Math.Max(0,Math.Min(255,col));v[p+c]=(byte)Math.Round(v[p+c]*(1-a)+col*a);}}Put(b,v);}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$generated=[System.Drawing.Image]::FromFile((Join-Path $assets 'Casper_gaze_generated.png'))
$eyes=[System.Drawing.Bitmap]::new(810,940,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($eyes);$g.InterpolationMode='HighQualityBicubic';$g.DrawImage($generated,0,0,810,940);$g.Dispose();$generated.Dispose()
$b=[System.Drawing.Bitmap]::FromFile((Join-Path $root 'Masters\V03\Casper_front_photo.png'))
[GazeV4]::Patch($b,$eyes);$b.Save((Join-Path $assets 'Casper_front_photo.png'))
$crop=$b.Clone([System.Drawing.Rectangle]::new(1670,85,810,940),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $root 'Apercus\V04\Casper_gaze_local_patch.png'))
$crop.Dispose();$b.Dispose();$eyes.Dispose()
