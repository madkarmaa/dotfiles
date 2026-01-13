param (
    [Parameter(Position = 0)]
    [ValidateSet("windhawk", "yasb", "flowlauncher", "powershell", "fastfetch", "cava", "powertoys", "all")]
    [string]$Feature = "all"
)

function Info {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[i] $Message"
}

function Success {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[+] $Message" -ForegroundColor Green
}

function Warning {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[!] $Message" -ForegroundColor Black -BackgroundColor Yellow
}

function Failure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[-] $Message" -ForegroundColor White -BackgroundColor Red
}

function New-DestDir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $dir = New-Item -Force -Type Directory -Path $Path
    return $dir.FullName
}

function AddToUserPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$NewPath
    )

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if ($currentPath.Split(';') -notcontains $NewPath) {
        $updatedPath = "$currentPath;$NewPath"
        [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
        Success "Added '$NewPath' to user PATH"
    } else {
        Info "'$NewPath' is already in user PATH"
    }
}

function TaskbarAutoHide {
    param (
        [Parameter(Mandatory = $true)]
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

function HighPriorityTask {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProgramPath,
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        [Parameter(Mandatory = $true)]
        [bool]$RunAsAdmin
    )

    $user = "$env:USERDOMAIN\$env:USERNAME";
    $runLevel = $RunAsAdmin ? "HighestAvailable" : "LeastPrivilege"

    $xmlContent = (Get-Content "$PSScriptRoot\HighPriority.xml").Trim().Replace("{{user}}", $user).Replace("{{program}}", $ProgramPath.Trim()).Replace("{{name}}", $TaskName.Trim().Replace(" ", "")).Replace("{{runLevel}}", $runLevel)
    $xmlPath = "$env:TEMP\yasb_task.xml"
    $xmlContent | Out-File -FilePath $xmlPath -Encoding Unicode

    schtasks /create /f /tn $TaskName /xml "$xmlPath"

    Remove-Item -Path $xmlPath -Force
}

function ApplyWindhawk {
    Info "Installing Windhawk..."
    winget install -e --id RamenSoftware.Windhawk

    Info "Applying Windhawk configuration..."

    regedit.exe /s "$PSScriptRoot\..\windhawk\settings.reg"
    Start-Process "C:\Program Files\Windhawk\windhawk.exe" -ArgumentList @("-restart", "-tray-only")

    Success "Windhawk configuration applied"
}

function ApplyYasb {
    ApplyWindhawk # YASB requires Windhawk to be installed for it to look correct

    Info "Installing YASB..."
    # https://github.com/amnweb/yasb?tab=readme-ov-file#winget
    winget install -e --id AmN.yasb

    Info "Applying yasb configuration..."

    HighPriorityTask -ProgramPath "C:\Program Files\YASB\yasb.exe" -TaskName "YASB" -RunAsAdmin $true

    Copy-Item "$PSScriptRoot\..\yasb\*" -Destination (New-DestDir "$env:USERPROFILE\.config\yasb") -Recurse -Force
    TaskbarAutoHide -Enable $true

    # reload yasb or else the windows' top bar will be shown under it
    yasbc.exe reload | Out-Null

    Success "YASB configuration applied"
}

function ApplyFlowLauncher {
    Info "Installing Flow Launcher..."
    winget install -e --id Flow-Launcher.Flow-Launcher

    Info "Applying Flow Launcher configuration..."

    HighPriorityTask -ProgramPath "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe" -TaskName "FlowLauncher" -RunAsAdmin $false

    Get-Process -Name Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force

    Copy-Item "$PSScriptRoot\..\flowlauncher\*" -Destination (New-DestDir "$env:APPDATA\FlowLauncher") -Recurse -Force
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/R0gue301/MinFlow/refs/heads/main/MinFlow.xaml" -OutFile (Join-Path (New-DestDir "$env:APPDATA\FlowLauncher\Themes") "MinFlow.xaml")

    $ONLINE_PLUGINS = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Flow-Launcher/Flow.Launcher.PluginsManifest/main/plugins.json"
    $CUSTOM_PLUGINS = Get-Content "$PSScriptRoot\..\flowlauncher\custom_plugins.json" -Raw | ConvertFrom-Json

    foreach ($ID in $CUSTOM_PLUGINS) {
        $PluginData = $ONLINE_PLUGINS | Where-Object { $_.ID -eq $ID }

        $Name    = $PluginData.Name
        $Version = $PluginData.Version
        $Url     = $PluginData.UrlDownload

        $FolderName = "$Name-$Version"
        $TargetDir  = "$env:APPDATA\FlowLauncher\Plugins\$FolderName"
        $ZipPath    = "$env:TEMP\$ID.zip"

        if (Test-Path $TargetDir) {
            Info "Skipping '$FolderName' (already exists)"
            continue
        }

        Info "Installing '$FolderName' plugin..."

        Invoke-WebRequest -Uri $Url -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $TargetDir -Force
        Remove-Item $ZipPath -Force
    }

    Start-Process "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe"

    Success "Flow Launcher configuration applied"
}

function ApplyPowerShell {
    Info "Applying PowerShell profile..."

    Copy-Item "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\PowerShell") -Force
    Copy-Item "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination (New-DestDir "$env:USERPROFILE\Documents\WindowsPowerShell") -Force

    Success "PowerShell profile applied"
}

function ApplyFastfetch {
    Info "Installing Fastfetch..."
    # https://github.com/fastfetch-cli/fastfetch?tab=readme-ov-file#windows
    winget install -e --id Fastfetch-cli.Fastfetch

    Info "Applying fastfetch configuration..."
    Copy-Item "$PSScriptRoot\..\fastfetch\*" -Destination (New-DestDir "$env:USERPROFILE\.config\fastfetch") -Recurse -Force

    Success "Fastfetch configuration applied"
}

function ApplyPowerToys {
    Info "Installing PowerToys..."
    # https://learn.microsoft.com/en-us/windows/powertoys/install#install-with-windows-package-manager
    winget install -e --id Microsoft.PowerToys --source winget

    Info "Applying PowerToys configuration..."

    $nowDt = [DateTime]::UtcNow
    $nowFt = $nowDt.ToFileTimeUtc()

    $dest = Join-Path (New-DestDir "$env:USERPROFILE\Documents\PowerToys\Backup") "settings_$nowFt.ptb"

    Copy-Item "$PSScriptRoot\..\powertoys\backup.ptb" -Destination $dest -Force

    $item = Get-Item $dest
    $item.CreationTimeUtc  = $nowDt
    $item.LastWriteTimeUtc = $nowDt
    $item.LastAccessTimeUtc = $nowDt

    # if powertoys settings is executed as admin, it'll re-launch as non-admin immediately
    # which will trick Wait-Process into thinking it's done before the window is actually shown to the user
    # so we open the settings via explorer.exe and try to intercept the process instead
    Start-Process explorer.exe -ArgumentList "C:\Program Files\PowerToys\WinUI3Apps\PowerToys.Settings.exe"

    Warning "Please restore the settings from the PowerToys Settings window that just opened, under General > Backup & Restore"
    Warning "After restoring, close the PowerToys Settings window to continue..."

    $RETRIES = 15
    for ($i = 0; $i -lt $RETRIES; $i++) {
        $proc = Get-Process -Name PowerToys.Settings -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Wait-Process
            break
        }
        Start-Sleep -Seconds 1
    }

    Success "PowerToys configuration applied"
}

function ApplyCava {
    $isCavaInstalled = Get-Command cava -ErrorAction SilentlyContinue

    if (-not $isCavaInstalled) {
        Info "Installing Cava..."

        # Cava has a winget package but it's outdated, so we download the latest release from GitHub
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/karlstav/cava/releases/latest"
        $asset = $release.assets | Where-Object { $_.name -eq "cava_win_x64_install.exe" }

        if (-not $asset) {
            Failure "cava_win_x64_install.exe not found in the latest release"
            return
        }

        $outputPath = "$env:TEMP\cava_win_x64_install.exe"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $outputPath
        Start-Process -FilePath $outputPath -ArgumentList @("/VERYSILENT", "/NOICONS") -Wait
        Remove-Item -Path $outputPath -Force
    } else {
        Info "Cava is already installed"
    }

    # add cava to user path even if already installed to ensure it's there
    AddToUserPath -NewPath "$env:LOCALAPPDATA\Programs\cava"

    Info "Installing Microsoft Visual C++ 2012 Redistributable..."
    winget install -e --id Microsoft.VCRedist.2012.x64

    Info "Applying Cava configuration..."
    Copy-Item "$PSScriptRoot\..\cava\config" -Destination (New-DestDir "$env:USERPROFILE\.config\cava") -Force
    Success "Cava configuration applied"
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

$OriginalProgressPreference = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

switch ($Feature) {
    "windhawk" { ApplyWindhawk }
    "yasb" { ApplyYasb }
    "flowlauncher" { ApplyFlowLauncher }
    "powershell" { ApplyPowerShell }
    "fastfetch" { ApplyFastfetch }
    "cava" { ApplyCava }
    "powertoys" { ApplyPowerToys }
    "all" {
        ApplyWindhawk
        ApplyYasb
        ApplyFlowLauncher
        ApplyPowerShell
        ApplyFastfetch
        ApplyCava
        ApplyPowerToys
        Success "All configurations applied successfully!"
    }
}

$ProgressPreference = $OriginalProgressPreference

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)