$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V08_StyleNaturel'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class SeamPatchV8{
public static byte[] Get(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
public static long Patch(Bitmap target,Bitmap patch){var a=Get(target);var p=Get(patch);var before=(byte[])a.Clone();double[,] masks={{619,271,70,65},{147,568,68,110},{228,660,110,70}};for(int y=0;y<760;y++)for(int x=0;x<760;x++){double opacity=0;for(int i=0;i<3;i++){double d=Math.Sqrt(Math.Pow((x-masks[i,0])/masks[i,2],2)+Math.Pow((y-masks[i,1])/masks[i,3],2));double t=Math.Max(0,Math.Min(1,(1-d)/.22));opacity=Math.Max(opacity,t*t*(3-2*t));}if(opacity<=0)continue;int q=((y+210)*target.Width+x+2170)*4,s=(y*760+x)*4;for(int c=0;c<3;c++)a[q+c]=(byte)Math.Round(a[q+c]*(1-opacity)+p[s+c]*opacity);}
 long outside=0;for(int y=0;y<target.Height;y++)for(int x=0;x<target.Width;x++){int lx=x-2170,ly=y-210;bool allowed=(lx>=549&&lx<=689&&ly>=206&&ly<=336)||(lx>=79&&lx<=215&&ly>=458&&ly<=678)||(lx>=118&&lx<=338&&ly>=590&&ly<=730);if(allowed)continue;int q=(y*target.Width+x)*4;for(int c=0;c<4;c++)if(a[q+c]!=before[q+c]){outside++;break;}}var d2=target.LockBits(new Rectangle(0,0,target.Width,target.Height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);Marshal.Copy(a,0,d2.Scan0,a.Length);target.UnlockBits(d2);return outside;}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$im=[System.Drawing.Image]::FromFile((Join-Path $assets 'Casper_seam_repair_generated.png'));$p=[System.Drawing.Bitmap]::new(760,760,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$pg=[System.Drawing.Graphics]::FromImage($p);$pg.InterpolationMode='HighQualityBicubic';$pg.DrawImage($im,0,0,760,760);$pg.Dispose();$im.Dispose()
$b=[System.Drawing.Bitmap]::FromFile((Join-Path $assets '09_scene_photo_composite.png'));$outside=[SeamPatchV8]::Patch($b,$p);if($outside -ne 0){throw 'Patch changed pixels outside permitted regions'};$b.Save((Join-Path $assets '09_scene_photo_final.png'))
$crop=$b.Clone([System.Drawing.Rectangle]::new(2170,210,760,760),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $root 'Apercus\V08_StyleNaturel\Controle_100pct\Casper_final.png'));$crop.Dispose();$b.Dispose();$p.Dispose()
[pscustomobject]@{Offset='2170,210';Region1='Temple glasses 619,271,70,65';Region2='Outer jaw 147,568,68,110';Region3='Lower jaw 228,660,110,70';ChangedPixelsOutsideRegions=$outside;CentralEyesNoseMouthAndForeheadPreserved=$true}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Local_seams_verification.json') -Encoding utf8
