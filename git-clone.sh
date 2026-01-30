#!/bin/bash

REPO_URL="https://github.com/uncurated-tests/big-repo-1.git"
TARGET_DIR="cloned-repo"
DEPTH=10

echo "========================================"
echo "=== INSTALLING DIAGNOSTIC TOOLS ==="
echo "========================================"

# Install mtr and traceroute (Amazon Linux 2023 uses dnf)
echo "Installing mtr and traceroute via dnf..."
dnf install -y mtr traceroute 2>&1 || echo "dnf install failed (may not have permissions)"

# From here on, exit on errors for critical commands
set -e

echo ""
echo "========================================"
echo "=== NETWORK DIAGNOSTICS START ==="
echo "========================================"

# Check available tools
echo ""
echo "--- Available tools ---"
which mtr && echo "mtr: found" || echo "mtr: not found"
which traceroute && echo "traceroute: found" || echo "traceroute: not found"
which curl && echo "curl: found" || echo "curl: not found"
which git && echo "git: $(git --version)" || echo "git: not found"

# Basic network info
echo ""
echo "--- Network info ---"
cat /etc/hostname 2>/dev/null || echo "hostname: $(uname -n)" || echo "hostname not available"
cat /etc/resolv.conf 2>/dev/null || echo "resolv.conf not accessible"

# MTR tests (if available)
echo ""
echo "--- MTR to api.github.com (UDP) ---"
if command -v mtr &> /dev/null; then
  mtr -rwbz -c 10 api.github.com || echo "mtr failed"
else
  echo "mtr not installed, trying traceroute..."
  traceroute -m 15 api.github.com 2>/dev/null || echo "traceroute not available"
fi

echo ""
echo "--- MTR to api.github.com (TCP 443) ---"
if command -v mtr &> /dev/null; then
  mtr -rwbz -c 10 -T -P 443 api.github.com || echo "mtr TCP failed"
else
  echo "mtr not installed"
fi

echo ""
echo "--- MTR to github.com (TCP 443) ---"
if command -v mtr &> /dev/null; then
  mtr -rwbz -c 10 -T -P 443 github.com || echo "mtr TCP failed"
else
  echo "mtr not installed"
fi

echo ""
echo "--- MTR to iad.github-debug.com (UDP) ---"
if command -v mtr &> /dev/null; then
  mtr -rwbz -c 10 iad.github-debug.com || echo "mtr failed"
else
  echo "mtr not installed"
fi

echo ""
echo "--- MTR to iad.github-debug.com (TCP 443) ---"
if command -v mtr &> /dev/null; then
  mtr -rwbz -c 10 -T -P 443 iad.github-debug.com || echo "mtr TCP failed"
else
  echo "mtr not installed"
fi

# Curl timing test to GitHub
echo ""
echo "--- Curl timing to github.com ---"
curl -w "\n  time_namelookup: %{time_namelookup}\n  time_connect: %{time_connect}\n  time_appconnect: %{time_appconnect}\n  time_starttransfer: %{time_starttransfer}\n  time_total: %{time_total}\n  speed_download: %{speed_download}\n" \
  -o /dev/null -s https://github.com || echo "curl failed"

# Test download speed from GitHub (small file)
echo ""
echo "--- GitHub raw download test ---"
curl -w "  speed: %{speed_download} bytes/sec\n  time: %{time_total}s\n" \
  -o /dev/null -s https://raw.githubusercontent.com/uncurated-tests/big-repo-1/main/package.json || echo "curl download test failed"

echo ""
echo "========================================"
echo "=== NETWORK DIAGNOSTICS END ==="
echo "========================================"

echo ""
echo "========================================"
echo "=== GIT CLONE START ==="
echo "========================================"
echo "Repo: $REPO_URL"
echo "Depth: $DEPTH"
echo ""

# Clean up if exists
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Step 1: git init
echo "[1/3] git init --quiet"
START_INIT=$(date +%s.%N)
git init --quiet "$TARGET_DIR"
END_INIT=$(date +%s.%N)
echo "  Duration: $(echo "$END_INIT - $START_INIT" | bc)s"

# Step 2: git fetch with depth
echo ""
echo "[2/3] git fetch --progress --depth=$DEPTH $REPO_URL HEAD"
START_FETCH=$(date +%s.%N)
git -C "$TARGET_DIR" fetch --progress --depth="$DEPTH" "$REPO_URL" HEAD
END_FETCH=$(date +%s.%N)
FETCH_DURATION=$(echo "$END_FETCH - $START_FETCH" | bc)
echo "  Duration: ${FETCH_DURATION}s"

# Step 3: git reset --hard
echo ""
echo "[3/3] git reset --hard FETCH_HEAD"
START_RESET=$(date +%s.%N)
git -C "$TARGET_DIR" reset --hard FETCH_HEAD
END_RESET=$(date +%s.%N)
echo "  Duration: $(echo "$END_RESET - $START_RESET" | bc)s"

echo ""
echo "========================================"
echo "=== GIT CLONE END ==="
echo "========================================"

# Git sizer (if we can install it)
echo ""
echo "========================================"
echo "=== GIT-SIZER START ==="
echo "========================================"

cd "$TARGET_DIR"

# Try to download and run git-sizer
if curl -sL https://github.com/github/git-sizer/releases/download/v1.5.0/git-sizer-1.5.0-linux-amd64.tar.gz | tar xz 2>/dev/null; then
  echo "git-sizer installed, running..."
  ./git-sizer --verbose || echo "git-sizer failed"
else
  echo "Could not install git-sizer"
fi

cd ..

echo ""
echo "========================================"
echo "=== GIT-SIZER END ==="
echo "========================================"

echo ""
echo "========================================"
echo "=== SUMMARY ==="
echo "========================================"
echo "Git fetch duration: ${FETCH_DURATION}s"
echo "Files in repo:"
ls -la "$TARGET_DIR" | head -20
