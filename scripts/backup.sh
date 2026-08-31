#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck source=manifest.sh
source "$SCRIPT_DIR/manifest.sh"

copied=()
skipped=()

backup_item() {
  local source=$1
  local destination=$2

  if [[ ! -e $source && ! -L $source ]]; then
    skipped+=("$source")
    return
  fi

  # apply.sh links destinations back into this repository. Do not replace a
  # repository item with its own symlink when backup.sh is run afterward.
  if [[ ( -e $destination || -L $destination ) &&
        $(readlink -f -- "$source") == $(readlink -f -- "$destination") ]]; then
    copied+=("$source")
    return
  fi

  mkdir -p -- "$(dirname -- "$destination")"

  if [[ -d $source && ! -L $source ]]; then
    mkdir -p -- "$destination"
    rsync -a --delete -- "$source/" "$destination/"
  else
    cp -a --remove-destination -- "$source" "$destination"
  fi

  copied+=("$source")
}

for relative_path in "${HOME_ITEMS[@]}"; do
  backup_item "$HOME/$relative_path" "$REPO_ROOT/home/$relative_path"
done

for absolute_path in "${SYSTEM_ITEMS[@]}"; do
  backup_item "$absolute_path" "$REPO_ROOT/system$absolute_path"
done

printf '[+] Backed up %d desktop configuration paths.\n' "${#copied[@]}"
if ((${#skipped[@]})); then
  printf '[!] Skipped missing paths:\n'
  printf '    %s\n' "${skipped[@]}"
fi
