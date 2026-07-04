#!/usr/bin/env bash
# Apply a Cumulus skin preset: sets the paired wallpaper + colour scheme.
#
#   ./apply.sh jade-aviator      # by flavour name
#   ./apply.sh 7                 # by preset number (1..24)
#   ./apply.sh                   # list presets
#
# If the schemes are installed system-wide (see install-schemes.sh) this uses
# `caelestia scheme set` so every themed app updates. Otherwise it writes the
# shell's state scheme.json directly (no root; re-themes the shell only).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# preset  flavour         wallpaper
PRESETS=(
  "1 rose-arcade      nw1"
  "2 midnight-shore   nw2"
  "3 crimson-study    nw3"
  "4 violet-dusk      nw4"
  "5 lilac-daydream   nw5"
  "6 lamplight-cat    nw6"
  "7 jade-aviator     nw7"
  "8 blue-voyage      nw8"
  "9 golden-transit   nw9"
  "10 windswept       nw10"
  "11 silver-sky      nw11"
  "12 harbor-dusk     nw12"
  "13 ember-night     nw13"
  "14 vinyl-halo      nw14"
  "15 dusty-rose      nw15"
  "16 indigo-camp     nw16"
  "17 midnight-street nw17"
  "18 neon-transit    nw18"
  "19 lilypad         nw19"
  "20 twilight-garden nw20"
  "21 cloudbank       nw21"
  "22 olive-marina    nw22"
  "23 jungle-sign     nw23"
  "24 flower-box      nw24"
)

WALL_SRC_DIR="${WALL_SRC_DIR:-$HOME/.local/share/cumulus/walls}"

list() { printf '  %s  %-16s %s.jpg\n' $(printf '%s\n' "${PRESETS[@]}"); }

if [[ $# -eq 0 ]]; then echo "Presets:"; list; exit 0; fi

sel="$1"; flavour=""; wall=""
for row in "${PRESETS[@]}"; do
  read -r n f w <<<"$row"
  if [[ "$sel" == "$n" || "$sel" == "$f" ]]; then flavour="$f"; wall="$w"; break; fi
done
[[ -z "$flavour" ]] && { echo "Unknown preset: $sel"; echo "Presets:"; list; exit 1; }

echo ":: preset $flavour  (wallpaper $wall.jpg)"

# --- wallpaper ---
wall_path="$WALL_SRC_DIR/$wall.jpg"
if [[ -f "$wall_path" ]] && command -v caelestia >/dev/null; then
  caelestia wallpaper -f "$wall_path" -N || echo "   (wallpaper set failed, continuing)"
else
  echo "   wallpaper $wall_path not found or caelestia missing — skipping wallpaper"
fi

# --- scheme ---
scheme_dir="$(python3 -c 'from caelestia.utils.paths import scheme_data_dir; print(scheme_data_dir)' 2>/dev/null || true)"
if [[ -n "$scheme_dir" && -d "$scheme_dir/cumulus/$flavour" ]]; then
  caelestia scheme set -n cumulus -f "$flavour" -m dark
  echo ":: applied via caelestia scheme set (system-wide)"
else
  state="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia"
  mkdir -p "$state"
  cp "$HERE/state/$flavour.json" "$state/scheme.json"
  echo ":: wrote $state/scheme.json (shell only — run install-schemes.sh for system-wide theming)"
fi
