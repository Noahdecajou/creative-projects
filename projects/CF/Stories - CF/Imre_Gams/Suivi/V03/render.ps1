$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -Path (Join-Path $PSScriptRoot 'render.cs') -ReferencedAssemblies System.Drawing,System.Core
[ImreNaturalStories]::Render((Split-Path (Split-Path $PSScriptRoot)), 'C:\Users\notti\Documents\ChatGPT\Stories - CF\Typography_V3\Fonts\Poppins-Bold.ttf')
