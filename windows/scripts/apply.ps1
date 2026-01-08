param (
    [Parameter(Position = 0)]
    [ValidateSet("yasb", "powershell", "fastfetch", "all")]
    [string]$Feature = "all"
)

$TASK_TEMPLATE = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
    <Triggers>
        <LogonTrigger>
            <UserId>{{user}}</UserId>
        </LogonTrigger>
    </Triggers>
    <Principals>
        <Principal>
            <UserId>{{user}}</UserId>
            <RunLevel>HighestAvailable</RunLevel>
        </Principal>
    </Principals>
    <Settings>
        <AllowStartOnDemand>true</AllowStartOnDemand>
        <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
        <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
        <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
        <Enabled>true</Enabled>
        <Hidden>false</Hidden>
    </Settings>
    <Actions>
        <Exec>
            <Command>cmd.exe</Command>
            <Arguments>/c start "" /high "C:\Program Files\YASB\yasb.exe"</Arguments>
        </Exec>
    </Actions>
</Task>
"@

function New-DestDir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $dir = New-Item -Force -Type Directory -Path $Path
    return $dir.FullName
}

function TaskbarAutoHide {
    param (
        [Parameter(Mandatory)]
        [bool]$Enable
    )

    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    $data = (Get-ItemProperty -Path $path -Name Settings).Settings

    # byte 8: 0x03 = enabled, 0x02 = disabled
    $data[8] = if ($Enable) { 0x03 } else { 0x02 }

    Set-ItemProperty -Path $path -Name Settings -Value $data

    # restart explorer to apply the registry changes
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
}

function ApplyYasb {
    Write-Host "Applying yasb configuration..."

    $user = "$env:USERDOMAIN\$env:USERNAME";

    $xmlContent = $TASK_TEMPLATE.Trim() -replace "{{user}}", $user
    $xmlPath = "$env:TEMP\yasb_task.xml"
    $xmlContent | Out-File -FilePath $xmlPath -Encoding Unicode

    schtasks /create /f /tn "YASB" /xml "$xmlPath"

    Remove-Item -Path $xmlPath -Force

    Copy-Item "$PSScriptRoot\..\yasb\*" -Destination (New-DestDir "$env:USERPROFILE\.config\yasb") -Recurse -Force
    TaskbarAutoHide -Enable $true

    # reload yasb or else the windows top bar will be shown under it
    Get-Process -Name yasb -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process yasb

    Write-Host "✅ yasb applied" -ForegroundColor Green
}

function ApplyPowerShell {
    Write-Host "Applying PowerShell profile..."

    Copy-Item "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\PowerShell") -Force
    Copy-Item "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\WindowsPowerShell") -Force

    Write-Host "✅ PowerShell profile applied" -ForegroundColor Green
}

function ApplyFastfetch {
    Write-Host "Applying fastfetch configuration..."

    Copy-Item "$PSScriptRoot\..\fastfetch\*" -Destination (New-DestDir "$env:USERPROFILE\.config\fastfetch") -Recurse -Force

    Write-Host "✅ fastfetch applied" -ForegroundColor Green
}

function IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function RelaunchScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParameters,

        [Parameter(Mandatory = $false)]
        [object[]]$UnboundArguments = @()
    )

    $argList = @()
    foreach ($param in $BoundParameters.GetEnumerator()) {
        $argList += "-$($param.Key)"
        $argList += "`"$($param.Value)`""
    }

    $argList += $UnboundArguments

    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $argList" -Verb RunAs
    exit
}

if (-not (IsAdmin)) {
    RelaunchScript -ScriptPath $MyInvocation.MyCommand.Path -BoundParameters $MyInvocation.BoundParameters -UnboundArguments $args
}

switch ($Feature) {
    "yasb" { ApplyYasb }
    "powershell" { ApplyPowerShell }
    "fastfetch" { ApplyFastfetch }
    "all" {
        ApplyYasb
        ApplyPowerShell
        ApplyFastfetch
        Write-Host "`nAll configurations applied successfully!" -ForegroundColor Green
    }
}