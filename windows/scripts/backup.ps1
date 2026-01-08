function New-Subdir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subpath
    )

    New-Item -Force -Type Directory -Path (Join-Path "$PSScriptRoot\windows" $Subpath)
}

Copy-Item "$env:USERPROFILE\.config\yasb\*" -Destination (New-Subdir "yasb") -Recurse -Force -Exclude "yasb.log"
Copy-Item "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Destination (New-Subdir "powershell") -Force
Copy-Item "$env:USERPROFILE\.config\fastfetch\*" -Destination (New-Subdir "fastfetch") -Recurse -Force