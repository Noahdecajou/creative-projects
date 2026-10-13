param([string]$Subject='Sampsa')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$rows=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot ('Capture_'+$Subject+'.json')) | ConvertFrom-Json
$dest=Join-Path $root ('production\candidates\'+$Subject)
New-Item -ItemType Directory -Path $dest -Force | Out-Null
$report=@()
foreach($r in $rows){
 $name=$r.subject+'_'+$r.tc.Replace(':','-')+'.jpg'
 $path=Join-Path $dest $name
 Copy-Item -LiteralPath $r.download -Destination $path -Force
 $im=[Drawing.Image]::FromFile($path)
 $report += [pscustomobject]@{Subject=$Subject;Timecode=$r.tc;File=$name;Width=$im.Width;Height=$im.Height;SHA256=(Get-FileHash -LiteralPath $path).Hash}
 $im.Dispose()
}
for($page=0;$page-lt[math]::Ceiling($rows.Count/20.0);$page++){
 $part=@($report | Select-Object -Skip ($page*20) -First 20)
 $sheet=[Drawing.Bitmap]::new(1640,1340)
 $g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(22,25,30));$g.InterpolationMode='HighQualityBicubic';$g.TextRenderingHint='AntiAliasGridFit'
 $font=[Drawing.Font]::new('Arial',17,[Drawing.FontStyle]::Bold)
 for($j=0;$j-lt$part.Count;$j++){
  $r=$part[$j];$x=10+($j%4)*410;$y=10+[math]::Floor($j/4)*264
  $im=[Drawing.Image]::FromFile((Join-Path $dest $r.File));$g.DrawImage($im,[int]$x,[int]$y,400,225);$im.Dispose()
  $g.DrawString($r.Timecode,$font,[Drawing.Brushes]::White,[float]$x,[float]($y+229))
 }
 $font.Dispose();$g.Dispose();$sheet.Save((Join-Path $root ('apercus\Sources_'+$Subject+'_'+($page+1)+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot ('Sources_'+$Subject+'_verified.json')) -Encoding utf8
Write-Output ($Subject+': '+$report.Count+' native stills verified and contact sheets created.')
