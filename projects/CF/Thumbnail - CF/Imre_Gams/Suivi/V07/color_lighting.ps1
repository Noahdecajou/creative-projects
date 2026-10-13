Add-Type -AssemblyName System.Drawing
$colorRuntime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$colorCode=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFColorLighting {
 static double Smooth(double edge0,double edge1,double x) {
  double t=Math.Max(0,Math.Min(1,(x-edge0)/(edge1-edge0)));
  return t*t*(3-2*t);
 }
 public static Bitmap Background(int width,int height) {
  var bitmap=new Bitmap(width,height,PixelFormat.Format32bppArgb);
  var data=new int[width*height];
  for(int yy=0;yy<height;yy++) {
   double y=720.0*yy/height;
   double ry=(y-405)/240.0,gy=(y-415)/260.0;
   for(int xx=0;xx<width;xx++) {
    double x=1280.0*xx/width;
    double rx=(x-10)/235.0,gx=(x-1270)/250.0;
    double red=Math.Exp(-0.5*(rx*rx+ry*ry))*(1-Smooth(150,320,x));
    double green=Math.Exp(-0.5*(gx*gx+gy*gy))*Smooth(960,1130,x);
    // Sub-LSB quantization dither keeps the continuous light field free of bands.
    uint hash=unchecked((uint)(xx*374761393+yy*668265263));
    hash=(hash^(hash>>13))*1274126177u;
    double d=((hash^(hash>>16))&255)/255.0-0.5;
    int r=(int)Math.Round(10+140*red+1*green+d);
    int g=(int)Math.Round(11+3*red+132*green+d);
    int b=(int)Math.Round(13+8*red+12*green+d);
    data[yy*width+xx]=unchecked((int)0xff000000)|(r<<16)|(g<<8)|b;
   }
  }
  var bd=bitmap.LockBits(new Rectangle(0,0,width,height),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
  try {Marshal.Copy(data,0,bd.Scan0,data.Length);} finally {bitmap.UnlockBits(bd);}
  return bitmap;
 }
}
'@
Add-Type -TypeDefinition $colorCode -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $colorRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $colorRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
