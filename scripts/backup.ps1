function Info { param([string]$Message) Write-Host "[i] $Message" }
function Success { param([string]$Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Warning { param([string]$Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Failure { param([string]$Message) Write-Host "[-] $Message" -ForegroundColor Red }

function New-Subdir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subpath
    )

    New-Item -Force -Type Directory -Path (Join-Path "$PSScriptRoot\..\" $Subpath) | Out-Null
    return (Join-Path "$PSScriptRoot\..\" $Subpath)
}

function Backup-Path {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [switch]$Recurse,
        [string[]]$Exclude
    )

    if (-not (Test-Path $Source)) {
        return $false
    }

    $params = @{ Path = $Source; Destination = $Destination; Force = $true }
    if ($Recurse) { $params.Recurse = $true }
    if ($Exclude) { $params.Exclude = $Exclude }

    Copy-Item @params
    return $true
}

$backedUp = @()
$skipped = @()

Info 'Backing up YASB...'
if (Backup-Path "$env:USERPROFILE\.config\yasb\*" (New-Subdir 'yasb') -Recurse -Exclude '*.log*') {
    $backedUp += 'YASB'
}
else {
    $skipped += 'YASB'
}

Info 'Backing up Windhawk...'
if (Test-Path 'HKLM:\SOFTWARE\Windhawk\Engine\Mods') {
    $mods = Get-ChildItem 'HKLM:\SOFTWARE\Windhawk\Engine\Mods' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName

    if ($mods) {
        $windhawkRegBackupPath = Join-Path (New-Subdir 'windhawk') 'settings.reg'
        "Windows Registry Editor Version 5.00`n" | Out-File -FilePath $windhawkRegBackupPath -Encoding Unicode

        foreach ($mod in $mods) {
            $regPath = "HKLM\SOFTWARE\Windhawk\Engine\Mods\$mod\Settings"
            $tempFile = "$env:TEMP\temp_$mod.reg"
            reg export $regPath $tempFile | Out-Null

            if (Test-Path $tempFile) {
                Get-Content $tempFile | Select-Object -Skip 1 | Add-Content -Path $windhawkRegBackupPath
                Remove-Item $tempFile
            }

            $modPath = "HKLM:\SOFTWARE\Windhawk\Engine\Mods\$mod"
            $disabled = Get-ItemProperty -Path $modPath -Name 'Disabled' -ErrorAction SilentlyContinue

            if ($disabled) {
                "[HKEY_LOCAL_MACHINE\SOFTWARE\Windhawk\Engine\Mods\$mod]" | Add-Content -Path $windhawkRegBackupPath
                $value = $disabled.Disabled
                "`"Disabled`"=dword:$('{0:x8}' -f $value)" | Add-Content -Path $windhawkRegBackupPath
                '' | Add-Content -Path $windhawkRegBackupPath
            }
        }
        $backedUp += 'Windhawk'
    }
    else {
        $skipped += 'Windhawk (no mods found)'
    }
}
else {
    $skipped += 'Windhawk (not installed)'
}

Info 'Backing up Flow Launcher...'
$FLOWLAUNCHER_SETTINGS = "$env:APPDATA\FlowLauncher\Settings\Settings.json"

if (Test-Path $FLOWLAUNCHER_SETTINGS) {
    Copy-Item $FLOWLAUNCHER_SETTINGS -Destination (New-Subdir 'flowlauncher\Settings') -Force

    $pluginsPath = "$env:APPDATA\FlowLauncher\Settings\Plugins\*"
    if (Test-Path $pluginsPath) {
        Copy-Item $pluginsPath -Destination (New-Subdir 'flowlauncher\Settings\Plugins') -Recurse -Force -Exclude '*.bak'
    }

    function CollectFlowLauncherPlugins {
        $DefaultIDs = @()
        $AppPluginsPath = "$env:LOCALAPPDATA\FlowLauncher\app-*\Plugins\*\plugin.json"
        $PluginFiles = Get-ChildItem $AppPluginsPath -ErrorAction SilentlyContinue

        foreach ($File in $PluginFiles) {
            $JsonContent = Get-Content $File.FullName -Raw | ConvertFrom-Json
            $DefaultIDs += $JsonContent.ID
        }

        $SettingsJson = Get-Content $FLOWLAUNCHER_SETTINGS -Raw | ConvertFrom-Json
        $UserPlugins = $SettingsJson.PluginSettings.Plugins

        $CustomIDs = @()

        foreach ($Key in $UserPlugins.PSObject.Properties.Name) {
            $PluginData = $UserPlugins.$Key
            $PluginID = $PluginData.ID

            if ($PluginID -and ($DefaultIDs -notcontains $PluginID)) {
                $CustomIDs += $PluginID
            }
        }

        return $CustomIDs
    }

    (CollectFlowLauncherPlugins) | ConvertTo-Json | Set-Content -Path (Join-Path (New-Subdir 'flowlauncher') 'custom_plugins.json') -Encoding UTF8
    $backedUp += 'Flow Launcher'
}
else {
    $skipped += 'Flow Launcher (not installed)'
}

Info 'Backing up PowerShell profile...'
if (Backup-Path "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" (New-Subdir 'powershell')) {
    $backedUp += 'PowerShell profile'
}
else {
    $skipped += 'PowerShell profile'
}

Info 'Backing up Fastfetch...'
if (Backup-Path "$env:USERPROFILE\.config\fastfetch\*" (New-Subdir 'fastfetch') -Recurse) {
    $backedUp += 'Fastfetch'
}
else {
    $skipped += 'Fastfetch'
}

Info 'Backing up WezTerm...'
if (Backup-Path "$env:USERPROFILE\.wezterm.lua" (Join-Path (New-Subdir 'wezterm') 'wezterm.lua')) {
    $backedUp += 'WezTerm'
}
else {
    $skipped += 'WezTerm'
}

Info 'Backing up Cava...'
if (Backup-Path "$env:USERPROFILE\.config\cava\config" (New-Subdir 'cava')) {
    $backedUp += 'Cava'
}
else {
    $skipped += 'Cava'
}

Info 'Backing up PowerToys...'
$powerToysBackupPath = "$env:USERPROFILE\Documents\PowerToys\Backup"
if (Test-Path $powerToysBackupPath) {
    $latestPowerToysBackup = Get-ChildItem -Path $powerToysBackupPath -Filter '*.ptb' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestPowerToysBackup) {
        Copy-Item $latestPowerToysBackup.FullName -Destination (Join-Path (New-Subdir 'powertoys') 'backup.ptb') -Force
        $backedUp += 'PowerToys'
    }
    else {
        $skipped += 'PowerToys (no backup file found)'
    }
}
else {
    $skipped += 'PowerToys (not installed)'
}

Write-Host
if ($backedUp.Count -gt 0) {
    Success "Backed up: $($backedUp -join ', ')"
}
if ($skipped.Count -gt 0) {
    Warning "Skipped: $($skipped -join ', ')"
}

Write-Host "`nPress any key to exit..."
[void][System.Console]::ReadKey($true)
