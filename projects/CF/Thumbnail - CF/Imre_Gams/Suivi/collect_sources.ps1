$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot
$source=Join-Path $root 'Sources_HD'
$files=@(Get-ChildItem -LiteralPath 'C:\Users\notti\Downloads' -Filter 'frame_*.jpg' | Where-Object {$_.LastWriteTime -ge [datetime]'2026-10-12T11:21:00'} | Sort-Object {[int]([regex]::Match($_.Name,'frame_(\d+)').Groups[1].Value)})
$manifest=@()
foreach($f in $files){
 $frame=[int]([regex]::Match($f.Name,'frame_(\d+)').Groups[1].Value)
 $sec=$frame/30
 $tc='{0:00}:{1:00}:{2:00}:00' -f [int][math]::Floor($sec/3600),([int][math]::Floor($sec/60)%60),([int]$sec%60)
 $dest=Join-Path $source $f.Name
 Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
 $im=[System.Drawing.Image]::FromFile($dest)
 $manifest+=[pscustomobject]@{File=$f.Name;Timecode=$tc;Frame=$frame;FPS=30;Width=$im.Width;Height=$im.Height;Bytes=$f.Length;Method='Frame.io Viewer Settings - Download Still';Quality='1080p highest offered';Asset='03067022-6f86-4567-acb5-b0116ad44886';SHA256=(Get-FileHash -LiteralPath $dest).Hash}
 $im.Dispose()
}
$manifest | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Sources_manifest.csv')
$font=New-Object System.Drawing.Font('Arial',15)
for($start=0;$start -lt $files.Count;$start+=20){
 $items=@($manifest | Select-Object -Skip $start -First 20)
 $canvas=New-Object System.Drawing.Bitmap(1920,([int]([math]::Ceiling($items.Count/4)*300)))
 $g=[System.Drawing.Graphics]::FromImage($canvas);$g.Clear([System.Drawing.Color]::FromArgb(24,24,24))
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 for($j=0;$j -lt $items.Count;$j++){
  $im=[System.Drawing.Image]::FromFile((Join-Path $source $items[$j].File))
  $x=($j%4)*480;$y=[int][math]::Floor($j/4)*300
  $g.DrawImage($im,$x,$y,480,270)
  $g.DrawString(($items[$j].Timecode+' | '+$items[$j].Frame),$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+274))
  $im.Dispose()
 }
 $g.Dispose();$canvas.Save((Join-Path $root ('Apercus\Sources_'+([int]($start/20)+1)+'.jpg')),[System.Drawing.Imaging.ImageFormat]::Jpeg);$canvas.Dispose()
}
$font.Dispose()
Write-Output ('Native stills: '+$files.Count)
$manifest | Group-Object Width,Height | Select-Object Count,Name
