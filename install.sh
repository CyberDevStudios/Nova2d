#!/usr/bin/env bash
#
# Nova2D Installer
# Usage: curl -fsSL https://nova2d.pages.dev/install.sh | bash
# Or:    curl -fsSL https://nova2d.pages.dev/install.sh | bash -s my-game
#
set -e

PROJECT_NAME="${1:-my-game}"
REPO="CyberDevStudios/Nova2d"
INSTALL_DIR="$PROJECT_NAME"

# ──────────────────────────────────────────────
# Colors
# ──────────────────────────────────────────────
printf -v RED   '\033[0;31m'
printf -v GREEN '\033[0;32m'
printf -v YELLOW '\033[1;33m'
printf -v BOLD  '\033[1m'
printf -v NC    '\033[0m'

info()  { printf "  ${GREEN}${BOLD}→${NC} %s\n" "$1"; }
warn()  { printf "  ${YELLOW}${BOLD}→${NC} %s\n" "$1"; }
error() { printf "  ${RED}${BOLD}✖${NC} %s\n" "$1"; }

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
        MINGW*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

OS=$(detect_os)

# ──────────────────────────────────────────────
# Check dependencies
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

check_love() {
    local found=0

    case "$OS" in
        linux|wsl)
            if command -v love >/dev/null 2>&1; then found=1; fi
            ;;
        macos)
            if command -v love >/dev/null 2>&1; then
                found=1
            elif [ -f "/Applications/love.app/Contents/MacOS/love" ]; then
                found=1
            fi
            ;;
        windows)
            # Git Bash (MSYS2) may not find .exe via command -v
            if command -v love >/dev/null 2>&1 \
                || command -v love.exe >/dev/null 2>&1 \
                || which love >/dev/null 2>&1 \
                || which love.exe >/dev/null 2>&1; then
                found=1
            elif [ -f "/c/Program Files/LOVE/love.exe" ] \
                || [ -f "/c/Program Files (x86)/LOVE/love.exe" ]; then
                found=1
            fi
            ;;
    esac

    if [ "$found" -eq 0 ]; then
        warn "Love2D is not installed."
        case "$OS" in
            linux)  info "Download: https://love2d.org/  or  sudo apt install love" ;;
            macos)  info "Download: https://love2d.org/" ;;
            windows) info "Download: https://love2d.org/" ;;
        esac
        info "Install Love2D first, then re-run this script."
        exit 1
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

   ${BOLD}Created by Cyber Dev Studios${NC}

   ${BOLD}Documentation:${NC}
     https://nova2d.pages.dev/

${BOLD}──────────────────────────────────────────────${NC}

EOF
}

# ──────────────────────────────────────────────
# Download framework
# ──────────────────────────────────────────────
download_framework() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local archive="$tmp_dir/nova2d.tar.gz"
    local url

    info "Downloading Nova2D..."

    # Try GitHub release API first, fall back to archive
    url=$(curl -fsSL --connect-timeout 10 \
        "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
        | grep '"tarball_url"' \
        | head -1 \
        | sed 's/.*"tarball_url": "\([^"]*\)".*/\1/' \
        2>/dev/null || true)

    if [ -z "$url" ]; then
        info "Using latest commit (no release tag found)"
        url="https://github.com/$REPO/archive/refs/heads/master.tar.gz"
    fi

    if ! curl -fsSL --connect-timeout 15 --max-time 60 "$url" -o "$archive" 2>/dev/null; then
        error "Failed to download Nova2D. Check your internet connection."
        exit 1
    fi

    # Extract
    info "Extracting..."
    tar -xzf "$archive" -C "$tmp_dir" 2>/dev/null

    # The archive creates a directory like Nova2d-{commit}
    local extracted
    extracted=$(ls -d "$tmp_dir"/*/ 2>/dev/null | head -1)

    if [ -z "$extracted" ]; then
        error "Failed to extract archive."
        exit 1
    fi

    # Remove the extracted directory name — we want just the contents
    mkdir -p "$INSTALL_DIR"
    cp -r "$extracted"* "$INSTALL_DIR/" 2>/dev/null || true
    cp -r "$extracted".* "$INSTALL_DIR/" 2>/dev/null || true
    cp "$extracted"* "$INSTALL_DIR/" 2>/dev/null || true

    # Cleanup
    rm -rf "$tmp_dir"

    if [ ! -f "$INSTALL_DIR/main.lua" ]; then
        error "Installation failed: core files not found."
        exit 1
    fi

    info "Project created at ./$PROJECT_NAME"
}

# ──────────────────────────────────────────────
# Install dependencies
# ──────────────────────────────────────────────
install_deps() {
    if command -v love >/dev/null 2>&1; then
        info "Installing default dependencies..."
        (cd "$INSTALL_DIR" && love gestor/ install 2>/dev/null) || true
        info "Dependencies ready."
    fi
}

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
main() {
    echo ""
    info "Nova2D Installer"

    if [ -d "$INSTALL_DIR" ]; then
        error "Directory '$INSTALL_DIR' already exists."
        info "Choose a different name: curl -fsSL ... | bash -s my-other-game"
        exit 1
    fi

    check_curl
    check_love
    check_unzip
    download_framework
    install_deps
    welcome
}

main "$@"
