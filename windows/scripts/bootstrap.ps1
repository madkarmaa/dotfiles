function Info { param([string]$Message) Write-Host "[i] $Message" }
function Success { param([string]$Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Warning { param([string]$Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Failure { param([string]$Message) Write-Host "[-] $Message" -ForegroundColor Red }

$REPO_URL = "https://github.com/madkarmaa/dotfiles.git"
$BOOTSTRAP_URL = "https://raw.githubusercontent.com/madkarmaa/dotfiles/refs/heads/main/windows/scripts/bootstrap.ps1"
$TARGET_DIR = "$env:USERPROFILE\.dotfiles"

function IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function RelaunchAsAdmin {
    Start-Process powershell.exe -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm '$BOOTSTRAP_URL' | iex") -Verb RunAs
    exit
}

if (-not (IsAdmin)) {
    RelaunchAsAdmin
}

$OriginalProgressPreference = $ProgressPreference
$ProgressPreference = "SilentlyContinue"

if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Warning "Git is not installed. Installing..."
    winget install -e --id Git.Git --source winget
}

if (-not (Test-Path $TARGET_DIR)) {
    Info "Cloning dotfiles repository..."
    git.exe clone $REPO_URL $TARGET_DIR --depth 1
} else {
    Info "Updating dotfiles repository..."
    git.exe -C $TARGET_DIR pull --ff-only
}

if (-not (Test-Path "$TARGET_DIR\windows\scripts\apply.ps1")) {
    Failure "Failed to clone repository. Please check your internet connection."
    Write-Host "`nPress any key to exit..."
    [void][System.Console]::ReadKey($true)
    exit 1
}

$ProgressPreference = $OriginalProgressPreference

& "$TARGET_DIR\windows\scripts\apply.ps1"
