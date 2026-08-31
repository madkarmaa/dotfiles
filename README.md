# Linux desktop configuration

CachyOS configuration for Niri, Noctalia, greetd, GTK/Qt theming, fonts, cursors, portals, and the programs referenced by the Niri session.

## Back up this machine

```sh
./scripts/backup.sh
```

The backup and apply scripts use the same path and package manifest in `scripts/manifest.sh`.

## Apply on another machine

Clone this repository as the target desktop user, then run:

```sh
./scripts/apply.sh
```

The script installs the required CachyOS and AUR packages, preserves existing destinations with a timestamped suffix, replaces them with symlinks into the repository, and enables greetd and keyd. Pulling the repository then updates the live configuration.

Application preferences and state are intentionally excluded. Browser profiles, credentials, tokens, histories, caches, logs, databases, OBS settings, Sunshine state, Cloudflare tunnel files, and hardware-specific boot/network configuration are never collected.
