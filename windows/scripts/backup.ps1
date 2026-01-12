function New-Subdir {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subpath
    )

    New-Item -Force -Type Directory -Path (Join-Path "$PSScriptRoot\..\" $Subpath)
}

Copy-Item "$env:USERPROFILE\.config\yasb\*" -Destination (New-Subdir "yasb") -Recurse -Force -Exclude "yasb.log"

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