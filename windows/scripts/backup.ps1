function New-Subdir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subpath
    )

    New-Item -Force -Type Directory -Path (Join-Path "$PSScriptRoot\..\" $Subpath)
}

Copy-Item "$env:USERPROFILE\.config\yasb\*" -Destination (New-Subdir "yasb") -Recurse -Force -Exclude "yasb.log"
Copy-Item "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Destination (New-Subdir "powershell") -Force
Copy-Item "$env:USERPROFILE\.config\fastfetch\*" -Destination (New-Subdir "fastfetch") -Recurse -Force

$latestPowerToysBackup = Get-ChildItem -Path "$env:USERPROFILE\Documents\PowerToys\Backup" -Filter "*.ptb" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestPowerToysBackup) {
    Copy-Item $latestPowerToysBackup.FullName -Destination (New-Subdir "powertoys") -Force
} else {
    Write-Host "No PowerToys backup file found." -ForegroundColor Yellow
}