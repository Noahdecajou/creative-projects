$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path (Split-Path $PSScriptRoot)
$checks=[System.Collections.Generic.List[object]]::new()
function Check($name,$pass,$detail){
 $checks.Add([pscustomobject]@{Check=$name;Passed=[bool]$pass;Detail=$detail})
 if(-not $pass){throw ($name+': '+$detail)}
}
function SameHash($a,$b){return (Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $b -Algorithm SHA256).Hash}
function Num($s){return [double]::Parse($s.Replace(',','.'),[System.Globalization.CultureInfo]::InvariantCulture)}
$exports=@(Get-ChildItem -LiteralPath (Join-Path $root 'Exports/V12') -Filter '*.png' -File | Sort-Object Name)
Check 'Complete pack' ($exports.Count -eq 8) 'Eight PNG exports'
foreach($file in $exports){
 $image=[System.Drawing.Image]::FromFile($file.FullName)
 Check ($file.Name+' dimensions') ($image.Width -eq 3840 -and $image.Height -eq 2160) '3840 x 2160'
 $image.Dispose()
 $master=Join-Path (Join-Path $root 'Masters/V12') ($file.Name.Replace('_3840x2160','_master'))
 Check ($file.Name+' no added export grain') (SameHash $file.FullName $master) 'Export and clean master are byte-identical'
 if(-not $file.Name.StartsWith('08_')){
  Check ($file.Name+' revised') (-not (SameHash $file.FullName (Join-Path (Join-Path $root 'Exports/V10') $file.Name))) 'Revised rendering differs from V10'
 }
}
foreach($name in @('03_plate.png','05_plate.png','07_plate.png','Imre_direct_camera.png','Riz_original_cutout.png')){
 Check ($name+' source preservation') (SameHash (Join-Path (Join-Path $root 'Masters/V10') $name) (Join-Path (Join-Path $root 'Masters/V12') $name)) 'Source geometry retained; tonal finish applied only in memory'
}
Check 'Approved 08 export retained' (SameHash (Join-Path $root 'Exports/V11_Test08/08_Price_To_Value_V11_Test_Sans_Grain_3840x2160.png') (Join-Path $root 'Exports/V12/08_Price_To_Value_3840x2160.png')) 'Exact approved V11 test'
Check 'Approved 08 master retained' (SameHash (Join-Path $root 'Masters/V11_Test08/08_Price_To_Value_master.png') (Join-Path $root 'Masters/V12/08_Price_To_Value_master.png')) 'Exact approved master'
foreach($size in @(1280,640,320)){
 Check ('Approved 08 preview '+$size) (SameHash (Join-Path $root ('Apercus/V11_Test08/08_'+$size+'.jpg')) (Join-Path $root ('Apercus/V12/08_'+$size+'.jpg'))) 'Exact approved preview'
 foreach($id in 1..8){Check ('Preview '+$id+' at '+$size) (Test-Path -LiteralPath (Join-Path $root ('Apercus/V12/'+('{0:00}' -f $id)+'_'+$size+'.jpg'))) 'Preview exists'}
}
$old=Import-Csv -LiteralPath (Join-Path $root 'Suivi/V10/Typography_geometry.csv')
$current=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Typography_geometry.csv')
$diff=Compare-Object @($old | Where-Object {[int]$_.Image -le 7}) $current -Property Image,Text
Check 'English copy retained 01-07' (-not $diff) 'All existing wording retained'
$diff=Compare-Object @($old | Where-Object {[int]$_.Image -le 6}) @($current | Where-Object {[int]$_.Image -le 6}) -Property Image,Text,X,Y,Width,Height,Font,Weight
Check 'Typography layout 01-06 retained' (-not $diff) 'Approved compact title spacing retained'
$approvedText=Import-Csv -LiteralPath (Join-Path $root 'Suivi/V11_Test08/Typography_geometry.csv')
$allText=@($current)+@($approvedText | Select-Object @{n='Image';e={'08'}},Text,X,Y,Width,Height,Font,@{n='Weight';e={'See V11_Test08 source'}})
$allText | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Typography_all_eight.csv')
foreach($entry in $allText){
 $valid=(Num $entry.X) -ge 0 -and (Num $entry.Y) -ge 0 -and ((Num $entry.X)+(Num $entry.Width)) -le 1280 -and ((Num $entry.Y)+(Num $entry.Height)) -le 720
 Check ('Text bounds '+$entry.Image+' '+$entry.Text) $valid 'All text ink within 1280 x 720 logical canvas'
}
$arrows=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Arrow_geometry.csv')
Check 'Arrows rebuilt 01-07' ($arrows.Count -eq 16 -and @($arrows | Where-Object IntegratedTip -ne 'True').Count -eq 0) '16 single silhouettes with integrated pointed heads'
foreach($arrow in $arrows){
 $valid=(Num $arrow.BoundsX) -ge 0 -and (Num $arrow.BoundsY) -ge 0 -and ((Num $arrow.BoundsX)+(Num $arrow.BoundsWidth)) -le 1280 -and ((Num $arrow.BoundsY)+(Num $arrow.BoundsHeight)) -le 720
 Check ('Arrow bounds '+$arrow.Image+' '+$arrow.TipX+','+$arrow.TipY) $valid 'Arrow inside canvas'
}
$fair=$arrows | Where-Object {$_.Image -eq '06' -and $_.TipX -eq '328'}
Check '06 fair value arrow clearance' (((Num $fair.BoundsX)-315) -ge 13) '13 logical pixels clear of the yellow volume bar'
$step=$arrows | Where-Object {$_.Image -eq '05' -and $_.StartY -eq '601'}
Check '05 step arrow clearance' (((Num $step.BoundsY)-585) -gt 14) 'More than 14 logical pixels below STEP BY STEP box'
$checks | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Verification_artwork_V12.csv')
Write-Output ('VERIFIED: '+$checks.Count+' checks passed; eight exports; approved 08 exact; five source assets exact; all copy and arrow bounds verified.')
