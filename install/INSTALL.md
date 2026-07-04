# Installing Cumulus

Cumulus is a **skin for Caelestia**. Install a working Caelestia first
(<https://github.com/caelestia-dots>), then apply Cumulus. Everything installs into
Caelestia's **override path**, so it's reversible (see [switching](../docs/SWITCHING.md)).

Check compatibility first: [docs/COMPATIBILITY.md](../docs/COMPATIBILITY.md).

---

## Prerequisites

- Caelestia (shell + `caelestia` CLI + Hypr config) installed and running
- Quickshell, Hyprland
- **Git LFS** (`git lfs install`) — required *before* cloning to get the wallpapers
- `jq` (for the config merge; optional if you merge by hand)

```sh
git lfs install
git clone <repo-url> cumulus && cd cumulus
```

---

## Fast path — script

```sh
./install/install.sh            # rootless (shell + wallpapers + scheme state)
./install/install.sh --system   # also register schemes with the caelestia CLI (sudo)
```

It backs up any existing override, stages assets to `~/.local/share/cumulus`, **merges**
(not overwrites) the skin keys into `~/.config/caelestia/shell.json`, applies a preset, and
reloads. It's best-effort — read it first.

---

## Manual path

```sh
# 1. Shell override (back up anything already there)
mv ~/.config/quickshell/caelestia ~/.config/quickshell/caelestia.pre-cumulus 2>/dev/null || true
mkdir -p ~/.config/quickshell
cp -a shell ~/.config/quickshell/caelestia

# 2. Stage wallpapers + scheme state
mkdir -p ~/.local/share/cumulus/walls ~/.local/share/cumulus/state
cp -a wallpapers/*.jpg   ~/.local/share/cumulus/walls/
cp -a schemes/state/.    ~/.local/share/cumulus/state/
cp    wallpapers/wallmap.json ~/.local/share/cumulus/wallmap.json

# 3. Merge skin settings into YOUR shell.json (do not overwrite)
jq -s '.[0] * .[1]' ~/.config/caelestia/shell.json config/shell.json > /tmp/m.json \
  && mv /tmp/m.json ~/.config/caelestia/shell.json
#   (keys: appearance.deformScale=0, border.thickness=0, border.rounding=0,
#    background.wallpaperEnabled=true, bar.clock/tray.background=true)

# 4. Apply a preset (rootless — shell + wallpaper only)
./schemes/apply.sh sunset-pitstop
#   or, for full cross-app theming (sudo, registers schemes with the CLI):
./schemes/install-schemes.sh && ./schemes/apply.sh sunset-pitstop

# 5. Reload
qs -c caelestia kill; caelestia shell -d
```

---

## Cycling / toggling

- **Cycle presets:** bind two keys to `scripts/cumulus-scheme-cycle.sh next|prev` in your
  Hypr keybinds (example in the main [README](../README.md)).
- **Toggle on/off vs stock Caelestia:** `scripts/cumulus on|off|status`
  (see [docs/SWITCHING.md](../docs/SWITCHING.md)).

## Optional extras

- **Focus transparency** (dim unfocused windows): source `scripts/focus-transparency.lua`
  from your Hypr config and add a slider; it reads `windowOpacity`. Skip if you don't want it.
