$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot)
$records=@()
foreach($section in @('Exports','Masters','Apercus')){
 foreach($id in @(3,5,6,7,8)){
  $prefix=('{0:00}' -f $id)+'_'
  foreach($f in (Get-ChildItem -LiteralPath (Join-Path $root ($section+'\V08')) -File | Where-Object {$_.Name.StartsWith($prefix)})){
   $new=Join-Path (Join-Path $root ($section+'\V09')) $f.Name
   $same=(Get-FileHash -LiteralPath $f.FullName).Hash -eq (Get-FileHash -LiteralPath $new).Hash
   if(-not $same){throw ('Unexpected change: '+$new)}
   $records+=[pscustomobject]@{Section=$section;File=$f.Name;IdenticalToV08=$true}
  }
 }
}
foreach($name in @('Imre_direct_camera.png','Riz_original_cutout.png')){
 $old=Join-Path (Join-Path $root 'Masters\V08') $name
 $new=Join-Path (Join-Path $root 'Masters\V09') $name
 if((Get-FileHash -LiteralPath $old).Hash -ne (Get-FileHash -LiteralPath $new).Hash){throw ('Portrait asset changed: '+$name)}
 $records+=[pscustomobject]@{Section='Portrait source';File=$name;IdenticalToV08=$true}
}
$records | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $PSScriptRoot 'Preservation_V08_V09.csv')
$oldGeometry=Import-Csv -LiteralPath (Join-Path (Split-Path $PSScriptRoot) 'V08\Typography_geometry.csv')
$newGeometry=Import-Csv -LiteralPath (Join-Path $PSScriptRoot 'Typography_geometry.csv')
$diff=Compare-Object $oldGeometry $newGeometry -Property Image,Text,X,Y,Width,Height,Font,Weight
if($diff){$diff | Format-Table;throw 'Typography geometry changed'}
Write-Output ('VERIFIED: '+$records.Count+' inherited files/assets identical; all typography geometry unchanged.')


