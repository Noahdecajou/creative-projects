$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$out=Join-Path $root 'Apercus\V04\Controle_100pct'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$jobs=@(@('01',953,222,260,115,'01_Casper_yeux'),@('02',953,222,260,115,'02_Casper_yeux'),@('04',179,203,208,110,'04_Casper_yeux'),@('06',583,309,176,88,'06_Casper_yeux'),@('06',63,260,319,361,'06_Schemas_feutre'),@('08',651,143,242,111,'08_Bleu_electrique'))
foreach($j in $jobs){$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V04') -Filter ($j[0]+'_*.png')|Select-Object -First 1;$im=[System.Drawing.Bitmap]::FromFile($file.FullName);$rect=[System.Drawing.Rectangle]::new(($j[1]*3),($j[2]*3),($j[3]*3),($j[4]*3));$b=$im.Clone($rect,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$b.Save((Join-Path $out ($j[5]+'.png')));$b.Dispose();$im.Dispose()}
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class CompareV4{
 static byte[] Get(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
 public static int[] Diff(Bitmap a,Bitmap b){var va=Get(a);var vb=Get(b);int w=a.Width,h=a.Height,count=0,x0=w,y0=h,x1=-1,y1=-1;for(int y=0;y<h;y++)for(int x=0;x<w;x++){int p=(y*w+x)*4;if(va[p]==vb[p]&&va[p+1]==vb[p+1]&&va[p+2]==vb[p+2]&&va[p+3]==vb[p+3])continue;count++;x0=Math.Min(x0,x);x1=Math.Max(x1,x);y0=Math.Min(y0,y);y1=Math.Max(y1,y);}return new int[]{count,x0,y0,x1,y1};}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$report=foreach($f in (Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V04') -Filter '*.png' | Sort-Object Name)){
 $b=[System.Drawing.Bitmap]::FromFile($f.FullName);$a=[System.Drawing.Bitmap]::FromFile((Join-Path $root ('Exports_4K\V03\'+$f.Name)))
 $d=[CompareV4]::Diff($a,$b);$a.Dispose();$b.Dispose()
 [pscustomobject]@{File=$f.Name;ChangedPixels=$d[0];ChangedBounds=if($d[0]){$d[1..4]-join ','}else{'None'};V03Identical=($d[0] -eq 0)}
}
$report|Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'Pixel_comparison_V03_V04.csv') -NoTypeInformation -Encoding utf8
$report|Format-Table
