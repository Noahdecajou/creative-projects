$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V06'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class GazeV6{
 public static byte[] Get(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
 public static void Put(Bitmap b,byte[] v){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
 public static long Patch(Bitmap b,Bitmap eyes){var v=Get(b);var s=Get(eyes);double[,] masks={{480,575,100,63},{719,532,92,65}};long changed=0;for(int y=0;y<eyes.Height;y++)for(int x=0;x<eyes.Width;x++){double a=0;for(int j=0;j<2;j++){double u=(x-masks[j,0])/masks[j,2],z=(y-masks[j,1])/masks[j,3],r=Math.Sqrt(u*u+z*z);double t=Math.Max(0,Math.Min(1,(1-r)/.32));a=Math.Max(a,t*t*(3-2*t));}if(a<=0)continue;int p=((y+160)*b.Width+x+1470)*4,q=(y*eyes.Width+x)*4;bool diff=false;for(int c=0;c<3;c++){byte col=(byte)Math.Round(v[p+c]*(1-a)+s[q+c]*a);if(v[p+c]!=col)diff=true;v[p+c]=col;}if(diff)changed++;}Put(b,v);return changed;}
 public static long Outside(Bitmap a,Bitmap b){var av=Get(a);var bv=Get(b);long n=0;for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){bool allowed=(x>=1850&&x<=2050&&y>=672&&y<=798)||(x>=2097&&x<=2281&&y>=627&&y<=757);if(allowed)continue;int p=(y*a.Width+x)*4;for(int c=0;c<4;c++)if(av[p+c]!=bv[p+c]){n++;break;}}return n;}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$generated=[System.Drawing.Image]::FromFile((Join-Path $assets 'Riz_gaze_generated.png'))
$eyes=[System.Drawing.Bitmap]::new(950,1120,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($eyes);$g.InterpolationMode='HighQualityBicubic';$g.DrawImage($generated,0,0,950,1120);$g.Dispose();$generated.Dispose()
$original=[System.Drawing.Bitmap]::FromFile((Join-Path $assets 'Riz_front_photo_original.png'))
$b=$original.Clone([System.Drawing.Rectangle]::new(0,0,$original.Width,$original.Height),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$count=[GazeV6]::Patch($b,$eyes);$outside=[GazeV6]::Outside($original,$b)
if($outside -ne 0){throw 'Changes outside allowed eye regions'}
$b.Save((Join-Path $assets 'Riz_front_photo.png'))
$crop=$b.Clone([System.Drawing.Rectangle]::new(1470,160,950,1120),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $root 'Apercus\V06\Riz_local_gaze_patch.png'))
[pscustomobject]@{Source='Riz_01-16-00.jpg';BasePortrait='V05/Riz_front_photo.png';CropNativePixels='1470,160,950,1120';EyeMasks='480,575,100,63 / 719,532,92,65';ChangedPixels=$count;ChangedPixelsOutsideEyeRegions=$outside;AlphaUnchanged=$true}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Riz_gaze_manifest.json') -Encoding utf8
$crop.Dispose();$b.Dispose();$original.Dispose();$eyes.Dispose()
