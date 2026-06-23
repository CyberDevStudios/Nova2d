# Installer

Nova2D provides a one-command installer that sets up a complete project with a single curl command.

> Status: v0.4 — planned.

## One command

```bash
curl -fsSL https://nova2d.dev/install.sh | bash
```

## What it does

1. Detects your operating system (Linux, macOS, Windows)
2. Verifies Love2D 11.x is installed
3. Downloads the latest Nova2D release from GitHub
4. Creates the full project structure in the current directory
5. Installs default dependencies (bump.lua, anim8, hump, lurker, lovebird)
6. Prints a welcome message with next steps

## Result

```bash
> Nova2D installed successfully
> 5 dependencies installed
> Project ready

Run: love .
```

## Manual alternative

If you prefer not to pipe curl to bash:

```bash
# Clone the repository
git clone https://github.com/CyberDevStudios/Nova2d.git my-game

# Or download the latest release ZIP from GitHub
```

## Requirements

| Requirement | Version | How to verify |
|---|---|---|
| Love2D | 11.x | `love --version` |
| curl | any | `curl --version` |
| bash | 4.x+ | `bash --version` (Windows: Git Bash or WSL) |
