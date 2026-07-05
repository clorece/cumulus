#!/usr/bin/env bash
# Cumulus installer (EXPERIMENTAL / best-effort).
#
# Installs the Cumulus skin into Caelestia's user override path so it is fully
# reversible (see: scripts/cumulus off, or docs/SWITCHING.md).
#
#   ./install/install.sh            # rootless: shell + wallpapers + scheme state
#   ./install/install.sh --system   # also install schemes into the caelestia CLI (sudo)
#
# This makes assumptions about paths and may not fit every distro. Read it first.
# Prefer the manual steps (install/INSTALL.md) or the AI prompt if unsure.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
OVERRIDE="$CONFIG/quickshell/caelestia"
STAGE="$SHARE/cumulus"
SYSTEM=0; [ "${1:-}" = "--system" ] && SYSTEM=1

say() { printf '\033[1;36m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# --- 0. dependency + compatibility check ---------------------------------
command -v caelestia >/dev/null || { warn "caelestia CLI not found — install Caelestia first (see README)"; exit 1; }
command -v qs >/dev/null || warn "quickshell (qs) not found on PATH"
SUPPORTED="2.0.3"
ver="$(caelestia --version 2>/dev/null | grep -oE 'caelestia-shell [0-9.]+' | awk '{print $2}')"
if [ -n "$ver" ] && [ "$ver" != "$SUPPORTED" ]; then
  warn "Your caelestia-shell is $ver; Cumulus was built for $SUPPORTED."
  warn "It may still work, but the compiled Config plugin API can differ. See docs/COMPATIBILITY.md."
  read -r -p "Continue anyway? [y/N] " a; [ "${a,,}" = y ] || exit 1
fi

# --- 1. shell override (reversible) --------------------------------------
if [ -d "$OVERRIDE" ]; then
  bak="$OVERRIDE.pre-cumulus.$(date +%Y%m%d%H%M%S)"
  say "backing up existing override -> $bak"
  mv "$OVERRIDE" "$bak"
fi
mkdir -p "$(dirname "$OVERRIDE")"
cp -a "$REPO/shell" "$OVERRIDE"
# Make the override a tiny git repo: `caelestia --version` runs
# `git rev-list HEAD` on this dir *uncaught*, so a non-git copy makes that
# command traceback. A single local commit keeps `--version` happy (harmless
# to Quickshell, which ignores the .git dir). Best-effort.
if command -v git >/dev/null; then
  git -C "$OVERRIDE" init -q 2>/dev/null \
    && git -C "$OVERRIDE" add -A 2>/dev/null \
    && git -C "$OVERRIDE" -c user.name=Cumulus -c user.email=cumulus@localhost \
         -c commit.gpgsign=false commit -qm "Cumulus skin override" 2>/dev/null || true
fi
say "installed shell override -> $OVERRIDE"

# --- 2. stage wallpapers + scheme state ----------------------------------
mkdir -p "$STAGE/walls" "$STAGE/state"
cp -a "$REPO/wallpapers/"*.jpg "$STAGE/walls/" 2>/dev/null || warn "no wallpaper .jpg found (Git LFS not pulled?)"
cp -a "$REPO/schemes/state/." "$STAGE/state/"
cp -a "$REPO/wallpapers/wallmap.json" "$STAGE/wallmap.json"
say "staged wallpapers + scheme state -> $STAGE"

# --- 3. merge shell.json (NEVER overwrite the user's config) --------------
usercfg="$CONFIG/caelestia/shell.json"
mkdir -p "$(dirname "$usercfg")"
if command -v jq >/dev/null; then
  tmp="$(mktemp)"
  if [ -f "$usercfg" ]; then
    jq -s '.[0] * .[1]' "$usercfg" "$REPO/config/shell.json" > "$tmp" && mv "$tmp" "$usercfg"
    say "merged Cumulus keys into your existing $usercfg"
  else
    cp "$REPO/config/shell.json" "$usercfg"
    say "wrote $usercfg"
  fi
else
  warn "jq not installed — merge $REPO/config/shell.json into $usercfg by hand (see README)."
fi

# --- 4. scheme install ----------------------------------------------------
if [ "$SYSTEM" = 1 ]; then
  say "installing schemes into the caelestia CLI (sudo)…"
  ( cd "$REPO/schemes" && ./install-schemes.sh )
else
  say "rootless: applying a Cumulus preset via shell state (no sudo)."
  say "for full cross-app theming later, run: ./install/install.sh --system"
fi

# --- 5. apply a default preset + reload ----------------------------------
"$REPO/scripts/cumulus-scheme-cycle.sh" sunset-pitstop >/dev/null 2>&1 || \
  cp "$REPO/schemes/state/sunset-pitstop.json" "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
qs -c caelestia kill >/dev/null 2>&1; ( caelestia shell -d >/dev/null 2>&1 & )
say "done. Toggle with:  $REPO/scripts/cumulus {on|off|status}"
say "cycle presets by binding cumulus-scheme-cycle.sh next/prev to keys (see README)."
