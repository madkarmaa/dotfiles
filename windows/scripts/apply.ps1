param (
    [Parameter(Position = 0)]
    [ValidateSet("yasb", "powershell", "fastfetch", "all")]
    [string]$Feature = "all"
)

function New-DestDir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    New-Item -Force -Type Directory -Path $Path | Out-Null
}

function Apply-Yasb {
    Write-Host "Applying yasb configuration..."
    Copy-Item "$PSScriptRoot\..\yasb\*" -Destination (New-DestDir "$env:USERPROFILE\.config\yasb") -Recurse -Force
    Write-Host "✅ yasb applied" -ForegroundColor Green
}

function Apply-PowerShell {
    Write-Host "Applying PowerShell profile..."
    Copy-Item "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\PowerShell") -Force
    Copy-Item "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\WindowsPowerShell") -Force
    Write-Host "✅ PowerShell profile applied" -ForegroundColor Green
}

function Apply-Fastfetch {
    Write-Host "Applying fastfetch configuration..."
    Copy-Item "$PSScriptRoot\..\fastfetch\*" -Destination (New-DestDir "$env:USERPROFILE\.config\fastfetch") -Recurse -Force
    Write-Host "✅ fastfetch applied" -ForegroundColor Green
}

switch ($Feature) {
    "yasb" { Apply-Yasb }
    "powershell" { Apply-PowerShell }
    "fastfetch" { Apply-Fastfetch }
    "all" {
        Apply-Yasb
        Apply-PowerShell
        Apply-Fastfetch
        Write-Host "`nAll configurations applied successfully!" -ForegroundColor Green
    }
}
