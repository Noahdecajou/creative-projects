param([string[]]$Names)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$dir=Join-Path $PSScriptRoot 'candidates'
foreach($name in $Names){
  Copy-Item -LiteralPath (Join-Path 'C:\Users\notti\Downloads' $name) -Destination (Join-Path $dir $name) -Force
}
$files=@(Get-ChildItem -LiteralPath $dir -File -Filter 'frame_*.jpg' | Sort-Object {[int]([regex]::Match($_.Name,'frame_(\d+)').Groups[1].Value)})
$manifest=foreach($file in $files){
  $frame=[int]([regex]::Match($file.Name,'frame_(\d+)').Groups[1].Value)
  $im=[Drawing.Image]::FromFile($file.FullName)
  [pscustomobject]@{File=$file.Name;Frame=$frame;Timecode=([TimeSpan]::FromSeconds($frame/30).ToString('hh\:mm\:ss'));Width=$im.Width;Height=$im.Height;Bytes=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
  $im.Dispose()
}
$manifest | Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'capture_manifest.csv') -NoTypeInformation -Encoding utf8
$font=New-Object Drawing.Font('Arial',16,[Drawing.FontStyle]::Bold)
for($page=0;$page -lt [Math]::Ceiling($files.Count/16);$page++){
  $group=@($files | Select-Object -Skip ($page*16) -First 16)
  $bmp=New-Object Drawing.Bitmap(1600,([Math]::Ceiling($group.Count/4)*255))
  $g=[Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::FromArgb(22,22,25))
  $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  for($j=0;$j -lt $group.Count;$j++){
    $file=$group[$j];$im=[Drawing.Image]::FromFile($file.FullName)
    $x=($j%4)*400;$y=[Math]::Floor($j/4)*255
    $g.DrawImage($im,$x,$y,400,225); $im.Dispose()
    $g.DrawString($file.BaseName,$font,[Drawing.Brushes]::White,($x+8),($y+230))
  }
  $out=Join-Path $root ('apercus\Selection_Contact_{0:00}.jpg' -f ($page+1))
  $bmp.Save($out,[Drawing.Imaging.ImageFormat]::Jpeg);$g.Dispose();$bmp.Dispose()
}
$font.Dispose()
$manifest | Group-Object Width,Height | Select-Object Count,Name | ConvertTo-Json
