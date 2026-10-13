Add-Type -AssemblyName System.Drawing
$sourceImagePath = 'C:\Users\notti\Downloads\Scott_Pulcini_8_Stories_V3_Poppins\07_Hidden_Orders_Revealed.png'
$generatedImagePath = 'C:\Users\notti\.codex\generated_images\01a11aa1-9b2c-7e71-abf3-a7b1599c70b1\exec-a22a05e7-db73-4a7a-9291-df807c2cbceb.png'
$outputFolder = Join-Path $PSScriptRoot 'Stories_v4_Eye_Fix'
New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
$code = @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class RizEyeFix {
  public static void Run(string src,string generated,string dest) {
    using(var original=new Bitmap(src)) using(var gen=new Bitmap(generated))
    using(var output=new Bitmap(original.Width,original.Height,PixelFormat.Format32bppArgb))
    using(var edit=new Bitmap(original.Width,original.Height,PixelFormat.Format32bppArgb)) {
      using(var g=Graphics.FromImage(output))g.DrawImageUnscaled(original,0,0);
      using(var g=Graphics.FromImage(edit)){g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.DrawImage(gen,new Rectangle(0,0,edit.Width,edit.Height));}
      var rect=new Rectangle(0,0,output.Width,output.Height);
      var od=output.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
      var ed=edit.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
      try {
        byte[] a=new byte[od.Stride*od.Height],b=new byte[ed.Stride*ed.Height];
        Marshal.Copy(od.Scan0,a,0,a.Length);Marshal.Copy(ed.Scan0,b,0,b.Length);
        var rng=new Random(81407);
        for(int y=810;y<891;y++)for(int x=213;x<323;x++) {
          double radius=Math.Sqrt(Math.Pow((x-268)/55.0,2)+Math.Pow((y-850)/40.0,2));
          if(radius>=1)continue;
          double alpha=Math.Min(1,(1-radius)/.28);alpha=alpha*alpha*(3-2*alpha);
          double noise=Math.Sqrt(-2*Math.Log(1-rng.NextDouble()))*Math.Cos(2*Math.PI*rng.NextDouble())*7.65;
          int p=y*od.Stride+x*4;
          for(int c=0;c<3;c++) {
            double fixedPixel=Math.Max(0,Math.Min(255,b[p+c]+noise));
            a[p+c]=(byte)Math.Round(a[p+c]*(1-alpha)+fixedPixel*alpha);
          }
        }
        Marshal.Copy(a,0,od.Scan0,a.Length);
      } finally {output.UnlockBits(od);edit.UnlockBits(ed);}
      output.Save(dest,ImageFormat.Png);
    }
  }
}
'@
$runtimeFolder = Split-Path ([System.Drawing.Bitmap].Assembly.Location)
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtimeFolder 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtimeFolder 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$destination = Join-Path $outputFolder '07_Hidden_Orders_Revealed.png'
[RizEyeFix]::Run($sourceImagePath,$generatedImagePath,$destination)
Write-Output $destination
