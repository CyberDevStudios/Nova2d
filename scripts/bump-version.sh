#!/usr/bin/env bash
# Nova2D — Version Bump Script
# scripts/bump-version.sh
#
# Extracts the latest version from docs/community/changelog.md and
# propagates it to all files that need the current framework version.
#
# Usage: bash scripts/bump-version.sh
#
# Files updated (Category A — "current version"):
#   - src/version.lua        (runtime version for splash/menu)
#   - nova2d.lua             (project manifest, read by website build)
#   - docs/guides/installer.md  (installer status line)
#
# Files with "available from vX+" convention (Category B) are NOT
# touched by this script — they track feature-introduced-in versions,
# not the current framework version.

set -euo pipefail

CHANGELOG="docs/community/changelog.md"

# ---- Extract latest version from changelog ----
# Looks for the first "## vX.Y.Z" heading in the changelog
LATEST=$(grep -m1 '^## v[0-9]\+\.[0-9]\+\.[0-9]' "$CHANGELOG" \
    | sed 's/^## v//' \
    | sed 's/ .*//')

if [ -z "$LATEST" ]; then
    echo "ERROR: could not extract latest version from $CHANGELOG"
    echo "Expected a line like: ## v0.6.1 — Some Title"
    exit 1
fi

echo "=== Bumping to v$LATEST ==="

# ---- 1. src/version.lua ----
sed -i 's/return "[0-9.]*"/return "'"$LATEST"'"/' src/version.lua
echo "  → src/version.lua  (v$LATEST)"

# ---- 2. nova2d.lua ----
sed -i 's/version = "[0-9.]*"/version = "'"$LATEST"'"/' nova2d.lua
echo "  → nova2d.lua       (v$LATEST)"

# ---- 3. docs/guides/installer.md ----
# Replaces "Status: vX.Y" or "Status: vX.Y.Z" with the new version
sed -i 's/^> Status: v[0-9.]* — /> Status: v'"$LATEST"' — /' docs/guides/installer.md
echo "  → docs/guides/installer.md  (v$LATEST)"

# ---- 4. Nova2dDocs website (index.html) ----
DOCS_REPO="../../Nova2d/Page"  # sibling dir — update path if moved
if [ -f "$DOCS_REPO/index.html" ]; then
    sed -i 's/v[0-9.]*<\(\/sup>\|<\/span>\)/v'"$LATEST"'<\1/' "$DOCS_REPO/index.html"
    echo "  → $DOCS_REPO/index.html  (v$LATEST)"
else
    echo "  ⚠ Nova2dDocs repo not found at $DOCS_REPO — skipping"
fi

echo ""
echo "=== Done. All current-version references updated to v$LATEST ==="
echo ""
echo "Next steps:"
echo "  1. cd ../Nova2d/Page && git add index.html && git commit -m \"chore: bump version to v$LATEST\" && git push origin main"
echo "  2. cd - && git add . && git commit -m \"chore: bump version to v$LATEST\" && git push"
