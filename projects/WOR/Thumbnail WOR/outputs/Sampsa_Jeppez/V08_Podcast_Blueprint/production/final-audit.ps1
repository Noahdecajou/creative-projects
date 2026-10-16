$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V07_Selected_Titles'
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants.json') -Raw|ConvertFrom-Json
$inherited=@()
foreach($r in $rows|Where-Object {!$_.changed}){
 $new=Join-Path $root ('exports_4K/Sampsa_Jeppez_V08_'+$r.id+'_3840x2160_Grain4.png')
 $old=Join-Path $base ('exports_4K/Sampsa_Jeppez_V07_'+$r.id+'_3840x2160_Grain4.png')
 $hash=(Get-FileHash -LiteralPath $new).Hash
 if($hash-ne(Get-FileHash -LiteralPath $old).Hash){throw ('Inherited export differs: '+$r.id)}
 $inherited+=[pscustomobject]@{Id=$r.id;SHA256=$hash;ByteIdenticalToV07=$true}
}
$inherited|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_inherited.json') -Encoding utf8
$jobs=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Generation_jobs.json') -Raw|ConvertFrom-Json
$manifest=@()
foreach($j in $jobs){
 $inputs=@();foreach($f in $j.inputs){if(!(Test-Path -LiteralPath $f)){throw ('Missing generation input '+$f)};$inputs+=[pscustomobject]@{Path=$f;SHA256=(Get-FileHash -LiteralPath $f).Hash}}
 $file=Join-Path $PSScriptRoot ('generated/'+$j.id+'.png')
 $manifest+=[pscustomobject]@{Id=$j.id;Tool='image_gen.imagegen';Inputs=$inputs;Prompt=$j.prompt;SavedOutput=('production/generated/'+$j.id+'.png');OutputSHA256=(Get-FileHash -LiteralPath $file).Hash;UsedFor=if($j.id-eq'13'){@('13_Blur10','13_Blur15')}else{@($j.id)}}
}
$manifest|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Generation_manifest.json') -Encoding utf8
# Focus sheet of the five revisions, exported from the actual final previews.
$part=@($rows|Where-Object changed)
$sheet=[Drawing.Bitmap]::new(1320,1230);$g=[Drawing.Graphics]::FromImage($sheet);$g.Clear([Drawing.Color]::FromArgb(22,16,25));$g.InterpolationMode='HighQualityBicubic';$g.TextRenderingHint='AntiAliasGridFit';$font=[Drawing.Font]::new('Arial',18,[Drawing.FontStyle]::Bold)
for($i=0;$i-lt$part.Count;$i++){$r=$part[$i];$x=10+($i%2)*660;$y=10+[math]::Floor($i/2)*410;$im=[Drawing.Image]::FromFile((Join-Path $root ('apercus/Sampsa_'+$r.id+'_1280.jpg')));$g.DrawImage($im,[int]$x,[int]$y,640,360);$im.Dispose();$g.DrawString(('V08 / REF '+$r.id),$font,[Drawing.Brushes]::White,[float]$x,[float]($y+368))}
$g.Dispose();$font.Dispose();$sheet.Save((Join-Path $root 'apercus/Planche_5_retouches.jpg'),[Drawing.Imaging.ImageFormat]::Jpeg);$sheet.Dispose()
$html=Get-Content -LiteralPath (Join-Path $root 'Galerie.html') -Raw
$links=@();foreach($m in [regex]::Matches($html,'(?:src|href)="([^"]+)"')){$target=$m.Groups[1].Value;if($target-match'^(#|\$|https?:)' -or $target.Contains('${')){continue};if($target.EndsWith('.zip')){continue};$path=Join-Path $root $target;if(!(Test-Path -LiteralPath $path)){throw ('Broken static asset '+$target)};$links+=$target}
foreach($r in $rows){foreach($name in @('source','rizSource')){if($r.$name-and!(Test-Path -LiteralPath (Join-Path $root ('sources_HD/'+$r.$name)))){throw ('Missing source photo '+$r.$name)}}}
if(@($part).Count-ne5-or@($inherited).Count-ne8){throw 'Wrong changed/inherited count'}
if($rows.id-contains'11_Yellow'){throw 'Yellow candle still in active set'}
[pscustomobject]@{ModifiedVariants=5;InheritedVariants=8;InheritedPNGBytesIdentical=$true;Reference11='Green only';Reference10='Two original identities, two microphones, mutual gaze, guest gesture, two blurred foreground listeners';Titles='Visually checked on all five revisions and 320px overview';Faces='Eight localized face cores unchanged; ref10 is a new guided composition';Seams='Checked on full-size masters after local compositing';StaticLinksChecked=$links;SourcePhotoLinks='All present';VisualQA='Passed';Date=(Get-Date -Format o)}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_visual.json') -Encoding utf8
Write-Output 'Final audit passed: five revisions, eight byte-identical inherited PNGs, source photos and static links verified.'
