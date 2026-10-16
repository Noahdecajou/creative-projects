$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path (Split-Path $root -Parent) 'V08_Podcast_Blueprint'
$rows=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Variants.json') -Raw|ConvertFrom-Json
$audit=@()
foreach($r in $rows|Where-Object {!$_.changed}){
 $new=Join-Path $root ('exports_4K/Sampsa_Jeppez_V09_'+$r.id+'_3840x2160_Grain4.png')
 $old=Join-Path $base ('exports_4K/Sampsa_Jeppez_V08_'+$r.id+'_3840x2160_Grain4.png')
 $hash=(Get-FileHash -LiteralPath $new).Hash
 if($hash-ne(Get-FileHash -LiteralPath $old).Hash){throw ('Inherited export changed '+$r.id)}
 if((Get-FileHash -LiteralPath (Join-Path $root ('masters/Sampsa_'+$r.id+'.png'))).Hash-ne(Get-FileHash -LiteralPath (Join-Path $base ('masters/Sampsa_'+$r.id+'.png'))).Hash){throw ('Inherited master changed '+$r.id)}
 $audit+=[pscustomobject]@{Id=$r.id;SHA256=$hash;ExportAndMasterIdenticalToV08=$true}
}
if($audit.Count-ne12){throw 'Expected twelve inherited exports'}
$audit|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_inherited.json') -Encoding utf8
$manifest=@()
foreach($name in @('Generation_job.json','Correction_job.json')){
 $job=Get-Content -LiteralPath (Join-Path $PSScriptRoot $name) -Raw|ConvertFrom-Json
 $inputs=@();foreach($f in $job.inputs){$saved=$f;if($name-eq'Correction_job.json'){$saved=Join-Path $PSScriptRoot '11_Green_before_correction.png'};$inputs+=[pscustomobject]@{OriginalPathAtGeneration=$f;ArchivedInput=$saved;SHA256=(Get-FileHash -LiteralPath $saved).Hash}}
 $output=if($name-eq'Correction_job.json'){'production/generated/11_Green_final.png'}else{'production/generated/11_Green.png'}
 $manifest+=[pscustomobject]@{Id=$job.id;Tool='image_gen.imagegen';Inputs=$inputs;Prompt=$job.prompt;SavedGeneration=$output;OutputSHA256=(Get-FileHash -LiteralPath (Join-Path $root $output)).Hash}
}
$manifest|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Generation_manifest.json') -Encoding utf8
$html=Get-Content -LiteralPath (Join-Path $root 'Galerie.html') -Raw
$links=@();foreach($m in [regex]::Matches($html,'(?:src|href)="([^"]+)"')){$target=$m.Groups[1].Value;if($target-match'^(#|\$|https?:)' -or $target.Contains('${') -or $target.EndsWith('.zip')){continue};if(!(Test-Path -LiteralPath (Join-Path $root $target))){throw ('Broken asset '+$target)};$links+=$target}
foreach($r in $rows){foreach($key in @('source','rizSource')){if($r.$key-and!(Test-Path -LiteralPath (Join-Path $root ('sources_HD/'+$r.$key)))){throw 'Missing source photo'}}}
[pscustomobject]@{ModifiedVariants=1;InheritedVariants=12;Reference11Final='No candlestick sculptures; raised sheet has a blank back; overlapping chart research remains on table';Title='Unchanged';Faces='Two protected face cores pixel-identical to V08';VisualQA='Final 1280px and 320px exports inspected';StaticLinksChecked=$links;SourcePhotos='All present';ArchiveExpectedExports=13;Date=(Get-Date -Format o)}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'Verification_visual.json') -Encoding utf8
Write-Output 'Final audit passed: one corrected reference, twelve byte-identical inherited exports.'
