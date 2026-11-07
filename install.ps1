# Nova2D Installer — Windows (PowerShell 5.1+)
#
# Usage:
#   .\install.ps1
#   .\install.ps1 my-game
#   .\install.ps1 my-game -Version v0.8.0
#
# Always read a downloaded script before running it:
#   Invoke-WebRequest https://nova2d.dev/install.ps1 -OutFile install.ps1
#   notepad install.ps1
#   .\install.ps1 my-game

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectName = "my-game",

    [string]$Version = ""
)

$ErrorActionPreference = "Stop"
$Repo = "CyberDevStudios/Nova2d"

function Write-Info($Message) { Write-Host "  -> $Message" -ForegroundColor Green }
function Write-Warn($Message) { Write-Host "  -> $Message" -ForegroundColor Yellow }
function Write-Err($Message)  { Write-Host "  x  $Message" -ForegroundColor Red }

function Resolve-Url {
    if ($Version) {
        return "https://github.com/$Repo/archive/refs/tags/$Version.tar.gz"
    }

    try {
        $release = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$Repo/releases/latest" `
            -Headers @{ "User-Agent" = "nova2d-installer" } `
            -TimeoutSec 15
        if ($release.tarball_url) { return $release.tarball_url }
    } catch {
        # No stable release yet — fall through to main.
    }

    Write-Warn "No stable release found; installing the main branch."
    Write-Warn "Use -Version <tag> to pin a release."
    return "https://github.com/$Repo/archive/refs/heads/main.tar.gz"
}

function Test-Love {
    $candidates = @(
        (Get-Command love -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
        (Get-Command love.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
        "C:\Program Files\LOVE\love.exe",
        "C:\Program Files (x86)\LOVE\love.exe"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    return $null
}

# ── Main ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Info "Nova2D Installer"

if (Test-Path $ProjectName) {
    Write-Err "Directory '$ProjectName' already exists."
    Write-Info "Choose a different name: .\install.ps1 my-other-game"
    exit 1
}

if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
    Write-Err "tar is required but not found. Windows 10 1803+ ships it."
    Write-Err "Alternatively install 7-Zip and extract the archive manually."
    exit 1
}

$love = Test-Love
if (-not $love) {
    Write-Warn "Love2D is not installed."
    Write-Info "Download: https://love2d.org/"
    Write-Info "Install Love2D first, then re-run this script."
    exit 1
}

$tmp = Join-Path $env:TEMP ("nova2d-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    $url = Resolve-Url
    $archive = Join-Path $tmp "nova2d.tar.gz"

    if ($Version) {
        Write-Info "Downloading Nova2D $Version..."
    } else {
        Write-Info "Downloading Nova2D..."
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
    } catch {
        Write-Err "Failed to download Nova2D. Check your internet connection."
        if ($Version) {
            Write-Err "Does tag '$Version' exist? See https://github.com/$Repo/tags"
        }
        exit 1
    }

    Write-Info "Extracting..."
    tar -xzf $archive -C $tmp
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to extract archive."
        exit 1
    }

    $extracted = Get-ChildItem -Path $tmp -Directory | Select-Object -First 1
    if (-not $extracted -or -not (Test-Path (Join-Path $extracted.FullName "main.lua"))) {
        Write-Err "Installation failed: core files not found."
        exit 1
    }

    New-Item -ItemType Directory -Path $ProjectName | Out-Null
    Copy-Item -Path (Join-Path $extracted.FullName "*") -Destination $ProjectName -Recurse -Force
    Write-Info "Project created at .\$ProjectName"
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Info "Installing default dependencies..."
Push-Location $ProjectName
try {
    & $love "gestor/" "install"
} catch {
    Write-Warn "Could not install dependencies automatically. Run: cd $ProjectName; love gestor/ install"
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "── Nova2D ────────────────────────────────────"
Write-Host "   Framework for Love2D"
Write-Host "   Installed successfully" -ForegroundColor Green
Write-Host ""
Write-Host "   Next steps:"
Write-Host "     cd $ProjectName"
Write-Host "     love ."
Write-Host ""
Write-Host "   Documentation:"
Write-Host "     https://nova2d.dev/"
Write-Host "     https://github.com/$Repo"
Write-Host "──────────────────────────────────────────────"
Write-Host ""
