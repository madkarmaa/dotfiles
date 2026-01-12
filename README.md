My desktop setup configuration files for both **Windows** and ~~**Linux** (soon)~~

## 🔤 Fonts

- **[Fira Code](https://github.com/ryanoasis/nerd-fonts/releases/latest)**
- **[JetBrains Mono](https://github.com/ryanoasis/nerd-fonts/releases/latest)**

## 🪟 Windows

![Windows desktop](./windows/images/desktop.png)

### 🚀 Apply configurations

Run this command in an **admin** PowerShell session to automatically install the required software and apply the configurations:

```
git clone https://github.com/madkarmaa/dotfiles --depth 1
cd .\dotfiles\windows\scripts

# yasb, flowlauncher, powershell, fastfetch, cava, powertoys, all (defaults to all)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ".\apply.ps1 all"
```

### 💻 Software

- **[Wallpaper Engine](https://store.steampowered.com/app/431960)** (Steam)
- **[Cava](https://github.com/karlstav/cava/releases/latest)**

- **[Windhawk](https://windhawk.net)**

```
winget install -e --id RamenSoftware.Windhawk
```

- **[YASB](https://github.com/amnweb/yasb)**

```
winget install -e --id AmN.yasb
```

- **[Flow Launcher](https://github.com/Flow-Launcher/Flow.Launcher)**

```
winget install -e --id Flow-Launcher.Flow-Launcher
```

- **[Fastfetch](https://github.com/fastfetch-cli/fastfetch)**

```
winget install -e --id Fastfetch-cli.Fastfetch
```

- **[PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/install#install-with-windows-package-manager)**

```
winget install -e --id Microsoft.PowerToys --source winget
```

### 🖼️ Wallpaper
- **[Wallpaper Engine](https://steamcommunity.com/sharedfiles/filedetails/?id=1382838434)**
- **[Static](./images/wallpaper-static.jpg)** ([original](https://www.pexels.com/photo/grayscale-photography-of-mountain-234272/))

### 🖥️ Windows Terminal color scheme

**Get it [here](https://windowsterminalthemes.dev/?theme=OneDark)**.

Learn how to install the color scheme **[here](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/color-schemes)**.

### 🎨 Windhawk mods

| | |
|---|---|
| ![Extension Change No Warning](./windows/images/windhawk/extension-change-no-warning.png) | ![Start Menu All Apps](./windows/images/windhawk/start-menu-all-apps.png) |
| ![Taskbar Button Click](./windows/images/windhawk/taskbar-button-click.png) | ![Taskbar On Top](./windows/images/windhawk/taskbar-on-top.png) |
| ![Taskbar Tray System Icon Tweaks](./windows/images/windhawk/taskbar-tray-system-icon-tweaks.png) | ![Windows 11 Notification Center Styler](./windows/images/windhawk/windows-11-notification-center-styler.png) |
| ![Windows 11 Start Menu Styler](./windows/images/windhawk/windows-11-start-menu-styler.png) | ![Windows 11 Taskbar Styler](./windows/images/windhawk/windows-11-taskbar-styler.png) |

### ⚙️ PowerToys settings

Paste this command in a **CMD** session to get the path of the Windows Terminal executable to paste in the "**App**" section:

```
where wt.exe
```

![PowerToys settings](./windows/images/powertoys.png)

<small><i>First time ricing, I hope you like it :P</i></small>