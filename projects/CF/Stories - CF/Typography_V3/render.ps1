Add-Type -AssemblyName System.Drawing
$runtimePath = Split-Path ([System.Drawing.Bitmap].Assembly.Location)
Add-Type -Path (Join-Path $PSScriptRoot 'render.cs') -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location,[System.Drawing.Point].Assembly.Location,(Join-Path $runtimePath 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtimePath 'System.Private.Windows.Core.dll'),'System.Runtime','System.Runtime.InteropServices')
[PoppinsStories]::Render((Split-Path $PSScriptRoot))
Write-Output 'Poppins Regular and Bold typeset.'
