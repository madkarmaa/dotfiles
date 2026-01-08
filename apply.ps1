function New-DestDir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    New-Item -Force -Type Directory -Path $Path
}

Copy-Item "$PSScriptRoot\windows\yasb\*" -Destination (New-DestDir "$env:USERPROFILE\.config\yasb") -Recurse -Force
Copy-Item "$PSScriptRoot\windows\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\PowerShell") -Force
Copy-Item "$PSScriptRoot\windows\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\WindowsPowerShell") -Force
Copy-Item "$PSScriptRoot\windows\fastfetch\*" -Destination (New-DestDir "$env:USERPROFILE\.config\fastfetch") -Recurse -Force
