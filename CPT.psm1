$modulePath = $PSScriptRoot
Get-ChildItem -Recurse -Path $modulePath\*.ps1 | ForEach-Object { . $_.FullName }
write-host "$($splash[0])" -foregroundcolor red
write-host "$($splash[1])" -foregroundcolor magenta