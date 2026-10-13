param([string]$Subject='Riz',[int[]]$Minutes=@(),[int[]]$Seconds=@(),[int]$Fps=24)
Add-Type -AssemblyName System.Drawing
$root=$PSScriptRoot
$src=Join-Path $root "Sources_HD\$Subject"
New-Item -ItemType Directory -Force -Path $src | Out-Null
$manifest=@()
$allSeconds=@($Seconds)+@($Minutes | ForEach-Object {$_*60})
foreach($sec in $allSeconds){
 $frame=$sec*$Fps
 $pattern='^frame_'+$frame+'(?: \(\d+\))?\.jpg$'
 $file=Get-ChildItem -LiteralPath 'C:\Users\notti\Downloads' -Filter 'frame_*.jpg' | Where-Object {$_.Name -match $pattern} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
 if(!$file){continue}
 $tc='{0:00}-{1:00}-{2:00}' -f [math]::Floor($sec/3600),([math]::Floor($sec/60)%60),($sec%60)
 $dest=Join-Path $src ($Subject+'_'+$tc+'.jpg')
 Copy-Item -LiteralPath $file.FullName -Destination $dest
}
$files=@(Get-ChildItem -LiteralPath $src -Filter '*.jpg' | Sort-Object Name)
$font=New-Object System.Drawing.Font('Arial',15)
$brush=[System.Drawing.Brushes]::White
for($start=0;$start -lt $files.Count;$start+=20){
 $items=@($files | Select-Object -Skip $start -First 20)
 $rows=[math]::Ceiling($items.Count/4)
 $canvas=New-Object System.Drawing.Bitmap(1920,([int]($rows*300)))
 $g=[System.Drawing.Graphics]::FromImage($canvas)
 $g.Clear([System.Drawing.Color]::FromArgb(24,24,24))
 $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
 for($j=0;$j -lt $items.Count;$j++){
  $im=[System.Drawing.Image]::FromFile($items[$j].FullName)
  $x=($j%4)*480; $y=[math]::Floor($j/4)*300
  $g.DrawImage($im,[int]$x,[int]$y,480,270)
  $g.DrawString($items[$j].BaseName,$font,$brush,[single]($x+8),[single]($y+274))
  $manifest+=[pscustomobject]@{File=$items[$j].Name;Width=$im.Width;Height=$im.Height;Bytes=$items[$j].Length}
  $im.Dispose()
 }
 $page=[int]($start/20)+1
 $canvas.Save((Join-Path $root "Apercus\${Subject}_planche_$page.jpg"),[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $g.Dispose();$canvas.Dispose()
}
$font.Dispose()
$manifest | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $root "Suivi\${Subject}_manifest.csv")
$manifest | Group-Object Width,Height | Select-Object Count,Name
Write-Output "Files: $($files.Count)"
