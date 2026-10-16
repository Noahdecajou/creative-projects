$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V05_Natural_Set'
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants_V05_source.json') -Raw|ConvertFrom-Json
$before=Join-Path $root 'apercus/avant_V05'
New-Item -ItemType Directory -Force -Path $before|Out-Null
foreach($r in $rows){Copy-Item -LiteralPath (Join-Path $base ('apercus/Sampsa_'+$r.id+'_1280.jpg')) -Destination $before}
$html=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'gallery-template.html') -Raw
$html.Replace('__VARIANTS__',($rows|ConvertTo-Json -Depth 6 -Compress))|Set-Content -LiteralPath (Join-Path $root 'Galerie.html') -Encoding utf8
$rows|Select-Object id,refId,title,evidence,source,rizSource,@{n='Status';e={'V06 branding applied'}}|Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'Suivi_titres.tsv') -Delimiter "`t" -NoTypeInformation -Encoding utf8
# Face crops include a margin around each preserved area for visual seam checking.
$regions=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Preservation_regions.json') -Raw|ConvertFrom-Json -AsHashtable
$items=@();foreach($r in $rows){$n=0;foreach($f in $regions[$r.id].faces){$n++;$items+=[pscustomobject]@{Id=$r.id;N=$n;Rect=$f}}}
for($page=0;$page-lt[math]::Ceiling($items.Count/9);$page++){
 $sheet=[Drawing.Bitmap]::new(1240,1330);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(21,17,24));$g.InterpolationMode='HighQualityBicubic';$g.TextRenderingHint='AntiAliasGridFit';$font=[Drawing.Font]::new('Arial',17,[Drawing.FontStyle]::Bold)
 $part=@($items|Select-Object -Skip ($page*9) -First 9)
 for($j=0;$j-lt$part.Count;$j++){$p=$part[$j];$im=[Drawing.Bitmap]::new((Join-Path $root ('masters/Sampsa_'+$p.Id+'.png')));$f=$p.Rect;$x=10+($j%3)*410;$y=10+[math]::Floor($j/3)*440;$rx=[math]::Max(0,$f[0]-35);$ry=[math]::Max(0,$f[1]-35);$rw=[math]::Min($im.Width-$rx,$f[2]+70);$rh=[math]::Min($im.Height-$ry,$f[3]+70);$scale=[math]::Min(390/$rw,390/$rh);$dw=[int]($rw*$scale);$dh=[int]($rh*$scale);$g.DrawImage($im,[Drawing.Rectangle]::new([int]($x+(390-$dw)/2),[int]$y,$dw,$dh),[Drawing.Rectangle]::new($rx,$ry,$rw,$rh),[Drawing.GraphicsUnit]::Pixel);$im.Dispose();$g.DrawString(($p.Id+' / '+$p.N),$font,[Drawing.Brushes]::White,[float]$x,[float]($y+397))}
 $font.Dispose();$g.Dispose();$sheet.Save((Join-Path $root ('apercus/Controle_visages_'+($page+1)+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
}
$manifest=@();foreach($file in Get-ChildItem -LiteralPath (Join-Path $root 'sources_HD') -File -Recurse){$im=[Drawing.Image]::FromFile($file.FullName);$manifest+=[pscustomobject]@{File=[IO.Path]::GetRelativePath($root,$file.FullName);Width=$im.Width;Height=$im.Height;SHA256=(Get-FileHash -LiteralPath $file.FullName).Hash};$im.Dispose()}
$manifest|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Sources_manifest.json') -Encoding utf8
Write-Output ('Gallery, title tracking, '+$items.Count+' face checks and '+$manifest.Count+' source records ready.')
