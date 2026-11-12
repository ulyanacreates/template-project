#!/usr/bin/env bash
# devserver.sh — bootstrap the raw devserver VPS (Ubuntu 24.04, user `dev`).
# Installs claude code, omp, ovnfs, uv; adds the superpowers skills (own fork)
# to both harnesses. User-level only, no sudo. Idempotent: safe to re-run.
# Usage: ssh devserver 'bash -s' < setup/devserver.sh
set -euo pipefail

SUPERPOWERS_REPO="ulyanacreates/superpowers"
SUPERPOWERS_PLUGIN="superpowers@superpowers-dev"

die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "run as the normal user, not root"
command -v curl >/dev/null || die "curl is required"
command -v git  >/dev/null || die "git is required"
command -v fusermount3 >/dev/null || \
  echo "WARN: fusermount3 missing — ovnfs needs 'sudo apt-get install -y fuse3'"

export PATH="$HOME/.local/bin:$PATH"

# 1) shell init — the bare home ships no .bashrc/.profile; wire ~/.local/bin in
ensure_path() {
  local f="$1" line='export PATH="$HOME/.local/bin:$PATH"'
  [ -f "$f" ] || printf '%s\n' "$line" > "$f"
  grep -q '\.local/bin' "$f" || printf '%s\n' "$line" >> "$f"
}
ensure_path "$HOME/.bashrc"
ensure_path "$HOME/.profile"

# 2) tools — official installers, all landing in ~/.local/bin
install_tool() {
  local name="$1" url="$2" runner="${3:-sh}"
  if command -v "$name" >/dev/null; then
    echo "== $name: already at $(command -v "$name")"
  else
    echo "== installing $name"
    curl -fsSL "$url" | "$runner"
  fi
}
install_tool claude https://claude.ai/install.sh   bash
install_tool omp    https://omp.sh/install         sh
install_tool ovnfs  https://stencil.so/ovnfs.sh    sh
install_tool uv     https://astral.sh/uv/install.sh sh

# 3) superpowers → claude code (marketplace named superpowers-dev by the fork)
if ! claude plugin marketplace list | grep -q "$SUPERPOWERS_REPO"; then
  claude plugin marketplace add "$SUPERPOWERS_REPO"
fi
if ! claude plugin list --json | grep -q "\"$SUPERPOWERS_PLUGIN\""; then
  claude plugin install "$SUPERPOWERS_PLUGIN"
fi

# 4) superpowers → omp
if ! grep -q "$SUPERPOWERS_REPO" "$HOME/.omp/marketplaces.json" 2>/dev/null; then
  omp plugin marketplace add "$SUPERPOWERS_REPO"
fi
if ! omp plugin list --json | grep -q "\"$SUPERPOWERS_PLUGIN\""; then
  omp plugin install "$SUPERPOWERS_PLUGIN" --scope user
fi

# 5) verify
echo; echo "== versions"
claude --version
omp --version
uv --version
ovnfs version
echo; echo "== superpowers installed"
claude plugin list --json | grep "\"$SUPERPOWERS_PLUGIN\""
omp    plugin list --json | grep "\"$SUPERPOWERS_PLUGIN\""
echo; echo "Auth left to you on first use: 'claude' then /login, and 'omp login'."
