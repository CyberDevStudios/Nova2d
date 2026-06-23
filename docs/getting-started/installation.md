# Installation

## Requirements

| Dependency | Version | Notes |
|---|---|---|
| Love2D | 11.x+ | [Download](https://love2d.org/) |
| curl | any | Included on Windows 10+, macOS, and most Linux distros |
| unzip | any | Required for multi-file libraries. Included on most systems |

## One-command install (v0.4+)

```bash
curl -fsSL https://raw.githubusercontent.com/CyberDevStudios/Nova2d/master/install.sh | bash -s my-game
```

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
