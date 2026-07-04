#!/usr/bin/env bash
# Install the 24 Cumulus schemes into Caelestia so they're first-class selectable:
#   caelestia scheme set -n cumulus -f fleeting-moments -m dark
# and (optionally) copy the paired wallpapers into your Caelestia wallpaper dir.
#
# The scheme data dir lives under the caelestia-cli package (root-owned), so this
# step needs sudo. Re-run after upgrading caelestia-cli (a package update may
# replace the dir). apply.sh works without this step (shell-only, no root).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scheme_dir="$(python3 -c 'from caelestia.utils.paths import scheme_data_dir; print(scheme_data_dir)')"
echo ":: scheme data dir: $scheme_dir"
echo ":: installing cumulus/ (24 flavours) — needs sudo"
sudo cp -rv "$HERE/schemes/cumulus" "$scheme_dir/"

echo
echo ":: verify:"
caelestia scheme list -n 2>/dev/null | tr ',' '\n' | grep -i cumulus || echo "   (run: caelestia scheme list -n)"

# Optional wallpaper copy
walls_src="${WALL_SRC_DIR:-$HOME/.local/share/cumulus/walls}"
walls_dst="$(python3 - <<'PY' 2>/dev/null || true
try:
    from caelestia.utils.paths import config_dir
    import json
    # best-effort: caelestia default wallpaper dir
    print(str((config_dir / "../Pictures/Wallpapers").resolve()))
except Exception:
    pass
PY
)"
walls_dst="${walls_dst:-$HOME/Pictures/Wallpapers}"
if [[ -d "$walls_src" ]]; then
  read -r -p ":: copy nw1..nw24.jpg from $walls_src to $walls_dst? [y/N] " ans
  if [[ "${ans,,}" == "y" ]]; then
    mkdir -p "$walls_dst"
    cp -v "$walls_src"/nw{1..24}.jpg "$walls_dst/" 2>/dev/null || true
  fi
fi
echo ":: done. Apply with:  ./apply.sh fleeting-moments"
