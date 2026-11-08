#!/usr/bin/env bash
# Create Aeronautics: one-step setup for Prism Launcher on macOS/Linux.
# Installs Prism (if missing), creates the "Create Aeronautics" instance (Minecraft 1.21.1, NeoForge 21.1.265),
# wires up the automatic mod sync, and adds the server to the server list. You still sign in with Microsoft inside Prism.
# Safe to re-run. Read it first if you like; it only touches Prism's own folders.
set -euo pipefail
INSTANCE="Create Aeronautics"
PACK_URL="https://raw.githubusercontent.com/loswastaken/create-aeronautics-pack/main/pack.toml"
BOOT_URL="https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar"
BOOT_SHA="a8fbb24dc604278e97f4688e82d3d91a318b98efc08d5dbfcbcbcab6443d116c"
SERVERS_B64="CgAACQAHc2VydmVycwoAAAACCAACaXAAG2Rvcmt1bmlmeS5kdWNrZG5zLm9yZzoyNTU2OAgABG5hbWUAEkNyZWF0ZSBBZXJvbmF1dGljcwAIAAJpcAARMTAuMjQuNC4xNDM6MjU1NjgIAARuYW1lAB1DcmVhdGUgQWVyb25hdXRpY3MgKGhvbWUvVlBOKQAA"

say() { printf '\n==> %s\n' "$*"; }
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
  DATA="${PRISM_DATA:-$HOME/Library/Application Support/PrismLauncher}"
  if [ -z "${SKIP_INSTALL:-}" ] && [ ! -d "/Applications/Prism Launcher.app" ] && [ ! -d "$HOME/Applications/Prism Launcher.app" ]; then
    say "Installing Prism Launcher with Homebrew"
    command -v brew >/dev/null || { echo "Homebrew is missing. Install Prism from https://prismlauncher.org, then run this again."; exit 1; }
    brew install --cask prismlauncher
  fi
elif [ "$OS" = "Linux" ]; then
  FLATDATA="$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher"
  if [ -z "${SKIP_INSTALL:-}" ] && ! command -v prismlauncher >/dev/null && ! { command -v flatpak >/dev/null && flatpak info org.prismlauncher.PrismLauncher >/dev/null 2>&1; }; then
    command -v flatpak >/dev/null || { echo "Install Prism from https://prismlauncher.org (or your package manager), then run this again."; exit 1; }
    say "Installing Prism Launcher with Flatpak"
    flatpak install -y flathub org.prismlauncher.PrismLauncher
  fi
  if [ -n "${PRISM_DATA:-}" ]; then DATA="$PRISM_DATA"
  elif command -v flatpak >/dev/null && flatpak info org.prismlauncher.PrismLauncher >/dev/null 2>&1; then DATA="$FLATDATA"
  else DATA="${XDG_DATA_HOME:-$HOME/.local/share}/PrismLauncher"; fi
else
  echo "Unsupported system: $OS (on Windows use join.ps1)"; exit 1
fi

DIR="$DATA/instances/$INSTANCE"
MC="$DIR/.minecraft"
say "Creating instance in $DIR"
mkdir -p "$MC"
if [ ! -f "$DIR/instance.cfg" ]; then
  cat > "$DIR/instance.cfg" <<'CFG'
InstanceType=OneSix
iconKey=default
name=Create Aeronautics
OverrideCommands=true
PreLaunchCommand="\"$INST_JAVA\" -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/loswastaken/create-aeronautics-pack/main/pack.toml"
CFG
  cat > "$DIR/mmc-pack.json" <<'PACK'
{"components":[{"cachedName":"Minecraft","cachedVersion":"1.21.1","important":true,"uid":"net.minecraft","version":"1.21.1"},{"cachedName":"NeoForge","cachedRequires":[{"equals":"1.21.1","uid":"net.minecraft"}],"cachedVersion":"21.1.265","uid":"net.neoforged","version":"21.1.265"}],"formatVersion":1}
PACK
else
  echo "Instance already exists; keeping its settings."
fi

say "Downloading the mod sync tool"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
curl -fsSL "$BOOT_URL" -o "$TMP"
if command -v sha256sum >/dev/null; then GOT="$(sha256sum "$TMP" | cut -d' ' -f1)"; else GOT="$(shasum -a 256 "$TMP" | cut -d' ' -f1)"; fi
[ "$GOT" = "$BOOT_SHA" ] || { echo "Checksum mismatch for the sync tool; stopping."; exit 1; }
cp "$TMP" "$MC/packwiz-installer-bootstrap.jar"

if [ ! -f "$MC/servers.dat" ]; then
  say "Adding the server to your server list"
  printf '%s' "$SERVERS_B64" | base64 -d > "$MC/servers.dat"
fi

say "Done."
echo "Next: open Prism Launcher, add your Microsoft account (Accounts, top right), pick the 'Create Aeronautics' instance and press Play."
echo "The first launch downloads the mods (a few minutes). Server: dorkunify.duckdns.org:25568"
