Add-Type -AssemblyName System.Drawing
$noiseCode = @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class ThumbnailNoise {
  public static void Apply(Bitmap image, double percent, int seed) {
    var rect = new Rectangle(0,0,image.Width,image.Height);
    var data=image.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
    try {
      var bytes=new byte[data.Stride*data.Height];
      Marshal.Copy(data.Scan0,bytes,0,bytes.Length);
      var random=new Random(seed);
      double sigma=255.0*percent/100.0;
      double spare=0; bool hasSpare=false;
      for(int y=0;y<image.Height;y++) {
        for(int x=0;x<image.Width;x++) {
          double z;
          if(hasSpare) { z=spare; hasSpare=false; }
          else {
            double u1=1.0-random.NextDouble(),u2=random.NextDouble();
            double radius=Math.Sqrt(-2.0*Math.Log(u1));
            z=radius*Math.Cos(2.0*Math.PI*u2);
            spare=radius*Math.Sin(2.0*Math.PI*u2); hasSpare=true;
          }
          int p=y*data.Stride+x*4;
          double n=z*sigma;
          for(int c=0;c<3;c++) bytes[p+c]=(byte)Math.Max(0,Math.Min(255,Math.Round(bytes[p+c]+n)));
        }
      }
      Marshal.Copy(bytes,0,data.Scan0,bytes.Length);
    } finally { image.UnlockBits(data); }
  }
}
'@
$noiseRuntime = Split-Path ([System.Drawing.Bitmap].Assembly.Location)
Add-Type -TypeDefinition $noiseCode -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $noiseRuntime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $noiseRuntime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
