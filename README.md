# Cumulus

A **matte-bubble** skin for the [Caelestia](https://github.com/caelestia-dots/caelestia)
Quickshell desktop shell (Hyprland). Cumulus reskins the entire shell into soft, rounded
**matte bubbles lit from the top** — floating islands instead of a connected screen-edge
frame — and ships **24 wallpaper-paired colour schemes** you can cycle through with a keybind.

> **Status:** draft / pre-release. Wallpaper licensing is unresolved (see
> [Credits & licensing](#credits--licensing)); not yet published.

---

## What it looks like

- **Matte bubbles** — every pill, card, button, slider and panel is a rounded surface with a
  top→bottom gradient, inner top highlight, pooled bottom shadow and an outer drop shadow
  (ambient-occlusion pass). Container surfaces are flat; only *elements* are shaded, so the UI
  stays calm.
- **Floating islands** — the screen-edge frame is removed and the bar + every panel float as
  discrete offset cards.
- **24 presets** — each pairs a wallpaper with a hand-tuned palette. 16 are dark, 8 are true
  light schemes (the mode flows through to GTK/Qt/terminals automatically).

![Sunset Pitstop — dashboard & notifications](docs/gallery/01-sunset-pitstop-dashboard.png)

<p align="center">
  <img src="docs/gallery/07-fleeting-moments.png" width="49%" alt="Fleeting Moments (dark)">
  <img src="docs/gallery/21-solitude.png" width="49%" alt="Solitude (light)">
</p>

**→ See all 24 presets in the [gallery](docs/GALLERY.md).**

**Preset flavours:** sunset-pitstop · seaside-respite · solace · elation ·
pastel-dreams · research-study · fleeting-moments · expeditions · yearning · journey ·
reflection · dusk-harbor · aspirations · vinyl-halo · seaside-stroll · obscuram ·
lingering-moments · island-three · wondering-beyond · flaura · solitude · olive-marina ·
post-anthropocene · ponder

---

## Requirements

Cumulus is a **skin for Caelestia**, not a standalone shell. You need a working Caelestia
setup first:

- [Caelestia dots](https://github.com/caelestia-dots) installed and running — the shell,
  the `caelestia` CLI, and the Hyprland config.
- **Quickshell** and **Hyprland** (installed by Caelestia).
- **Git LFS** to clone the wallpapers (they're stored via LFS).
- Optional, for full cross-app theming on preset changes: the apps Caelestia already themes
  (fish/bash, fuzzel, btop, htop, nvtop, cava, GTK, Qt, Zed, spicetify, Discord clients).

> **Compatibility note:** this repo is a fork of the Caelestia shell pinned to
> **caelestia-shell 2.0.3 / caelestia-cli 1.1.0 / Quickshell 0.3.0 / Hyprland 0.55.4**.
> If your installed Caelestia is much newer/older, some files may need re-syncing — see
> [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) and [Keeping in sync](#keeping-in-sync-with-caelestia).

---

## Install

Cumulus installs into Caelestia's **user override path**
(`~/.config/quickshell/caelestia/`), which shadows the system copy. That makes it fully
**reversible** — remove the override and you're back to stock Caelestia.

Pick whichever install path suits you:

### Option A — Manual (most transparent)

```sh
# 1. Clone (Git LFS pulls the wallpapers)
git clone <repo-url> cumulus && cd cumulus

# 2. Back up any existing override, then drop in the cumulus shell
mv ~/.config/quickshell/caelestia ~/.config/quickshell/caelestia.bak 2>/dev/null || true
mkdir -p ~/.config/quickshell
cp -a shell ~/.config/quickshell/caelestia

# 3. Stage wallpapers + scheme state
mkdir -p ~/.local/share/cumulus
cp -a wallpapers ~/.local/share/cumulus/walls
cp -a schemes/state ~/.local/share/cumulus/state
cp wallpapers/wallmap.json ~/.local/share/cumulus/wallmap.json

# 4. Merge the skin's shell.json settings into your Caelestia config
#    (deformScale:0, border thickness/rounding:0, backgrounds on)
#    -- merge by hand; do NOT blindly overwrite your own shell.json.
$EDITOR config/shell.json   # then apply the keys to ~/.config/caelestia/shell.json

# 5. (Optional) install the schemes into the caelestia CLI for full app theming
./schemes/install-schemes.sh    # needs sudo; rootless fallback works without it

# 6. Reload the shell
qs -c caelestia kill; caelestia shell -d
```

### Option B — Let an AI agent do it

Open an agent (Claude Code, Codex, Gemini CLI, etc.) **in the cloned repo** and paste the
prompt in [`install/ai-install-prompt.md`](install/ai-install-prompt.md). It walks the agent
through detecting your Caelestia paths, backing up, installing, and reloading — adapting to
your machine instead of assuming it.

### Option C — Install script (experimental)

```sh
./install/install.sh
```

Best-effort and **not guaranteed stable across distros** — it makes assumptions about paths
and Python locations. Read it before running. Option A or B is safer.

---

## Cycling presets

Preset switching is bound in your Hyprland keybinds (which live in *your* Caelestia Hypr
config, not in this repo). Add two binds pointing at the cycle script — example in
[`scripts/`](scripts/) — e.g.:

```lua
-- ~/.config/hypr/... keybinds
-- Ctrl+Super+Left / Right  →  previous / next preset (all 24)
bind = CTRL SUPER, left,  exec, ~/.config/hypr/scripts/cumulus-scheme-cycle.sh prev
bind = CTRL SUPER, right, exec, ~/.config/hypr/scripts/cumulus-scheme-cycle.sh next
```

Rebind to whatever you like — you just need a way to walk all 24 variants. The script
re-themes the shell + wallpaper (and, if the apps are present, terminals/spicetify/Discord/
btop/GTK/Qt/Zed/etc.).

---

## Switching back to stock Caelestia

Because Cumulus lives in the override path, reverting is just:

```sh
rm -rf ~/.config/quickshell/caelestia
mv ~/.config/quickshell/caelestia.bak ~/.config/quickshell/caelestia 2>/dev/null || true
# restore your previous scheme:
caelestia scheme set ...    # or delete ~/.local/state/caelestia/scheme.json
qs -c caelestia kill; caelestia shell -d
```

> **Recommended:** treat this as a **toggle**. A `cumulus off` / `cumulus on` helper that
> snapshots your prior scheme + wallpaper on first enable (so "off" restores *exactly* what
> you had) is on the roadmap — see [PLAN.md](PLAN.md).

---

## Keeping in sync with Caelestia

The `shell/` tree is a fork of the Caelestia shell. When you upgrade Caelestia, the system
copy changes but your override does **not** — so after big upgrades you may need to re-apply
the Cumulus changes on top of the new upstream. The skin also depends on the
`Caelestia.Config` plugin's `Tokens.*` (rounding/padding/font), which are compiled, not
shipped here; a plugin API change upstream can require edits. See [PLAN.md](PLAN.md).

---

## Credits & licensing

- **Cumulus** is a fork/skin of **[Caelestia](https://github.com/caelestia-dots/caelestia)**,
  which is **GPLv3**. This repo keeps that license (see [`LICENSE`](LICENSE)) and all
  attribution.
- **Wallpapers by [@XilmO@夕末 on pixiv](https://www.pixiv.net/en/users/19389056)!** All 24
  images are the artist's work (4K-upscaled for desktop use). Please support the artist on
  pixiv. See [`CREDITS.md`](CREDITS.md). If you're the artist and want them removed/credited
  differently, open an issue.

See [`CREDITS.md`](CREDITS.md) for attribution and [`PLAN.md`](PLAN.md) for the full build
plan, what was intentionally excluded, open problems, and recommendations.
