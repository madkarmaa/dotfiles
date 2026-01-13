function New-Subdir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subpath
    )

    New-Item -Force -Type Directory -Path (Join-Path "$PSScriptRoot\..\" $Subpath)
}

Copy-Item "$env:USERPROFILE\.config\yasb\*" -Destination (New-Subdir "yasb") -Recurse -Force -Exclude "yasb.log"

$mods = Get-ChildItem "HKLM:\SOFTWARE\Windhawk\Engine\Mods" | Select-Object -ExpandProperty PSChildName

$windhawkRegBackupPath = Join-Path (New-Subdir "windhawk") "settings.reg"
"Windows Registry Editor Version 5.00`n" | Out-File -FilePath $windhawkRegBackupPath -Encoding Unicode

foreach ($mod in $mods) {
    $regPath = "HKLM\SOFTWARE\Windhawk\Engine\Mods\$mod\Settings"
    $tempFile = "$env:TEMP\temp_$mod.reg"
    reg export $regPath $tempFile 2>$null | Out-Null

    if (Test-Path $tempFile) {
        # skip the header line and append the rest
        Get-Content $tempFile | Select-Object -Skip 1 | Add-Content -Path $windhawkRegBackupPath
        Remove-Item $tempFile
    }

    $modPath = "HKLM:\SOFTWARE\Windhawk\Engine\Mods\$mod"
    $disabled = Get-ItemProperty -Path $modPath -Name "Disabled" -ErrorAction SilentlyContinue

    if ($disabled) {
        "[HKEY_LOCAL_MACHINE\SOFTWARE\Windhawk\Engine\Mods\$mod]" | Add-Content -Path $windhawkRegBackupPath
        $value = $disabled.Disabled
        "`"Disabled`"=dword:$('{0:x8}' -f $value)" | Add-Content -Path $windhawkRegBackupPath
        "" | Add-Content -Path $windhawkRegBackupPath
    }
}

$FLOWLAUNCHER_SETTINGS = "$env:APPDATA\FlowLauncher\Settings\Settings.json"

Copy-Item $FLOWLAUNCHER_SETTINGS -Destination (New-Subdir "flowlauncher\Settings") -Force
Copy-Item "$env:APPDATA\FlowLauncher\Settings\Plugins\*" -Destination (New-Subdir "flowlauncher\Settings\Plugins") -Recurse -Force -Exclude "*.bak"

function CollectFlowLauncherPlugins {
    $DefaultIDs = @()
    $AppPluginsPath = "$env:LOCALAPPDATA\FlowLauncher\app-*\Plugins\*\plugin.json"
    $PluginFiles = Get-Item $AppPluginsPath

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

(CollectFlowLauncherPlugins) | ConvertTo-Json | Set-Content -Path (Join-Path (New-Subdir "flowlauncher") "custom_plugins.json") -Encoding UTF8

Copy-Item "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Destination (New-Subdir "powershell") -Force
Copy-Item "$env:USERPROFILE\.config\fastfetch\*" -Destination (New-Subdir "fastfetch") -Recurse -Force
Copy-Item "$env:USERPROFILE\.config\cava\config" -Destination (New-Subdir "cava") -Force

$latestPowerToysBackup = Get-ChildItem -Path "$env:USERPROFILE\Documents\PowerToys\Backup" -Filter "*.ptb" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestPowerToysBackup) {
    Copy-Item $latestPowerToysBackup.FullName -Destination (Join-Path (New-Subdir "powertoys") "backup.ptb") -Force
} else {
    Write-Host "No PowerToys backup file found." -ForegroundColor Yellow
}