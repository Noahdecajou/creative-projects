$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$out=Join-Path $root 'Apercus\V05\Controle_100pct'
New-Item -ItemType Directory -Force -Path $out|Out-Null
$jobs=@(@('03',215,100,230,265,'03_Riz_visage'),@('03',879,82,225,310,'03_Casper_visage'),@('03',655,507,174,124,'03_Main_marqueur'),@('03',859,546,209,90,'03_Main_posee'),@('03',154,499,255,136,'03_Mains_Riz'),@('05',430,10,400,105,'05_Degrade_et_lueur'),@('08',194,130,285,156,'08_Fleche_derriere_tete'))
foreach($j in $jobs){$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V05') -Filter ($j[0]+'_*.png')|Select-Object -First 1;$im=[System.Drawing.Bitmap]::FromFile($file.FullName);$crop=$im.Clone([System.Drawing.Rectangle]::new(($j[1]*3),($j[2]*3),($j[3]*3),($j[4]*3)),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $out ($j[5]+'.png')));$im.Dispose();$crop.Dispose()}
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class FaceRegionsV5{
static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
public static int Count(Bitmap a,Bitmap b,Rectangle r){var av=Read(a);var bv=Read(b);int n=0;for(int y=r.Top;y<r.Bottom;y++)for(int x=r.Left;x<r.Right;x++){int p=(y*a.Width+x)*4;for(int c=0;c<3;c++)if(av[p+c]!=bv[p+c]){n++;break;}}return n;}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
# Rectangles sample interior facial skin; the former wider Casper 04 rectangle included the relit board background beside his jaw.
$checks=@(@('01','Casper',900,230,300,290),@('02','Casper',900,230,300,290),@('04','Casper',200,270,75,110),@('04','Riz',935,172,208,228),@('05','Casper',598,177,130,178),@('06','Casper',573,299,165,212),@('07','Riz',251,224,154,115),@('07','Casper',860,203,140,153),@('08','Riz',945,166,129,161))
$report=foreach($v in $checks){$f=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V05') -Filter ($v[0]+'_*.png')|Select-Object -First 1;$a=[System.Drawing.Bitmap]::FromFile((Join-Path $root ('Exports_4K\V04\'+$f.Name)));$b=[System.Drawing.Bitmap]::FromFile($f.FullName);$r=[System.Drawing.Rectangle]::new(($v[2]*3),($v[3]*3),($v[4]*3),($v[5]*3));$n=[FaceRegionsV5]::Count($a,$b,$r);$a.Dispose();$b.Dispose();[pscustomobject]@{Image=$v[0];Person=$v[1];NativeRegion=($r.ToString());ChangedPixels=$n;FacialRegionPreserved=($n -eq 0)}}
$report|Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'Visages_preserves_V04_V05.csv') -NoTypeInformation -Encoding utf8
$report|Format-Table Image,Person,ChangedPixels,FacialRegionPreserved


# Confirm that the selected local hand repair preserves every pixel outside its bounding area.
$a=[System.Drawing.Bitmap]::FromFile((Join-Path $root 'Masters\V05\03_scene_generated.png'));$b=[System.Drawing.Bitmap]::FromFile((Join-Path $root 'Masters\V05\03_scene_retouch.png'));$n=0
foreach($r in @([System.Drawing.Rectangle]::new(0,0,1672,704),[System.Drawing.Rectangle]::new(0,805,1672,135),[System.Drawing.Rectangle]::new(0,704,1180,101),[System.Drawing.Rectangle]::new(1410,704,262,101))){$n+=[FaceRegionsV5]::Count($a,$b,$r)};$a.Dispose();$b.Dispose()
if($n -ne 0){throw 'Pixels outside the hand repair changed'}
[pscustomobject]@{ChangedPixelsOutsideHandArea=$n;SourceDimensions='1672x940';AllowedHandArea='1180,704,230,101'}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_main_locale.json') -Encoding utf8
