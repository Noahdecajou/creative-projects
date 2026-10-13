Add-Type -AssemblyName System.Drawing
$drawingRuntime = Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$glowCode = @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFSoftGlow {
 public static Bitmap Blur(Bitmap mask, double sigma, Color tint, double opacity) {
  int width=mask.Width, height=mask.Height, count=width*height;
  var pixels=new int[count];
  var data=mask.LockBits(new Rectangle(0,0,width,height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
  try { Marshal.Copy(data.Scan0,pixels,0,count); } finally {mask.UnlockBits(data);}
  int radius=(int)Math.Ceiling(3*sigma);
  var kernel=new double[2*radius+1]; double sum=0;
  for(int d=-radius;d<=radius;d++){double v=Math.Exp(-(d*d)/(2*sigma*sigma));kernel[d+radius]=v;sum+=v;}
  for(int j=0;j<kernel.Length;j++)kernel[j]/=sum;
  var horizontal=new float[count];
  for(int y=0;y<height;y++)for(int x=0;x<width;x++){
   double v=0;for(int d=-radius;d<=radius;d++){int xx=x+d;if(xx>=0&&xx<width)v+=((uint)pixels[y*width+xx]>>24)*kernel[d+radius];}
   horizontal[y*width+x]=(float)v;
  }
  for(int y=0;y<height;y++)for(int x=0;x<width;x++){
   double v=0;for(int d=-radius;d<=radius;d++){int yy=y+d;if(yy>=0&&yy<height)v+=horizontal[yy*width+x]*kernel[d+radius];}
   int a=(int)Math.Round(Math.Min(255,v*opacity));
   pixels[y*width+x]=(a<<24)|(tint.R<<16)|(tint.G<<8)|tint.B;
  }
  var result=new Bitmap(width,height,PixelFormat.Format32bppArgb);
  var target=result.LockBits(new Rectangle(0,0,width,height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
  try {Marshal.Copy(pixels,0,target.Scan0,count);} finally {result.UnlockBits(target);}
  return result;
 }
}
'@
Add-Type -TypeDefinition $glowCode -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $drawingRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $drawingRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')

