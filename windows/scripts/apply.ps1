function Info { param([string]$Message) Write-Host "[i] $Message" }
function Success { param([string]$Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Warning { param([string]$Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Failure { param([string]$Message) Write-Host "[-] $Message" -ForegroundColor Red }

function RefreshEnv {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
}

function WingetInstall {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    winget install -e --id $Id.Trim() --source winget --silent --accept-source-agreements --accept-package-agreements
    RefreshEnv
}

function New-DestDir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $dir = New-Item -Force -Type Directory -Path $Path
    return $dir.FullName
}

function New-Symlink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        Failure "Source path does not exist: $Source"
        return
    }

    $resolvedSource = (Resolve-Path $Source).Path

    # Ensure parent directory exists
    $parentDir = Split-Path -Parent $Destination
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -Force -Type Directory -Path $parentDir | Out-Null
    }

    # Remove existing item (symlink or physical file/folder)
    # Use .Delete() for symlinks to avoid following the link
    if (Test-Path $Destination) {
        $item = Get-Item $Destination -Force
        if ($item.LinkType) {
            $item.Delete()
        }
        else {
            Remove-Item -Path $Destination -Recurse -Force
        }
    }

    New-Item -ItemType SymbolicLink -Path $Destination -Target $resolvedSource -Force | Out-Null
}

function AddToUserPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$NewPath
    )

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    if ($currentPath.Split(';') -notcontains $NewPath) {
        $updatedPath = "$currentPath;$NewPath"
        [Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')
        Success "Added '$NewPath' to user PATH"
    }
    else {
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

function DesktopIcons {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Show
    )

    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path $path -Name HideIcons -Value ([int](-not $Show))

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

    if ($RunAsAdmin) {
        $runLevel = 'HighestAvailable'
    }
    else {
        $runLevel = 'LeastPrivilege'
    }

    $xmlContent = (Get-Content "$PSScriptRoot\HighPriority.xml").Trim().Replace('{{user}}', $user).Replace('{{program}}', $ProgramPath.Trim()).Replace('{{name}}', $TaskName.Trim().Replace(' ', '')).Replace('{{runLevel}}', $runLevel)
    $safeTaskName = $TaskName.Trim().Replace(' ', '_')
    $xmlPath = "$env:TEMP\HighPriority_$safeTaskName.xml"
    $xmlContent | Out-File -FilePath $xmlPath -Encoding Unicode

    schtasks /create /f /tn $TaskName /xml "$xmlPath"

    Remove-Item -Path $xmlPath -Force
}

function DownloadLatestGitHubReleaseFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$User,
        [Parameter(Mandatory = $true)]
        [string]$Repo,
        [Parameter(Mandatory = $true)]
        [string]$FilePattern,
        [Parameter(Mandatory = $true)]
        [string]$OutDir
    )

    $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$($User.Trim())/$($Repo.Trim())/releases"

    $downloadUrl = $null
    foreach ($release in $releases) {
        foreach ($asset in $release.assets) {
            if ($asset.name -like $FilePattern) {
                $downloadUrl = $asset.browser_download_url
                break
            }
        }
    }

    if ($downloadUrl) {
        $outPath = Join-Path -Path $OutDir -ChildPath (Split-Path -Path $downloadUrl -Leaf)
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outPath
        return $outPath
    }
    else {
        Warning "File not found matching pattern: $FilePattern"
        return $null
    }
}

function InstallFont {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FontPath
    )

    $fontFile = Get-Item $FontPath.Trim() -ErrorAction Stop
    $fontsFolder = "$env:WINDIR\Fonts"

    $suffix = if ($fontFile.Extension.ToLower() -eq '.ttf') { ' (TrueType)' } elseif ($fontFile.Extension.ToLower() -eq '.otf') { ' (OpenType)' } else { '' }
    $fontName = $fontFile.BaseName + $suffix

    $destinationPath = Join-Path -Path $fontsFolder -ChildPath $fontFile.Name

    if (-not (Test-Path -Path $destinationPath)) {
        Copy-Item -Path $FontPath.Trim() -Destination $destinationPath

        $regKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        New-ItemProperty -Path $regKey -Name $fontName -Value $fontFile.Name -PropertyType String | Out-Null

        Success "Installed font: $fontName"
    }
    else {
        Info "Font already installed: $fontName"
    }
}

function ApplyWindhawk {
    Info 'Installing Windhawk...'
    WingetInstall -Id 'RamenSoftware.Windhawk'

    Info 'Applying Windhawk configuration...'

    regedit.exe /s "$PSScriptRoot\..\windhawk\settings.reg"
    Start-Process 'C:\Program Files\Windhawk\windhawk.exe' -ArgumentList @('-restart', '-tray-only')

    Success 'Windhawk configuration applied'
}

function ApplyYasb {
    Info 'Installing YASB...'
    WingetInstall -Id 'AmN.yasb'

    Info 'Applying yasb configuration...'

    HighPriorityTask -ProgramPath 'C:\Program Files\YASB\yasb.exe' -TaskName 'YASB' -RunAsAdmin $true

    New-Symlink -Source "$PSScriptRoot\..\yasb" -Destination "$env:USERPROFILE\.config\yasb"
    TaskbarAutoHide -Enable $true

    # start yasb if not running
    yasbc.exe start | Out-Null

    # reload yasb or else the windows' top bar will be shown under it
    yasbc.exe reload | Out-Null

    Success 'YASB configuration applied'
}

function ApplyFlowLauncher {
    Info 'Installing Flow Launcher...'
    WingetInstall -Id 'Flow-Launcher.Flow-Launcher'

    Info 'Applying Flow Launcher configuration...'

    HighPriorityTask -ProgramPath "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe" -TaskName 'FlowLauncher' -RunAsAdmin $false

    Get-Process -Name Flow.Launcher -ErrorAction SilentlyContinue | Stop-Process -Force

    New-Symlink -Source "$PSScriptRoot\..\flowlauncher\Settings" -Destination "$env:APPDATA\FlowLauncher\Settings"

    $ONLINE_PLUGINS = Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Flow-Launcher/Flow.Launcher.PluginsManifest/main/plugins.json'
    $CUSTOM_PLUGINS = Get-Content "$PSScriptRoot\..\flowlauncher\custom_plugins.json" -Raw | ConvertFrom-Json

    foreach ($ID in $CUSTOM_PLUGINS) {
        $PluginData = $ONLINE_PLUGINS | Where-Object { $_.ID -eq $ID }

        if (-not $PluginData) {
            Warning "Plugin '$ID' not found in manifest, skipping..."
            continue
        }

        $Name = $PluginData.Name
        $Version = $PluginData.Version
        $Url = $PluginData.UrlDownload

        $FolderName = "$Name-$Version"
        $TargetDir = "$env:APPDATA\FlowLauncher\Plugins\$FolderName"
        $ZipPath = "$env:TEMP\$ID.zip"

        if (Test-Path $TargetDir) {
            Info "Skipping '$FolderName' (already exists)"
            continue
        }

        Info "Installing '$FolderName' plugin..."

        Invoke-WebRequest -Uri $Url -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $TargetDir -Force
        Remove-Item $ZipPath -Force
    }

    Start-ScheduledTask -TaskName 'FlowLauncher'

    Success 'Flow Launcher configuration applied'
}

function ApplyPowerShell {
    Info 'Applying PowerShell profile...'

    New-DestDir "$env:USERPROFILE\Documents\PowerShell" | Out-Null
    New-DestDir "$env:USERPROFILE\Documents\WindowsPowerShell" | Out-Null

    New-Symlink -Source "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    New-Symlink -Source "$PSScriptRoot\..\powershell\Microsoft.PowerShell_profile.ps1" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

    Success 'PowerShell profile applied'
}

function ApplyFastfetch {
    Info 'Installing Fastfetch...'
    WingetInstall -Id 'Fastfetch-cli.Fastfetch'

    Info 'Applying fastfetch configuration...'
    New-Symlink -Source "$PSScriptRoot\..\fastfetch" -Destination "$env:USERPROFILE\.config\fastfetch"

    Success 'Fastfetch configuration applied'
}

function ApplyWezTerm {
    Info 'Installing WezTerm...'
    WingetInstall -Id 'wez.wezterm'

    Info 'Applying WezTerm configuration...'
    New-Symlink -Source "$PSScriptRoot\..\wezterm\.wezterm.lua" -Destination "$env:USERPROFILE\.wezterm.lua"

    Success 'WezTerm configuration applied'
}

function ApplyPowerToys {
    Info 'Installing PowerToys...'
    WingetInstall -Id 'Microsoft.PowerToys'

    Info 'Applying PowerToys configuration...'

    $nowDt = [DateTime]::UtcNow
    $nowFt = $nowDt.ToFileTimeUtc()

    $dest = Join-Path (New-DestDir "$env:USERPROFILE\Documents\PowerToys\Backup") "settings_$nowFt.ptb"

    Copy-Item "$PSScriptRoot\..\powertoys\backup.ptb" -Destination $dest -Force

    $item = Get-Item $dest
    $item.CreationTimeUtc = $nowDt
    $item.LastWriteTimeUtc = $nowDt
    $item.LastAccessTimeUtc = $nowDt

    Warning 'Please restore the backup from the PowerToys Settings page, under General > Backup & Restore > Restore'
    Success 'PowerToys configuration applied'
}

function ApplyCava {
    Info 'Installing Cava...'
    WingetInstall -Id 'karlstav.cava'

    Info 'Applying Cava configuration...'
    New-Symlink -Source "$PSScriptRoot\..\cava" -Destination "$env:USERPROFILE\.config\cava"

    Success 'Cava configuration applied'
}

function InstallAcrylicMenus {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$SystemWide
    )

    Info 'Installing AcrylicMenus...'

    $fileName = 'AcrylicMenus.zip'
    $zipPath = DownloadLatestGitHubReleaseFile -User 'krlvm' -Repo 'AcrylicMenus' -FilePattern $fileName -OutDir $env:TEMP

    $LOCAL_INSTALLATION_PATH = "$env:LOCALAPPDATA\AcrylicMenus"
    $GLOBAL_INSTALLATION_PATH = "$env:PROGRAMFILES\AcrylicMenus"

    if ($SystemWide) {
        $installationPath = $GLOBAL_INSTALLATION_PATH
    }
    else {
        $installationPath = $LOCAL_INSTALLATION_PATH
    }

    if (Test-Path $installationPath) {
        Get-Process -Name AcrylicMenusLoader -ErrorAction SilentlyContinue | Stop-Process -Force
        Remove-Item -Path $installationPath -Recurse -Force
    }

    Expand-Archive -Path $zipPath -DestinationPath $installationPath -Force
    Remove-Item -Path $zipPath -Force

    HighPriorityTask -ProgramPath "$installationPath\AcrylicMenusLoader.exe" -TaskName 'AcrylicMenus' -RunAsAdmin $true
    Start-ScheduledTask -TaskName 'AcrylicMenus'

    if ($SystemWide) {
        Success 'AcrylicMenus installed successfully for all users'
    }
    else {
        Success 'AcrylicMenus installed successfully for the current user'
    }
}

function IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function RelaunchScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -Verb RunAs
    exit
}

Set-ExecutionPolicy Bypass -Scope Process

if (-not (IsAdmin)) {
    RelaunchScript -ScriptPath $MyInvocation.MyCommand.Path
}

$OriginalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

DesktopIcons -Show $false

ApplyWindhawk
ApplyYasb
ApplyFlowLauncher
ApplyPowerShell
ApplyFastfetch
ApplyWezTerm
ApplyCava
ApplyPowerToys

InstallAcrylicMenus -SystemWide $true

Success 'All configurations applied successfully!'

$ProgressPreference = $OriginalProgressPreference

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)
