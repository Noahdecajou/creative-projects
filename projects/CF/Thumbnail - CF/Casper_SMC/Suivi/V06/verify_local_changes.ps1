$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$out=Join-Path $root 'Apercus\V06\Controle_100pct'
$runtime=Split-Path ([System.Drawing.Bitmap].Assembly.Location)
$cs=@'
using System;using System.Drawing;using System.Drawing.Imaging;using System.Runtime.InteropServices;
public static class CompareV6{
static byte[] Read(Bitmap b){var d=b.LockBits(new Rectangle(0,0,b.Width,b.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);var v=new byte[d.Stride*b.Height];Marshal.Copy(d.Scan0,v,0,v.Length);b.UnlockBits(d);return v;}
public static long[] Outside(Bitmap a,Bitmap b,Rectangle[] areas){var av=Read(a);var bv=Read(b);long changed=0,outside=0;for(int y=0;y<a.Height;y++)for(int x=0;x<a.Width;x++){int p=(y*a.Width+x)*4;bool diff=false;for(int c=0;c<4;c++)if(av[p+c]!=bv[p+c]){diff=true;break;}if(!diff)continue;changed++;bool allowed=false;foreach(var r in areas)if(r.Contains(x,y)){allowed=true;break;}if(!allowed)outside++;}return new long[]{changed,outside};}
}
'@
Add-Type -TypeDefinition $cs -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtime 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtime 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
$unchanged=foreach($id in @('01','03','07','08')){$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V06') -Filter ($id+'_*.png')|Select-Object -First 1;$a=(Get-FileHash -LiteralPath (Join-Path $root ('Exports_4K\V05\'+$file.Name))).Hash;$b=(Get-FileHash -LiteralPath $file.FullName).Hash;if($a -ne $b){throw ('Unrequested image changed: '+$id)};[pscustomobject]@{Image=$id;SHA256=$b;ByteIdenticalToV05=$true}}
$unchanged|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Images_inchangees_V05_V06.csv')
$reports=foreach($id in @('02','04','05','06')){
 $file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V06') -Filter ($id+'_*.png')|Select-Object -First 1
 $a=[System.Drawing.Bitmap]::FromFile((Join-Path $root ('Exports_4K\V05\'+$file.Name)));$b=[System.Drawing.Bitmap]::FromFile($file.FullName)
 [System.Drawing.Rectangle[]]$allowed=switch($id){
 '02'{[System.Drawing.Rectangle]::new(960,1150,900,585)}
 '04'{[System.Drawing.Rectangle]::new(2957,669,265,170);[System.Drawing.Rectangle]::new(2660,611,245,175)}
 '05'{[System.Drawing.Rectangle]::new(2907,1158,870,324);[System.Drawing.Rectangle]::new(18,1848,798,312)}
 '06'{[System.Drawing.Rectangle]::new(820,407,2195,1753)}
 }
 $result=[CompareV6]::Outside($a,$b,$allowed);$a.Dispose();$b.Dispose()
 if($result[1] -ne 0){throw ('Unexpected pixels outside requested area, image '+$id+': '+$result[1])}
 [pscustomobject]@{Image=$id;ChangedPixels=$result[0];ChangedPixelsOutsideRequestedAreas=$result[1];AllowedAreas=($allowed|ForEach-Object {$_.ToString()}) -join '; '}
}
$reports|Export-Csv -NoTypeInformation -Encoding utf8 -LiteralPath (Join-Path $PSScriptRoot 'Corrections_locales_V05_V06.csv')
$portraitA=(Get-FileHash -LiteralPath (Join-Path $root 'Masters\V05\Casper_front_photo.png')).Hash;$portraitB=(Get-FileHash -LiteralPath (Join-Path $root 'Masters\V06\Casper_front_photo.png')).Hash
if($portraitA -ne $portraitB){throw 'Casper original component was changed'}
$jobs=@(@('02',310,375,333,216,'02_Bougies'),@('04',890,97,316,350,'04_Riz_regard'),@('06',471,196,345,379,'06_Casper_visage'),@('05',14,624,250,89,'05_Nom_Casper'))
foreach($j in $jobs){$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V06') -Filter ($j[0]+'_*.png')|Select-Object -First 1;$im=[System.Drawing.Bitmap]::FromFile($file.FullName);$crop=$im.Clone([System.Drawing.Rectangle]::new(($j[1]*3),($j[2]*3),($j[3]*3),($j[4]*3)),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$crop.Save((Join-Path $out ($j[5]+'.png')));$im.Dispose();$crop.Dispose()}
$reports|Format-Table Image,ChangedPixels,ChangedPixelsOutsideRequestedAreas
'Four untouched exports verified byte-identical; Casper portrait component unchanged.'
