# Installer

Nova2D provides a one-command installer for Linux, macOS and Windows. It creates a
complete project with the framework, assets and dependencies.

## Read before you run

Piping a script straight into a shell executes code you have not seen. Download it first:

```bash
curl -fsSL https://nova2d.dev/install.sh -o install.sh
less install.sh          # read it
bash install.sh my-game
```

The script only:

1. downloads a GitHub source archive
2. extracts it into a new directory
3. runs `love gestor/ install` inside that directory

Verify the download against the published checksum:

```bash
curl -fsSL https://nova2d.dev/install.sh.sha256 -o install.sh.sha256
sha256sum -c install.sh.sha256
```

## Usage

```bash
# Latest stable release
curl -fsSL https://nova2d.dev/install.sh | bash

# Named project
curl -fsSL https://nova2d.dev/install.sh | bash -s my-game

# Pin a release
curl -fsSL https://nova2d.dev/install.sh | bash -s my-game --version v0.8.0
```

The positional argument is the project directory (default `my-game`). `--version` accepts
any published tag; without it the installer asks GitHub for the latest release.

If the repository has no stable release yet, the script warns and installs the `main`
branch instead of failing.

## Windows

Use **PowerShell 5.1+**, not the `curl` alias from older PowerShell versions:

```powershell
Invoke-WebRequest https://nova2d.dev/install.ps1 -OutFile install.ps1
notepad install.ps1
.\install.ps1 my-game
```

Pin a release with `-Version v0.8.0`. The PowerShell installer requires `tar.exe`
(shipped with Windows 10 1803+) and Love2D installed.

> The bash installer also works under **Git Bash** and **WSL**. Native PowerShell aliases
> (`curl` → `Invoke-WebRequest`) do not accept the same flags.

## What it does

1. Detects the operating system
2. Verifies Love2D 11.x is installed (and warns about missing `unzip`)
3. Downloads the requested release (or `main` as a fallback)
4. Creates the project directory and extracts the archive
5. Runs `love gestor/ install` to fetch default dependencies
6. Prints the next steps

## Result

```bash
> Nova2D installed successfully
> Project created at ./my-game
> Dependencies ready

Next steps:
  cd my-game
  love .
```

## Manual alternative

If you prefer not to run a script:

```bash
git clone https://github.com/CyberDevStudios/Nova2d.git my-game
cd my-game
love gestor/ install
```

Or download a tag archive from
<https://github.com/CyberDevStudios/Nova2d/tags> and extract it.

## Requirements

| Requirement | Version | How to verify |
|---|---|---|
| Love2D | 11.x | `love --version` |
| curl | any | `curl --version` |
| unzip | any | `unzip --version` (multi-file deps like anim8, hump) |
| tar | any | `tar --version` |
| bash | 4.x+ | `bash --version` (Windows: Git Bash or WSL) |

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Directory 'my-game' already exists` | Target exists | Pick another name |
| `Love2D is not installed` | `love` not on `PATH` | Install from <https://love2d.org/> and reopen the terminal |
| `No stable release found` | No release published yet | Expected; the installer uses `main`. Use `--version` to pin a tag |
| `Failed to download` | Network/tag error | Check connectivity and that the tag exists |
| Dependencies missing after install | `love gestor/ install` failed | `cd my-game && love gestor/ install` |
