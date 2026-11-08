# Create Aeronautics: one-step setup for Prism Launcher on Windows.
# Installs Prism (if missing), creates the "Create Aeronautics" instance (Minecraft 1.21.1, NeoForge 21.1.265),
# wires up the automatic mod sync, and adds the server to the server list. You still sign in with Microsoft inside Prism.
# Safe to re-run. It only touches Prism's own folder.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Instance = 'Create Aeronautics'
$PackUrl = 'https://raw.githubusercontent.com/loswastaken/create-aeronautics-pack/main/pack.toml'
$BootUrl = 'https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar'
$BootSha = 'a8fbb24dc604278e97f4688e82d3d91a318b98efc08d5dbfcbcbcab6443d116c'
$ServersB64 = 'CgAACQAHc2VydmVycwoAAAACCAACaXAAG2Rvcmt1bmlmeS5kdWNrZG5zLm9yZzoyNTU2OAgABG5hbWUAEkNyZWF0ZSBBZXJvbmF1dGljcwAIAAJpcAARMTAuMjQuNC4xNDM6MjU1NjgIAARuYW1lAB1DcmVhdGUgQWVyb25hdXRpY3MgKGhvbWUvVlBOKQAA'

function Say($m) { Write-Host ""; Write-Host "==> $m" }
$Data = if ($env:PRISM_DATA) { $env:PRISM_DATA } else { Join-Path $env:APPDATA 'PrismLauncher' }
$utf8 = New-Object System.Text.UTF8Encoding $false

$installed = (Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\PrismLauncher\prismlauncher.exe')) -or (Test-Path (Join-Path $Data 'prismlauncher.cfg'))
if (-not $env:SKIP_INSTALL -and -not $installed) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is missing. Install Prism from https://prismlauncher.org, then run this again.'
    }
    Say 'Installing Prism Launcher with winget'
    winget install --id PrismLauncher.PrismLauncher -e --accept-source-agreements --accept-package-agreements
}

$Dir = Join-Path $Data "instances\$Instance"
$Mc = Join-Path $Dir '.minecraft'
Say "Creating instance in $Dir"
New-Item -ItemType Directory -Force -Path $Mc | Out-Null
if (Get-Process -Name prismlauncher -ErrorAction SilentlyContinue) { throw 'Close Prism Launcher first, then run this again (it would overwrite the changes).' }
$cfgPath = Join-Path $Dir 'instance.cfg'
if (Test-Path $cfgPath) {
    Write-Host 'Instance already exists; refreshing its launch command.'
    $lines = @(Get-Content $cfgPath | Where-Object { $_ -notmatch '^(PreLaunchCommand|OverrideCommands)=' })
} else {
    $lines = @('InstanceType=OneSix', 'iconKey=default', 'name=Create Aeronautics')
    $pack = '{"components":[{"cachedName":"Minecraft","cachedVersion":"1.21.1","important":true,"uid":"net.minecraft","version":"1.21.1"},{"cachedName":"NeoForge","cachedRequires":[{"equals":"1.21.1","uid":"net.minecraft"}],"cachedVersion":"21.1.265","uid":"net.neoforged","version":"21.1.265"}],"formatVersion":1}'
    [IO.File]::WriteAllText((Join-Path $Dir 'mmc-pack.json'), $pack + "`n", $utf8)
}
# Prism 11 keeps the quotes literally, so write the command with plain quotes and no outer quotes or backslashes.
$lines += 'OverrideCommands=true'
$lines += ('PreLaunchCommand="$INST_JAVA" -jar packwiz-installer-bootstrap.jar ' + $PackUrl)
[IO.File]::WriteAllText($cfgPath, (($lines -join "`n") + "`n"), $utf8)

Say 'Downloading the mod sync tool'
$tmp = Join-Path $env:TEMP 'packwiz-installer-bootstrap.jar'
Invoke-WebRequest -UseBasicParsing -Uri $BootUrl -OutFile $tmp
$got = (Get-FileHash -Algorithm SHA256 $tmp).Hash.ToLower()
if ($got -ne $BootSha) { Remove-Item $tmp -Force; throw 'Checksum mismatch for the sync tool; stopping.' }
Move-Item -Force $tmp (Join-Path $Mc 'packwiz-installer-bootstrap.jar')

$servers = Join-Path $Mc 'servers.dat'
if (-not (Test-Path $servers)) {
    Say 'Adding the server to your server list'
    [IO.File]::WriteAllBytes($servers, [Convert]::FromBase64String($ServersB64))
}

Say 'Done.'
Write-Host "Next: open Prism Launcher, add your Microsoft account (Accounts, top right), pick the 'Create Aeronautics' instance and press Play."
Write-Host 'The first launch downloads the mods (a few minutes). Server: dorkunify.duckdns.org:25568'
