# Create Aeronautics pack

packwiz pack for Los's server: Minecraft 1.21.1, NeoForge 21.1.265, Create, Sable, Create Aeronautics, plus Sodium (client only) for performance. Links only, no mod files.

## Quick setup (one command)
Windows (PowerShell):

    irm https://raw.githubusercontent.com/loswastaken/create-aeronautics-pack/main/join.ps1 | iex

macOS / Linux:

    curl -fsSL https://raw.githubusercontent.com/loswastaken/create-aeronautics-pack/main/join.sh | bash

It installs Prism Launcher if needed, creates the instance, sets up the mod sync and adds the server. Then open Prism, sign in with your Microsoft account, and press Play. Read `join.ps1` / `join.sh` first if you like; they only touch Prism's own folder.

## Manual setup
1. Create a Prism instance: Minecraft 1.21.1, NeoForge 21.1.265 (Java 21).
2. Download https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar into the instance's `.minecraft` folder.
3. Instance Settings > Custom commands > Pre-launch command:
   `"$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/loswastaken/create-aeronautics-pack/main/pack.toml`
4. Launch. Mods sync on every launch.
