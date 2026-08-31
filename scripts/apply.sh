#!/usr/bin/env bash
set -euo pipefail

if ((EUID == 0)); then
  printf 'Run this script as the desktop user, not root. It uses sudo for system changes.\n' >&2
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  printf 'This configuration targets CachyOS and requires pacman.\n' >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  printf 'sudo is required.\n' >&2
  exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
BACKUP_SUFFIX="dotfiles-backup-$(date +%Y%m%d%H%M%S)"

# shellcheck source=manifest.sh
source "$SCRIPT_DIR/manifest.sh"

printf '[i] Installing desktop packages...\n'
sudo pacman -Syu --needed --noconfirm "${REPO_PACKAGES[@]}" paru
paru -S --needed --noconfirm --skipreview "${AUR_PACKAGES[@]}"

link_home_item() {
  local relative_path=$1
  local source="$REPO_ROOT/home/$relative_path"
  local destination="$HOME/$relative_path"

  if [[ ! -e $source && ! -L $source ]]; then
    printf 'Missing repository path: %s\n' "$source" >&2
    exit 1
  fi

  mkdir -p -- "$(dirname -- "$destination")"

  if [[ -L $destination && $(readlink -f -- "$destination") == $(readlink -f -- "$source") ]]; then
    return
  fi

  if [[ -e $destination || -L $destination ]]; then
    mv -- "$destination" "$destination.$BACKUP_SUFFIX"
  fi

  ln -s -- "$source" "$destination"
}

link_system_item() {
  local destination=$1
  local source="$REPO_ROOT/system$destination"

  if [[ ! -e $source && ! -L $source ]]; then
    printf 'Missing repository path: %s\n' "$source" >&2
    exit 1
  fi

  sudo mkdir -p -- "$(dirname -- "$destination")"

  if [[ -L $destination && $(readlink -f -- "$destination") == $(readlink -f -- "$source") ]]; then
    return
  fi

  if sudo test -e "$destination" || sudo test -L "$destination"; then
    sudo mv -- "$destination" "$destination.$BACKUP_SUFFIX"
  fi

  sudo ln -s -- "$source" "$destination"
}

printf '[i] Linking desktop configuration...\n'
for relative_path in "${HOME_ITEMS[@]}"; do
  link_home_item "$relative_path"
done

for absolute_path in "${SYSTEM_ITEMS[@]}"; do
  link_system_item "$absolute_path"
done

fc-cache -f

sudo systemctl enable greetd.service keyd.service

if [[ -d /run/systemd/system ]]; then
  sudo systemctl daemon-reload
fi

printf '[+] Desktop configuration applied. Existing paths were preserved with suffix %s.\n' "$BACKUP_SUFFIX"
