# Fix: `nova2d.dev/install.sh` not serving the script

## Problem

Running the documented install command:

```bash
curl -fsSL https://nova2d.dev/install.sh | bash -s my-game
```

returns HTML instead of the shell script, producing:

- **PowerShell**: `Invoke-WebRequest : A parameter cannot be found that matches parameter name 'fsSL'`
- **bash**: `bash: line 1: syntax error near unexpected token 'newline'`

## Root cause

`install.sh` lives at the **root** of the `Page/` directory (`Page/install.sh`), but Vite only copies files from `public/` to `dist/` during the build. Cloudflare Pages deploys the contents of `dist/`, so `install.sh` is never published.

This broke when the last deploy was made because the file was never included in the build output — it only worked before if the file happened to be manually placed in `dist/` or was served by a previous Cloudflare configuration that no longer applies.

## Fix

Move `install.sh` into `Page/public/` so Vite copies it to `dist/` on every build:

```bash
cd /home/matfon73/Nova2d/Page
mv install.sh public/install.sh
git add public/install.sh
git rm install.sh
git commit -m "fix: move install.sh to public/ so Cloudflare Pages serves it"
git push origin main
```

After the push, Cloudflare Pages auto-deploys and `https://nova2d.dev/install.sh` starts serving the script again.

## Why this works

| Directory | Role |
|---|---|
| `Page/` (root) | Vite project root, NOT deployed |
| `Page/public/` | Static files — Vite copies everything here into `dist/` as-is |
| `Page/dist/` | Build output — this is what Cloudflare Pages deploys |

Files in `public/` are copied verbatim to `dist/` during `vite build`. By moving `install.sh` there, it becomes part of every deploy automatically.

## Prevention

Any static file that needs to be served at the root of `nova2d.dev` must go in `Page/public/`. Examples:

- `public/install.sh`
- `public/robots.txt`
- `public/favicon.svg`

## Verification

After the deploy completes, test with:

```bash
curl -fsSL https://nova2d.dev/install.sh | head -5
```

Expected output starts with `#!/usr/bin/env bash`.
