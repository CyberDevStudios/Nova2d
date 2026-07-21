# Installation

## Requirements

| Dependency | Version | Notes |
|---|---|---|
| Love2D | 11.x+ | [Download](https://love2d.org/) |
| curl | any | Included on Windows 10+, macOS, and most Linux distros |
| unzip | any | Required for multi-file libraries. Included on most systems |

> On Windows, use Git Bash or WSL for gestor commands when possible. The gestor now handles Windows path quoting and archive cleanup safely, but `curl` and `unzip` are still required for dependency installs.

## One-command install (v0.4+)

```bash
# Windows users: use Git Bash, not PowerShell (curl alias conflict)
curl -fsSL https://nova2d.dev/install.sh | bash -s my-game
```

> **PowerShell gotcha**: PowerShell has a built-in `curl` alias that maps to `Invoke-WebRequest` and doesn't support `-fsSL` flags. Use Git Bash, WSL, or the manual install below.

This will:
1. Detect your operating system
2. Verify Love2D is installed
3. Download the latest Nova2D release
4. Create the project structure in the current directory
5. Install default dependencies

## Manual install

Clone the repository:

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
love .
```

## Verifying the install

Run `love .` from your project directory. You should see:
1. The Nova2D splash screen with animated logo and particle effects
2. The main menu after 3 seconds (or press any key to skip)
3. Working keyboard and mouse navigation
