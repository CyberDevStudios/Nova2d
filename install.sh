#!/usr/bin/env bash
#
# Nova2D Installer
#
# Usage:
#   curl -fsSL https://nova2d.dev/install.sh | bash
#   curl -fsSL https://nova2d.dev/install.sh | bash -s my-game
#   curl -fsSL https://nova2d.dev/install.sh | bash -s my-game --version v0.8.0
#
# Always read a piped script before running it:
#   curl -fsSL https://nova2d.dev/install.sh -o install.sh
#   less install.sh
#   bash install.sh my-game
#
set -euo pipefail

PROJECT_NAME="my-game"
VERSION=""
REPO="CyberDevStudios/Nova2d"
INSTALL_DIR=""

# ──────────────────────────────────────────────
# Arguments
# ──────────────────────────────────────────────
usage() {
    cat <<EOF
Nova2D installer

Usage: install.sh [project-name] [--version <tag>]

  project-name    Directory to create (default: my-game)
  --version       Release tag to install (default: latest stable)
  -h, --help      Show this help

Examples:
  install.sh
  install.sh my-game
  install.sh my-game --version v0.8.0
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                    echo "error: --version requires a tag (e.g. v0.8.0)" >&2
                    exit 1
                fi
                VERSION="$2"
                shift 2
                ;;
            --version=*)
                VERSION="${1#--version=}"
                shift
                ;;
            -*)
                echo "error: unknown option '$1'" >&2
                usage >&2
                exit 1
                ;;
            *)
                PROJECT_NAME="$1"
                shift
                ;;
        esac
    done

    if [ -z "$PROJECT_NAME" ]; then
        echo "error: project name cannot be empty" >&2
        exit 1
    fi
    INSTALL_DIR="$PROJECT_NAME"
}

# ──────────────────────────────────────────────
# Colors
# ──────────────────────────────────────────────
if [ -t 1 ]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
else
    RED="" GREEN="" YELLOW="" BOLD="" NC=""
fi

info()  { printf "  ${GREEN}${BOLD}→${NC} %s\n" "$1"; }
warn()  { printf "  ${YELLOW}${BOLD}→${NC} %s\n" "$1"; }
error() { printf "  ${RED}${BOLD}✖${NC} %s\n" "$1" >&2; }

# ──────────────────────────────────────────────
# Detect OS
# ──────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin) echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

OS=$(detect_os)

# ──────────────────────────────────────────────
# Checks
# ──────────────────────────────────────────────
check_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required but not found."
        case "$OS" in
            linux)  info "Install: sudo apt install curl  (Debian/Ubuntu)" ;;
            macos)  info "Install: brew install curl" ;;
            windows) info "Download: https://curl.se/windows/" ;;
        esac
        exit 1
    fi
}

check_tar() {
    if ! command -v tar >/dev/null 2>&1; then
        error "tar is required but not found."
        exit 1
    fi
}

check_love() {
    local found=0

    case "$OS" in
        linux|wsl)
            command -v love >/dev/null 2>&1 && found=1
            ;;
        macos)
            if command -v love >/dev/null 2>&1 \
                || [ -f "/Applications/love.app/Contents/MacOS/love" ]; then
                found=1
            fi
            ;;
        windows)
            if command -v love >/dev/null 2>&1 \
                || command -v love.exe >/dev/null 2>&1 \
                || [ -f "/c/Program Files/LOVE/love.exe" ] \
                || [ -f "/c/Program Files (x86)/LOVE/love.exe" ]; then
                found=1
            fi
            ;;
    esac

    if [ "$found" -eq 0 ]; then
        warn "Love2D is not installed."
        case "$OS" in
            linux)  info "Download: https://love2d.org/  or  sudo apt install love" ;;
            macos|windows) info "Download: https://love2d.org/" ;;
        esac
        info "Install Love2D first, then re-run this script."
        exit 1
    fi
}

check_unzip() {
    if ! command -v unzip >/dev/null 2>&1; then
        warn "unzip is recommended but not found."
        info "Some dependencies (anim8, hump, lurker, lovebird) need unzip."
        case "$OS" in
            linux)  info "Install: sudo apt install unzip  (Debian/Ubuntu)" ;;
            macos)  info "Install: brew install unzip" ;;
            windows) info "Install: https://infozip.sourceforge.net/" ;;
        esac
    fi
}

# ──────────────────────────────────────────────
# Download
# ──────────────────────────────────────────────
# Resolve the tarball URL. With --version, download that exact tag.
# Without it, ask GitHub for the latest release; if the repository has no
# stable release yet, fall back to the main branch with a warning.
resolve_url() {
    if [ -n "$VERSION" ]; then
        echo "https://github.com/$REPO/archive/refs/tags/$VERSION.tar.gz"
        return
    fi

    local url
    url=$(curl -fsSL --connect-timeout 10 \
        "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
        | grep '"tarball_url"' | head -1 \
        | sed 's/.*"tarball_url": "\([^"]*\)".*/\1/' 2>/dev/null || true)

    if [ -n "$url" ]; then
        echo "$url"
        return
    fi

    warn "No stable release found; installing the main branch."
    warn "Use --version <tag> to pin a release."
    echo "https://github.com/$REPO/archive/refs/heads/main.tar.gz"
}

download_framework() {
    local tmp_dir archive url extracted
    tmp_dir=$(mktemp -d)
    archive="$tmp_dir/nova2d.tar.gz"
    trap 'rm -rf "'"$tmp_dir"'"' EXIT

    url=$(resolve_url)
    if [ -n "$VERSION" ]; then
        info "Downloading Nova2D $VERSION..."
    else
        info "Downloading Nova2D..."
    fi

    if ! curl -fsSL --connect-timeout 15 --max-time 120 "$url" -o "$archive"; then
        error "Failed to download Nova2D. Check your internet connection."
        [ -n "$VERSION" ] && error "Does tag '$VERSION' exist? See https://github.com/$REPO/tags"
        exit 1
    fi

    info "Extracting..."
    if ! tar -xzf "$archive" -C "$tmp_dir"; then
        error "Failed to extract archive."
        exit 1
    fi

    extracted=$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d | head -1)
    if [ -z "$extracted" ] || [ ! -f "$extracted/main.lua" ]; then
        error "Installation failed: core files not found."
        exit 1
    fi

    mkdir -p "$INSTALL_DIR"
    # `/.` copies the directory contents, including dotfiles.
    cp -R "$extracted"/. "$INSTALL_DIR"/

    info "Project created at ./$INSTALL_DIR"
}

# ──────────────────────────────────────────────
# Dependencies
# ──────────────────────────────────────────────
install_deps() {
    if command -v love >/dev/null 2>&1; then
        info "Installing default dependencies..."
        (cd "$INSTALL_DIR" && love gestor/ install 2>/dev/null) || \
            warn "Could not install dependencies automatically. Run: cd $INSTALL_DIR && love gestor/ install"
        info "Dependencies ready."
    fi
}

welcome() {
    cat <<EOF

${BOLD}── Nova2D ────────────────────────────────────${NC}
   Framework for Love2D
   ${GREEN}✓ Installed successfully${NC}

   ${BOLD}Next steps:${NC}
     cd $PROJECT_NAME
     love .

   ${BOLD}Documentation:${NC}
     https://nova2d.dev/
     https://github.com/$REPO

${BOLD}──────────────────────────────────────────────${NC}

EOF
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
    parse_args "$@"

    echo ""
    info "Nova2D Installer"

    if [ -d "$INSTALL_DIR" ]; then
        error "Directory '$INSTALL_DIR' already exists."
        info "Choose a different name: install.sh my-other-game"
        exit 1
    fi

    check_curl
    check_tar
    check_love
    check_unzip
    download_framework
    install_deps
    welcome
}

main "$@"
