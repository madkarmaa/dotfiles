My desktop setup config files, for both **Windows** and ~~**Linux** (soon)~~

## Fonts

- **[Fira Code](https://github.com/ryanoasis/nerd-fonts/releases/latest)**
- **[JetBrains Mono](https://github.com/ryanoasis/nerd-fonts/releases/latest)**

## Windows

![Windows desktop](./windows/images/desktop.png)

- **[Wallpaper Engine](https://store.steampowered.com/app/431960)**
- **[Windhawk](https://windhawk.net)**
- **[YASB](https://github.com/amnweb/yasb?tab=readme-ov-file#installation)**
- **[Fastfetch](https://github.com/fastfetch-cli/fastfetch?tab=readme-ov-file#windows)**

## YASB auto-start

Paste this command in an admin PowerShell session to auto-start YASB at user logon.

```pwsh
schtasks /create /f /rl highest /sc onlogon /ru "$env:USERNAME" /tn "YASB" /tr 'cmd.exe /c start "" /high "C:\Program Files\YASB\yasb.exe"'
```

### Wallpaper
- [Wallpaper Engine](https://steamcommunity.com/sharedfiles/filedetails/?id=1382838434)
- [Static](./images/wallpaper-static.jpg) ([original](https://www.pexels.com/photo/grayscale-photography-of-mountain-234272/))

### Windows Terminal [color scheme](https://windowsterminalthemes.dev/?theme=OneDark)

### Windhawk

![Windhawk mods](./windows/images/windhawk.png)

<small><i>First time ricing, I hope you like it :P</i></small>