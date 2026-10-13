$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$assets=Join-Path $root 'Masters\V04'
if(-not (Test-Path -LiteralPath (Join-Path $assets 'handdrawn_charts_generated.png'))){Copy-Item -LiteralPath 'C:\Users\notti\.codex\generated_images\01a130a7-5add-7363-b5bb-540e469a7d9f\exec-6e043955-a3fb-432a-825b-592dd8f25a96.png' -Destination (Join-Path $assets 'handdrawn_charts_generated.png')}
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class MarkerAlphaV4{
 public static void Extract(Bitmap b,bool profile){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);
 for(int y=0;y<b.Height;y++)for(int x=0;x<b.Width;x++){int p=y*d.Stride+x*4;double lo=Math.Min(v[p],Math.Min(v[p+1],v[p+2])),hi=Math.Max(v[p],Math.Max(v[p+1],v[p+2]));double a=Math.Min(1,Math.Max(0,(hi-lo-12)/32.0))*Math.Min(1,Math.Max(0,(255-lo)/145.0));if(profile&&x>545)a=0;if(a<.025){v[p+3]=0;continue;}for(int c=0;c<3;c++)v[p+c]=(byte)Math.Max(0,Math.Min(255,(v[p+c]-255*(1-a))/a));v[p+3]=(byte)Math.Round(a*255);}
 Marshal.Copy(v,0,d.Scan0,v.Length);b.UnlockBits(d);}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$im=[System.Drawing.Bitmap]::FromFile((Join-Path $assets 'handdrawn_charts_generated.png'))
$defs=@(@('balance',80,60,600,180),@('trend',80,263,590,247),@('trigger',70,586,630,304),@('profile',829,30,660,450),@('accept',925,515,560,415))
foreach($d in $defs){$crop=$im.Clone([System.Drawing.Rectangle]::new($d[1],$d[2],$d[3],$d[4]),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);[MarkerAlphaV4]::Extract($crop,($d[0] -eq 'profile'));$crop.Save((Join-Path $assets ('chart_'+$d[0]+'.png')));$crop.Dispose()};$im.Dispose()
$p=Join-Path $PSScriptRoot 'render_v04.ps1';$s=Get-Content -LiteralPath $p -Raw
$s=$s.Replace("Photo 'chart_trend.png' 69 391 291 70","Photo 'chart_trend.png' 69 391 291 79").Replace("Photo 'chart_trigger.png' 67 537 305 69","Photo 'chart_trigger.png' 67 531 305 88").Replace("67 624 20","67 634 20").Replace("@('VAH',280),@('POC',346),@('VAL',411)","@('VAH',283),@('POC',343),@('VAL',405)").Replace("Photo 'chart_accept.png' 908 500 300 104","Photo 'chart_accept.png' 919 489 290 129")
Set-Content -LiteralPath $p -Value $s -Encoding utf8
