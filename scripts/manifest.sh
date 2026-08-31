#!/usr/bin/env bash

# Paths are relative to $HOME and are stored below home/ in the repository.
HOME_ITEMS=(
  ".Xresources"
  ".config/environment.d/70-electron-wayland.conf"
  ".config/fontconfig"
  ".config/gtk-3.0"
  ".config/gtk-4.0"
  ".config/niri/config.kdl"
  ".config/niri/noctalia-shell.kdl"
  ".config/niri/screenshot-menu"
  ".config/noctalia/appearance.toml"
  ".config/qt6ct"
  ".config/xdg-desktop-portal/niri-portals.conf"
  ".config/xdg-terminals.list"
  ".local/share/icons/catppuccin-mocha-lavender-cursors"
)

# Absolute paths are stored below system/ using the same path.
SYSTEM_ITEMS=(
  "/etc/greetd/config.toml"
  "/etc/keyd/default.conf"
  "/etc/systemd/logind.conf.d/10-power-button.conf"
  "/etc/systemd/system/accounts-daemon.service.d/override.conf"
  "/usr/share/themes/catppuccin-mocha-lavender-compact+default"
  "/usr/share/wallpapers/walls-catppuccin-mocha/pine.jpg"
  "/usr/share/wallpapers/walls-catppuccin-mocha/windows-xp.jpg"
)

# CachyOS repository packages required by the desktop configuration.
REPO_PACKAGES=(
  "accountsservice"
  "adwaita-cursors"
  "base-devel"
  "brightnessctl"
  "fontconfig"
  "git"
  "greetd"
  "grim"
  "keyd"
  "kitty"
  "nautilus"
  "niri"
  "noctalia"
  "noctalia-greeter"
  "orca"
  "papirus-icon-theme"
  "pipewire-audio"
  "playerctl"
  "qt6ct"
  "rsync"
  "ttf-firacode-nerd"
  "ttf-jetbrains-mono-nerd"
  "otf-geist-mono-nerd"
  "xdg-desktop-portal-gnome"
  "xdg-desktop-portal-gtk"
  "xwayland-satellite"
)

# AUR packages are installed by paru, which CachyOS provides in its repositories.
AUR_PACKAGES=(
  "ttf-outfit"
  "vicinae-bin"
  "xdg-terminal-exec"
)
