$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$asset=Join-Path (Split-Path $PSScriptRoot) 'Masters\V02'
$code=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class PortraitFinish {
 public static void CyanEdge(Bitmap image) {
  var data=image.LockBits(new Rectangle(0,0,image.Width,image.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
  try {
   var bytes=new byte[data.Stride*data.Height];Marshal.Copy(data.Scan0,bytes,0,bytes.Length);
   for(int y=0;y<Math.Min(1350,image.Height);y++)for(int x=0;x<image.Width;x++) {
    int p=y*data.Stride+x*4;int b=bytes[p],g=bytes[p+1],r=bytes[p+2];
    bool edge=bytes[p+3]<245;
    if(x>18 && x<image.Width-18 && y>18 && y<image.Height-18)
     edge=edge || bytes[p-72+3]<120 || bytes[p+72+3]<120 || bytes[p-18*data.Stride+3]<120 || bytes[p+18*data.Stride+3]<120;
    if(edge && bytes[p+3]>0 && g>r+10 && b>r+12) {bytes[p]=(byte)(r+(b-r)*.18);bytes[p+1]=(byte)(r+(g-r)*.18);}
   }
   Marshal.Copy(bytes,0,data.Scan0,bytes.Length);
  } finally {image.UnlockBits(data);}
 }
 public static long ChangedPixels(Bitmap a,Bitmap b,int x,int y,int w,int h) {
  long changed=0;for(int j=y;j<y+h;j++)for(int i=x;i<x+w;i++) {var ca=a.GetPixel(i,j);var cb=b.GetPixel(i,j);if(ca.A==255 && cb.A==255 && ca.ToArgb()!=cb.ToArgb())changed++;}return changed;
 }
}
'@
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$checks=@(
 @('Casper_front_photo.png','Casper_00-12-00_cutout.png',1850,350,420,480),
 @('Casper_explain_photo.png','Casper_00-16-00_cutout.png',1950,550,430,450),
 @('Casper_conversation_photo.png','Casper_00-20-00_cutout.png',1870,380,380,430),
 @('Riz_front_photo.png','Riz_01-16-00_cutout.png',1660,560,510,440),
 @('Riz_conversation_photo.png','Riz_01-34-00_cutout.png',1770,570,460,440)
)
$result=foreach($item in $checks){
 $input=Join-Path (Split-Path $asset) ('V01\'+$item[0]);$im=[System.Drawing.Bitmap]::FromFile($input);$b=New-Object System.Drawing.Bitmap(3840,2160,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$g=[System.Drawing.Graphics]::FromImage($b);$g.CompositingMode='SourceCopy';$g.DrawImageUnscaled($im,0,0);$g.Dispose();$im.Dispose();[PortraitFinish]::CyanEdge($b);$b.Save((Join-Path $asset $item[0]),[System.Drawing.Imaging.ImageFormat]::Png)
 $original=[System.Drawing.Bitmap]::FromFile((Join-Path $asset $item[1]));$n=[PortraitFinish]::ChangedPixels($original,$b,$item[2],$item[3],$item[4],$item[5]);$original.Dispose();$b.Dispose()
 [pscustomobject]@{Portrait=$item[0];Source=$item[1];FaceRegion=($item[2..5]-join ',');ChangedOpaquePixels=$n;Note='Comparison restricted to fully opaque source and output pixels. Transparent edge RGB can change during alpha compositing. Before resizing and final grain.'}
}
$result|Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Verification_visages_V02.csv');$result|Format-Table -AutoSize
