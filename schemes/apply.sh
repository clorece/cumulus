#!/usr/bin/env bash
# Apply a Cumulus skin preset: sets the paired wallpaper + colour scheme.
#
#   ./apply.sh fleeting-moments      # by flavour name
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
  "1 sunset-pitstop      nw1"
  "2 seaside-respite   nw2"
  "3 solace    nw3"
  "4 elation      nw4"
  "5 pastel-dreams   nw5"
  "6 research-study    nw6"
  "7 fleeting-moments     nw7"
  "8 expeditions      nw8"
  "9 yearning   nw9"
  "10 journey       nw10"
  "11 reflection      nw11"
  "12 dusk-harbor     nw12"
  "13 aspirations     nw13"
  "14 vinyl-halo      nw14"
  "15 seaside-stroll      nw15"
  "16 obscuram     nw16"
  "17 lingering-moments nw17"
  "18 island-three    nw18"
  "19 wondering-beyond         nw19"
  "20 flaura nw20"
  "21 solitude       nw21"
  "22 olive-marina    nw22"
  "23 post-anthropocene     nw23"
  "24 ponder      nw24"
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
