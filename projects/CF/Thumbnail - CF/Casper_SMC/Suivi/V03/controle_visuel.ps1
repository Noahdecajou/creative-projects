$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot);$out=Join-Path $root 'Apercus\V03\Controle_100pct'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$jobs=@(@('01',827,15,430,505,'01_Casper'),@('03',186,107,215,245,'03_Riz'),@('03',891,98,225,245,'03_Casper'),@('04',837,15,420,455,'04_Riz'),@('05',556,62,246,301,'05_Casper'),@('05',242,478,235,224,'05_Main_marqueur'),@('05',851,491,247,210,'05_Main_posee'),@('07',794,81,250,277,'07_Casper'),@('07',204,102,244,247,'07_Riz'),@('07',896,500,290,173,'07_Mains_Casper'),@('08',931,100,183,236,'08_Riz'))
foreach($j in $jobs){$file=Get-ChildItem -LiteralPath (Join-Path $root 'Exports_4K\V03') -Filter ($j[0]+'_*.png')|Select-Object -First 1;$im=[System.Drawing.Bitmap]::FromFile($file.FullName);$rect=[System.Drawing.Rectangle]::new(($j[1]*3),($j[2]*3),($j[3]*3),($j[4]*3));$b=$im.Clone($rect,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb);$b.Save((Join-Path $out ($j[5]+'.png')));$b.Dispose();$im.Dispose()}
