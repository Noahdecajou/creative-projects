$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public class RestoreStoryFaces {
 public static void Run(string source,string edited,string output,int id) {
  double[][] masks=new double[0][];
  if(id==1)masks=new[]{new[]{750d,880d,164d,230d}};
  if(id==2)masks=new[]{new[]{748d,850d,164d,235d}};
  if(id==3)masks=new[]{new[]{209d,754d,104d,137d},new[]{761d,759d,100d,138d}};
  if(id==4)masks=new[]{new[]{155d,865d,155d,235d},new[]{795d,870d,155d,235d}};
  if(id==5)masks=new[]{new[]{539d,789d,111d,156d}};
  if(id==6)masks=new[]{new[]{470d,864d,153d,230d}};
  if(id==7)masks=new[]{new[]{227d,742d,115d,157d},new[]{724d,733d,114d,157d}};
  if(id==8)masks=new[]{new[]{218d,817d,90d,153d},new[]{751d,817d,109d,151d}};
  using(var orig=new Bitmap(source)) using(var edit=new Bitmap(edited)) using(var result=new Bitmap(1080,1920,PixelFormat.Format32bppArgb)) {
   using(var g=Graphics.FromImage(result)){g.InterpolationMode=System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;g.DrawImage(edit,0,0,1080,1920);}
   var rect=new Rectangle(0,0,1080,1920);
   var a=orig.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var b=result.LockBits(rect,ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
   byte[] src=new byte[a.Stride*1920],dst=new byte[b.Stride*1920];Marshal.Copy(a.Scan0,src,0,src.Length);Marshal.Copy(b.Scan0,dst,0,dst.Length);
   for(int y=0;y<1920;y++)for(int x=0;x<1080;x++){
    int p=y*a.Stride+x*4;double xx=x*941.0/1080, yy=y*1672.0/1920,alpha=0;
    foreach(var m in masks){double d=Math.Sqrt(Math.Pow((xx-m[0])/m[2],2)+Math.Pow((yy-m[1])/m[3],2));alpha=Math.Max(alpha,Math.Max(0,Math.Min(1,(1-d)*25)));}
    int rr=src[p+2],gg=src[p+1],bb=src[p];
    if(rr<65||gg<38||bb<25||rr<gg*.95||rr>gg*2.3)alpha=0;
    if(alpha>0)for(int c=0;c<3;c++)dst[p+c]=(byte)Math.Round(dst[p+c]*(1-alpha)+src[p+c]*alpha);
   }
   Marshal.Copy(dst,0,b.Scan0,dst.Length);orig.UnlockBits(a);result.UnlockBits(b);result.Save(output,ImageFormat.Png);
  }
 }
}
'@
$root=Split-Path (Split-Path $PSScriptRoot)
$files=Get-ChildItem (Join-Path $root 'Masters\V02\ImageGen_Raw') -File -Filter '*.png' | Sort-Object Name
foreach($f in $files){[RestoreStoryFaces]::Run((Join-Path $root ('Stories_V01\'+$f.Name)),$f.FullName,(Join-Path $root ('Masters\V02\'+$f.Name)),[int]$f.Name.Substring(0,2))}
