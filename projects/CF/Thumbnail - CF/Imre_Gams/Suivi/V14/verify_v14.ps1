$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$code=@'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CFV14Check {
 static int[] Pixels(string path){using(var b=new Bitmap(path)){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var p=new int[b.Width*b.Height];try{Marshal.Copy(d.Scan0,p,0,p.Length);}finally{b.UnlockBits(d);}return p;}}
 public static long[] Compare(string oldFile,string newFile,Rectangle[] regions){
  var oldPixels=Pixels(oldFile);var newPixels=Pixels(newFile);var allowed=new bool[oldPixels.Length];
  foreach(var r in regions)for(int y=r.Top;y<r.Bottom;y++)for(int x=r.Left;x<r.Right;x++)allowed[y*3840+x]=true;
  long changed=0,outside=0;for(int n=0;n<oldPixels.Length;n++)if(oldPixels[n]!=newPixels[n]){changed++;if(!allowed[n])outside++;}
  return new long[]{changed,outside};
 }
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$root=Split-Path (Split-Path $PSScriptRoot)
$candles=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Illustrative_candles.csv')
$oldCandles=Import-Csv -LiteralPath (Join-Path $root 'Suivi/V13/Illustrative_candles.csv')
if(Compare-Object $candles $oldCandles -Property Image,X,OpenY,CloseY,HighY,LowY,BodyWidth){throw 'Candle geometry changed'}
$oldType=Import-Csv -LiteralPath (Join-Path $root 'Suivi/V13/Typography_geometry.csv')
$newType=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Typography_geometry.csv')
if(Compare-Object $oldType $newType -Property Image,Text,X,Y,Width,Height,Font,Weight){throw 'Text layout changed'}
$files=@(Get-ChildItem -LiteralPath (Join-Path $root 'Exports/V14') -Filter '*.png' -File | Sort-Object Name)
if($files.Count -ne 8){throw 'Expected eight exports'}
$records=@()
foreach($file in $files){
 $older=Join-Path (Join-Path $root 'Exports/V13') $file.Name
 $id=$file.Name.Substring(0,2)
 if([int]$id -le 2){
  $regions=[System.Collections.Generic.List[System.Drawing.Rectangle]]::new()
  foreach($c in @($candles | Where-Object Image -eq $id)){
   $x=[int][math]::Floor((([double]$c.X)-([double]$c.BodyWidth)/2)*3)-3
   $y=([int]$c.HighY)*3-3
   $w=([int]$c.BodyWidth)*3+6;$h=(([int]$c.LowY)-([int]$c.HighY))*3+6
   $regions.Add([System.Drawing.Rectangle]::new($x,$y,$w,$h))
  }
  $diff=[CFV14Check]::Compare($older,$file.FullName,$regions.ToArray())
  if($diff[0] -eq 0 -or $diff[1] -ne 0){throw ('Unexpected pixel changes: '+$id+' '+($diff -join ','))}
  $records+=[pscustomobject]@{Image=$id;ChangedPixels=$diff[0];ChangesOutsideCandles=$diff[1];UnchangedOutsideCandles=$true;ByteIdenticalToV13=$false}
 }else{
  if((Get-FileHash -LiteralPath $older).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash){throw ('Unexpected change: '+$file.Name)}
  $records+=[pscustomobject]@{Image=$id;ChangedPixels=0;ChangesOutsideCandles=0;UnchangedOutsideCandles=$true;ByteIdenticalToV13=$true}
 }
}
$records | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Pixel_preservation.csv')
Write-Output 'VERIFIED: only candle pixels changed in 01/02; every other pixel is identical to V13. Images 03-08 are byte-identical. Candle geometry and typography are unchanged.'
