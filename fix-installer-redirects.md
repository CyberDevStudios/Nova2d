# Use `_redirects` to serve `install.sh` from the framework repo

## Problem

`curl -fsSL https://nova2d.pages.dev/install.sh | bash -s my-game` returns HTML (the docs page) instead of the shell script.

## Root cause

`install.sh` is in the **framework repo** (`CyberDevStudios/Nova2d`), but the docs site at `nova2d.pages.dev` deploys from a **separate repo** (`CyberDevStudios/Nova2dDocs`). Cloudflare Pages only serves files that are in the build output (`dist/`) of the docs repo.

Copying `install.sh` between repos would create drift. The correct solution is to tell Cloudflare Pages to proxy the file from the framework repo without duplicating it.

## Fix — Add `_redirects` file

Create `Page/public/_redirects` with this single rule:

```
/install.sh https://raw.githubusercontent.com/CyberDevStudios/Nova2d/main/install.sh 200
```

### Why this works

| Component | Role |
|---|---|
| `Page/public/_redirects` | Static file that Vite copies to `dist/` as-is |
| Cloudflare Pages `_redirects` | Native feature — intercepts requests and proxies content from another URL |
| `200` status code | Tells Cloudflare to serve the remote content **transparently** — the browser sees `nova2d.pages.dev/install.sh` as if it were a local file |

This is not a browser redirect. The user runs `curl -fsSL https://nova2d.pages.dev/install.sh` and gets the script content directly, with no 301/302 redirect.

### Why not copy the file

- Two copies of the same file in two repos → inevitable drift
- Every time you update the framework, you'd need to remember to copy the file to the docs repo
- A single source of truth (the framework repo) is the correct ownership model

### What to do

```bash
cd /home/matfon73/Nova2d/Page
cat > public/_redirects << 'EOF'
/install.sh https://raw.githubusercontent.com/CyberDevStudios/Nova2d/main/install.sh 200
EOF

git add public/_redirects
# Optionally remove the old install.sh if it still lives here
git rm install.sh 2>/dev/null || true
git commit -m "fix: proxy install.sh from framework repo via _redirects"
git push origin main
```

After the deploy, test:

```bash
curl -fsSL https://nova2d.pages.dev/install.sh | head -3
```

Expected output: `#!/usr/bin/env bash`

### Caveat

If the framework repo ever changes its default branch from `main` to something else, update the URL in `_redirects`. Otherwise this is a one-time fix.
