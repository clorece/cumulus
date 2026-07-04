#!/usr/bin/env bash
# Cycle the Caelestia Cumulus skin presets (wallpaper + colour scheme together).
#   cumulus-scheme-cycle.sh next   -> next preset
#   cumulus-scheme-cycle.sh prev   -> previous preset
#   cumulus-scheme-cycle.sh <name> -> jump to a specific flavour
# Bound to Ctrl+Super keybinds (see hyprland/keybinds.lua).
#
# Structure matters for rapid keypresses:
#   1. resolve + commit the target preset FIRST, under a blocking lock, so
#      every press reads the previous press's write and advances one step.
#   2. wallpaper + app theming run backgrounded under a second lock; each
#      queued job re-reads the state file, so they all converge on the
#      newest preset regardless of wakeup order.
# The wallpaper path file is written atomically by us instead of via
# `caelestia wallpaper` — the CLI's truncate-then-write races the shell's
# file watcher, which reads an empty path and stomps it with the default
# wallpaper (the "random default wallpaper" bug).
set -uo pipefail

STAGE="$HOME/.local/share/cumulus"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"

# preset order  (index = wallpaper number - 1)
FLAVOURS=(
  rose-arcade midnight-shore crimson-study violet-dusk lilac-daydream
  lamplight-cat jade-aviator blue-voyage golden-transit windswept
  silver-sky harbor-dusk ember-night vinyl-halo dusty-rose
  indigo-camp midnight-street neon-transit lilypad twilight-garden
  cloudbank olive-marina jungle-sign flower-box
)
declare -A WALL=(
  [rose-arcade]=nw1     [midnight-shore]=nw2  [crimson-study]=nw3
  [violet-dusk]=nw4     [lilac-daydream]=nw5  [lamplight-cat]=nw6
  [jade-aviator]=nw7    [blue-voyage]=nw8     [golden-transit]=nw9
  [windswept]=nw10      [silver-sky]=nw11     [harbor-dusk]=nw12
  [ember-night]=nw13    [vinyl-halo]=nw14     [dusty-rose]=nw15
  [indigo-camp]=nw16    [midnight-street]=nw17 [neon-transit]=nw18
  [lilypad]=nw19        [twilight-garden]=nw20 [cloudbank]=nw21
  [olive-marina]=nw22   [jungle-sign]=nw23    [flower-box]=nw24
)

n=${#FLAVOURS[@]}
arg="${1:-next}"

# --- 1) resolve target flavour + commit state, serialized ---
exec 8>"$RUNTIME/cumulus-resolve.lock"
flock -x 8

flavour=""
if [[ -n "${WALL[$arg]:-}" ]]; then
  flavour="$arg"
else
  cur="$(sed -n 's/.*"flavour": *"\([^"]*\)".*/\1/p' "$STATE_FILE" 2>/dev/null)"
  idx=-1
  for i in "${!FLAVOURS[@]}"; do [[ "${FLAVOURS[$i]}" == "$cur" ]] && idx=$i && break; done
  if   [[ $idx -lt 0 ]];        then next=0
  elif [[ "$arg" == "prev" ]];  then next=$(( (idx - 1 + n) % n ))
  else                                next=$(( (idx + 1) % n )); fi
  flavour="${FLAVOURS[$next]}"
fi

# atomic replace — the shell hot-reloads this file, a plain copy can be
# caught half-written
mkdir -p "$(dirname "$STATE_FILE")"
tmp="$(mktemp "$(dirname "$STATE_FILE")/.scheme.XXXXXX")" || exit 1
cp "$STAGE/state/$flavour.json" "$tmp" && chmod 600 "$tmp" && mv -f "$tmp" "$STATE_FILE"

flock -u 8

# --- 2) wallpaper + app theming (backgrounded, converging) ---
(
  flock -x 9
  python3 - "$STAGE" <<'PY'
import json, os, sys
from pathlib import Path

stage = Path(sys.argv[1])
state_dir = Path(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))) / "caelestia"

# newest committed preset (may be newer than the press that queued this job)
d = json.load(open(state_dir / "scheme.json"))
wallmap = json.load(open(stage / "wallmap.json"))
wall = stage / "walls" / f"{wallmap[d['flavour']]}.jpg"

if wall.is_file():
    from caelestia.utils.paths import (
        compute_hash, wallpaper_link_path, wallpaper_path_path,
        wallpaper_thumbnail_path, wallpapers_cache_dir,
    )
    from caelestia.utils.wallpaper import get_thumb

    # what `caelestia wallpaper` does, minus its non-atomic path write and
    # minus its crash on non-root-installed schemes
    wallpaper_path_path.parent.mkdir(parents=True, exist_ok=True)
    tmp = wallpaper_path_path.with_suffix(".tmp")
    tmp.write_text(str(wall))
    tmp.replace(wallpaper_path_path)  # atomic: watcher never sees a partial file

    wallpaper_link_path.parent.mkdir(parents=True, exist_ok=True)
    wallpaper_link_path.unlink(missing_ok=True)
    wallpaper_link_path.symlink_to(wall)

    thumb = get_thumb(wall, wallpapers_cache_dir / compute_hash(wall))
    wallpaper_thumbnail_path.parent.mkdir(parents=True, exist_ok=True)
    wallpaper_thumbnail_path.unlink(missing_ok=True)
    wallpaper_thumbnail_path.symlink_to(thumb)

# rootless app theming: terminals, spicetify, discord clients, fuzzel, btop,
# htop, nvtop, gtk, qt, zed, cava, hypr + user templates
from caelestia.utils.theme import apply_colours
apply_colours(d["colours"], d.get("mode", "dark"))
PY
  # bake new colours into Spotify (no restart; takes effect next launch)
  command -v spicetify >/dev/null && spicetify -q apply -n || true
) 9>"$RUNTIME/cumulus-apply.lock" >/dev/null 2>&1 &

# --- 3) notify ---
pretty="$(echo "$flavour" | sed -E 's/(^|-)([a-z])/\1\u\2/g; s/-/ /g')"
notify-send -u low -i preferences-desktop-wallpaper -a "Cumulus" \
  "$pretty" "Preset ${WALL[$flavour]#nw}/$n" 2>/dev/null || true
