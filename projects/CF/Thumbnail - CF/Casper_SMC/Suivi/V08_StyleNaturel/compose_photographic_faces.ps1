$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$asset=Join-Path $root 'Masters\V08_StyleNaturel';$out=Join-Path $root 'Apercus\V08_StyleNaturel'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class FaceMatteV8{
public static void Ellipse(Bitmap b,double cx,double cy,double rx,double ry){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){double r=Math.Sqrt(Math.Pow((x-cx)/rx,2)+Math.Pow((y-cy)/ry,2));double t=Math.Max(0,Math.Min(1,(1-r)/.20));t=t*t*(3-2*t);int p=y*d.Stride+x*4;v[p+3]=(byte)Math.Round(v[p+3]*t);}Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$plate=[System.Drawing.Image]::FromFile((Join-Path $asset '09_scene_generated.png'))
$b=[System.Drawing.Bitmap]::new(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.InterpolationMode='HighQualityBicubic';$g.CompositingQuality='HighQuality';$g.PixelOffsetMode='HighQuality';$g.DrawImage($plate,0,0,3840,2160);$ratioX=3840.0/$plate.Width;$ratioY=2160.0/$plate.Height;$plate.Dispose()
$defs=@(@('Riz',470,563,707,519,501,266,593,279,550,697,295,380),@('Casper',383,451,596,464,1068,233,1164,213,460,520,300,375))
$record=foreach($d in $defs){
 $im=[System.Drawing.Bitmap]::FromFile((Join-Path $asset ($d[0]+'_head_photo_reference.png')))
 [FaceMatteV8]::Ellipse($im,$d[9],$d[10],$d[11],$d[12]);$im.Save((Join-Path $asset ($d[0]+'_face_photo_layer.png')))
 $ux=$d[3]-$d[1];$uy=$d[4]-$d[2];$vx=$d[7]-$d[5];$vy=$d[8]-$d[6];$den=$ux*$ux+$uy*$uy
 $a=($ux*$vx+$uy*$vy)/$den;$bb=($ux*$vy-$uy*$vx)/$den;$tx=$d[5]-$a*$d[1]+$bb*$d[2];$ty=$d[6]-$bb*$d[1]-$a*$d[2]
 $m=[System.Drawing.Drawing2D.Matrix]::new([single]($a*$ratioX),[single]($bb*$ratioY),[single](-$bb*$ratioX),[single]($a*$ratioY),[single]($tx*$ratioX),[single]($ty*$ratioY));$state=$g.Save();$g.Transform=$m;$g.DrawImageUnscaled($im,0,0);$g.Restore($state);$m.Dispose();$im.Dispose()
 [pscustomobject]@{Person=$d[0];SourceEye1=($d[1..2]-join ',');SourceEye2=($d[3..4]-join ',');TargetEye1=($d[5..6]-join ',');TargetEye2=($d[7..8]-join ',');Ellipse=($d[9..12]-join ',');Scale=[math]::Sqrt($a*$a+$bb*$bb);RotationDegrees=([math]::Atan2($bb,$a)*180/[math]::PI);OriginalRGBUnretouched=$true}
}
$g.Dispose();$b.Save((Join-Path $asset '09_scene_photo_composite.png'))
$s=[System.Drawing.Bitmap]::new(1280,720);$sg=[System.Drawing.Graphics]::FromImage($s);$sg.InterpolationMode='HighQualityBicubic';$sg.DrawImage($b,0,0,1280,720);$sg.Dispose();$s.Save((Join-Path $out '09_photo_composite_preview.jpg'),[System.Drawing.Imaging.ImageFormat]::Jpeg);$s.Dispose();$b.Dispose()
$record|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Photo_face_composite.json') -Encoding utf8
