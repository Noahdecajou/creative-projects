$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$base=Split-Path $PSScriptRoot -Parent
$native=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'native_exports.json') -Raw | ConvertFrom-Json
$picks=@(
    @{Id=1;Subject='Razvan';Expression='Explication, geste de la main'},
    @{Id=3;Subject='Animateur';Expression='Interrogatif, sourcil releve'},
    @{Id=4;Subject='Animateur';Expression='Attentif, regard lateral'},
    @{Id=5;Subject='Animateur';Expression='Question, mains ouvertes'},
    @{Id=11;Subject='Razvan';Expression='Explication animee, regard lateral'},
    @{Id=13;Subject='Razvan';Expression='Explication face camera'},
    @{Id=16;Subject='Razvan';Expression='Neutre et pose; portrait principal V01'},
    @{Id=17;Subject='Animateur';Expression='Attentif, regard vers invite'},
    @{Id=20;Subject='Razvan';Expression='Intense, regard lateral'},
    @{Id=25;Subject='Animateur';Expression='Serieux, en discussion'},
    @{Id=26;Subject='Razvan';Expression='Attentif, ecoute'},
    @{Id=49;Subject='Animateur';Expression='Ecoute, regard lateral'},
    @{Id=51;Subject='Animateur';Expression='Adresse directe au public'},
    @{Id=52;Subject='Razvan';Expression='Serieux, explication calme'},
    @{Id=59;Subject='Razvan';Expression='Alerte, regard vers camera'},
    @{Id=65;Subject='Razvan';Expression='Concentre, regard direct'},
    @{Id=68;Subject='Razvan';Expression='Explication de trois-quarts'},
    @{Id=69;Subject='Razvan';Expression='Explication, mains reunies'},
    @{Id=70;Subject='Razvan';Expression='Attentif, visage detendu'},
    @{Id=72;Subject='Razvan';Expression='Explication animee'},
    @{Id=73;Subject='Razvan';Expression='Explication frontale, stylo'},
    @{Id=75;Subject='Razvan';Expression='Neutre professionnel, regard lateral'},
    @{Id=78;Subject='Razvan';Expression='Conversation, regard vers animateur'},
    @{Id=19;Subject='Tableau';Expression='Niveaux cles; source du fond V01'},
    @{Id=64;Subject='Tableau';Expression='Schema de retournement et inversion'},
    @{Id=30;Subject='Graphique';Expression='Exemple Nasdaq commente dans episode'}
)
$inventory=@()
for($i=0;$i -lt $picks.Count;$i++) {
    $pick=$picks[$i]
    if($pick.Id -in @(69,73,78)){continue}
    $source=$native | Where-Object Number -eq $pick.Id
    $file='{0}_{1:00}_{2}.jpg' -f $pick.Subject,($i+1),$source.Timecode.Replace(':','-')
    $dest=Join-Path (Join-Path $base 'sources_HD') $file
    Copy-Item -LiteralPath $source.Path -Destination $dest
    $originalHash=(Get-FileHash -LiteralPath $source.Path -Algorithm SHA256).Hash
    $copyHash=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
    if($originalHash -ne $copyHash){throw 'Native source copy changed'}
    $inventory += [pscustomobject]@{Numero=$i+1;Sujet=$pick.Subject;Timecode=$source.Timecode;Expression=$pick.Expression;Largeur=3840;Hauteur=2160;Fichier=$file;ReperageId=$pick.Id;SHA256=$copyHash}
}
$inventory | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $base 'inventaire_sources.json') -Encoding utf8
$lines=@('PROP FIRM TRADER - RAZVAN - INVENTAIRE DES SOURCES','JPEG natifs issus de Viewer Settings > Download Still. 3840 x 2160. Aucune recompression ni retouche.','')
foreach($item in $inventory){$lines += ('{0:00} | {1} | {2} | {3} | 3840 x 2160 | {4}' -f $item.Numero,$item.Sujet,$item.Timecode,$item.Expression,$item.Fichier)}
$lines | Set-Content -LiteralPath (Join-Path $base 'inventaire_sources.txt') -Encoding utf8
$font=New-Object System.Drawing.Font('Arial',18,[System.Drawing.FontStyle]::Bold)
for($page=0;$page -lt [Math]::Ceiling($inventory.Count/9);$page++) {
    $count=[Math]::Min(9,$inventory.Count-$page*9);$rows=[Math]::Ceiling($count/3)
    $sheet=New-Object System.Drawing.Bitmap(1920,[int]($rows*420));$g=[System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::FromArgb(20,22,26));$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for($j=0;$j -lt $count;$j++) {
        $item=$inventory[$page*9+$j];$x=($j%3)*640;$y=[Math]::Floor($j/3)*420
        $im=[System.Drawing.Image]::FromFile((Join-Path (Join-Path $base 'sources_HD') $item.Fichier))
        $g.DrawImage($im,[int]$x,[int]$y,640,360)
        $g.DrawString(('{0:00}  {1}  {2}' -f $item.Numero,$item.Sujet,$item.Timecode),$font,[System.Drawing.Brushes]::White,[single]($x+10),[single]($y+362))
        $im.Dispose()
    }
    $sheet.Save((Join-Path (Join-Path $base 'apercus') ('Sources_selection_{0:00}.jpg' -f ($page+1))),[System.Drawing.Imaging.ImageFormat]::Jpeg)
    $g.Dispose();$sheet.Dispose()
}
for($page=0;$page -lt 5;$page++) {
    $count=[Math]::Min(4,20-$page*4);$sheet=New-Object System.Drawing.Bitmap(1600,1320);$g=[System.Drawing.Graphics]::FromImage($sheet)
    $g.Clear([System.Drawing.Color]::Black);$g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for($j=0;$j -lt $count;$j++) {
        $item=$inventory[$page*4+$j];$x=($j%2)*800;$y=[Math]::Floor($j/2)*660
        $im=[System.Drawing.Image]::FromFile((Join-Path (Join-Path $base 'sources_HD') $item.Fichier))
        $dest=New-Object System.Drawing.Rectangle([int]$x,[int]$y,800,630)
        $g.DrawImage($im,$dest,[single]768,[single]65,[single]1920,[single]1512,[System.Drawing.GraphicsUnit]::Pixel)
        $g.DrawString(('{0:00} {1}' -f $item.Numero,$item.Timecode),$font,[System.Drawing.Brushes]::White,[single]($x+12),[single]($y+630))
        $im.Dispose()
    }
    $sheet.Save((Join-Path $PSScriptRoot ('QA_portraits_{0:00}.jpg' -f ($page+1))),[System.Drawing.Imaging.ImageFormat]::Jpeg)
    $g.Dispose();$sheet.Dispose()
}
$font.Dispose()
$masterName='Razvan_158K_2Weeks_v01_master_1672x941.png'
$master=Join-Path (Join-Path $base 'masters') $masterName
Copy-Item -LiteralPath 'C:\Users\notti\.codex\generated_images\01a1162b-f49a-7aa0-9e3d-7c951c66d9f5\exec-6ab33dd0-917c-4ab9-b163-dddab9962f0f.png' -Destination $master
$im=[System.Drawing.Image]::FromFile($master)
foreach($spec in @(@{W=3840;H=2160;File='exports_4K\Razvan_158K_2Weeks_v01_3840x2160.png'},@{W=1280;H=720;File='apercus\Razvan_158K_2Weeks_v01_preview.png'},@{W=320;H=180;File='apercus\Razvan_v01_mobile_320x180.png'})) {
    $bmp=New-Object System.Drawing.Bitmap($spec.W,$spec.H)
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $attributes=New-Object System.Drawing.Imaging.ImageAttributes
    $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $rect=New-Object System.Drawing.Rectangle(0,0,$spec.W,$spec.H)
    $g.DrawImage($im,$rect,[single]0,[single]0.25,[single]1672,[single]940.5,[System.Drawing.GraphicsUnit]::Pixel,$attributes)
    $bmp.Save((Join-Path $base $spec.File),[System.Drawing.Imaging.ImageFormat]::Png)
    $attributes.Dispose();$g.Dispose();$bmp.Dispose()
}
$im.Dispose()
[pscustomobject]@{Sources=$inventory.Count;Portraits=20;Contextes=3;Master='1672x941';Export='3840x2160';Method='HighQualityBicubic; recadrage vertical 0.5px pour ratio exact 16:9'} | ConvertTo-Json
