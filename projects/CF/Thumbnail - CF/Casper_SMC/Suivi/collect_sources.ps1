param([string]$Subject='Casper',[int[]]$Seconds=@())
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$src=Join-Path $root "Sources_HD\$Subject"
foreach($sec in $Seconds){
 $frame=$sec*24
 $pattern='^frame_'+$frame+'(?: \(\d+\))?\.jpg$'
 $file=Get-ChildItem -LiteralPath 'C:\Users\notti\Downloads' -Filter 'frame_*.jpg' | Where-Object {$_.Name -match $pattern -and $_.LastWriteTime -ge [datetime]'2026-10-12T16:00:00'} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if(!$file){throw "Missing still $Subject at $sec"}
 $tc='{0:00}-{1:00}-{2:00}' -f [math]::Floor($sec/3600),([math]::Floor($sec/60)%60),($sec%60)
 $dest=Join-Path $src ($Subject+'_'+$tc+'.jpg')
 if(!(Test-Path -LiteralPath $dest)){Copy-Item -LiteralPath $file.FullName -Destination $dest}
}
$files=@(Get-ChildItem -LiteralPath $src -Filter '*.jpg' | Sort-Object Name)
$manifest=@()
$font=New-Object System.Drawing.Font('Arial',16)
for($start=0;$start -lt $files.Count;$start+=12){
 $items=@($files | Select-Object -Skip $start -First 12)
 $rows=[math]::Ceiling($items.Count/3)
 $canvas=New-Object System.Drawing.Bitmap(1920,([int]($rows*392)))
 $g=[System.Drawing.Graphics]::FromImage($canvas)
 $g.Clear([System.Drawing.Color]::FromArgb(24,24,24))
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 for($j=0;$j -lt $items.Count;$j++){
  $im=[System.Drawing.Image]::FromFile($items[$j].FullName)
  $x=($j%3)*640; $y=[math]::Floor($j/3)*392
  $g.DrawImage($im,[int]$x,[int]$y,640,360)
  $g.DrawString($items[$j].BaseName,$font,[System.Drawing.Brushes]::White,[single]($x+8),[single]($y+364))
  $manifest+=[pscustomobject]@{File=$items[$j].Name;Width=$im.Width;Height=$im.Height;Bytes=$items[$j].Length;SHA256=(Get-FileHash -LiteralPath $items[$j].FullName -Algorithm SHA256).Hash;Method='Frame.io Download Still / 2160p';Fps=24}
  $im.Dispose()
 }
 $page=[int]($start/12)+1
 $canvas.Save((Join-Path $root "Apercus\Sources\${Subject}_planche_$page.jpg"),[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $g.Dispose();$canvas.Dispose()
}
$font.Dispose()
$manifest | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $PSScriptRoot "${Subject}_manifest.csv")
$manifest | Group-Object Width,Height | Select-Object Count,Name
