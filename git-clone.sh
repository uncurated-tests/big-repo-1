#!/bin/bash
set -e

REPO_URL="https://github.com/uncurated-tests/big-repo-1.git"
TARGET_DIR="cloned-repo"
DEPTH=10

echo "Starting git clone (Vercel-style)..."
echo "  Repo: $REPO_URL"
echo "  Depth: $DEPTH"
echo ""

# Clean up if exists
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Step 1: git init
echo "[1/3] git init --quiet"
git init --quiet "$TARGET_DIR"

# Step 2: git fetch with depth
echo "[2/3] git fetch --progress --depth=$DEPTH $REPO_URL HEAD"
git -C "$TARGET_DIR" fetch --progress --depth="$DEPTH" "$REPO_URL" HEAD

# Step 3: git reset --hard
echo "[3/3] git reset --hard FETCH_HEAD"
git -C "$TARGET_DIR" reset --hard FETCH_HEAD

echo ""
echo "Clone complete!"
ls -la "$TARGET_DIR"
