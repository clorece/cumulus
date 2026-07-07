# Cumulus

A **soft-bubble** skin for the [Caelestia](https://github.com/caelestia-dots/caelestia)
Quickshell desktop shell (Hyprland). Cumulus reskins the entire shell into soft, rounded
**soft bubbles lit from the top** — floating islands instead of a connected screen-edge
frame — and ships **24 wallpaper-paired colour schemes** you can cycle through with a keybind.

> **Status:** draft / pre-release. Wallpaper licensing is unresolved (see
> [Credits & licensing](#credits--licensing)); not yet published.

---

## What it looks like

- **Soft bubbles** — every pill, card, button, slider and panel is a rounded surface with a
  top→bottom gradient, inner top highlight, pooled bottom shadow and an outer drop shadow
  (ambient-occlusion pass). Container surfaces are flat; only *elements* are shaded, so the UI
  stays calm.
- **Floating islands** — the screen-edge frame is removed and the bar + every panel float as
  discrete offset cards.
- **24 presets** — each pairs a wallpaper with a hand-tuned palette. 16 are dark, 8 are true
  light schemes (the mode flows through to GTK/Qt/terminals automatically).
- **Wake greeter** — a typewriter "Welcome, \<user\>" with mechanical key-click SFX on the lock
  screen, played at boot and on wake (dpms-on / resume). You can make it your actual
  [login screen](docs/LOGIN-SCREEN.md).
- **Shell-wide UI sounds** — an optional, non-invasive sound layer (hover/click/toggle/panel/
  system cues) with per-category levels; auto-configured via `~/.config/caelestia/sounds.json`.

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
- **git** + **Git LFS** — run `git lfs install` **before** cloning, or the wallpapers **and the
  greeter/UI sound samples** arrive as LFS pointer files (images blank, sounds silent).
- **jq** — for the `shell.json` merge (the installer degrades gracefully without it and tells
  you to merge by hand).
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
**reversible** — toggle it off (or remove the override) and you're back to stock Caelestia.

### 1. Install script (recommended)

```sh
git lfs install                       # once per machine — so wallpapers clone as images, not pointers
git clone https://github.com/clorece/cumulus
cd cumulus
./install/install.sh                  # rootless: shell override + wallpapers + a default preset
```

Want full cross-app theming (GTK/Qt/terminals/etc. follow the preset)? Also register the
schemes with the caelestia CLI:

```sh
./install/install.sh --system         # additionally installs the 24 schemes (uses sudo)
```

The installer backs up any existing override, stages wallpapers + scheme state to
`~/.local/share/cumulus`, **merges** (never overwrites) the skin keys into your
`~/.config/caelestia/shell.json`, applies the `sunset-pitstop` preset, and reloads the shell.
It's a plain, reversible bash script — read it first if you like.

Then toggle or check state anytime:

```sh
./scripts/cumulus status              # ON/OFF vs stock Caelestia
./scripts/cumulus off                 # revert to stock (restores your previous scheme/wallpaper)
./scripts/cumulus on                  # re-enable Cumulus
```

> Tested on Arch Linux against the pinned Caelestia stack (see [Requirements](#requirements)).
> The script targets standard XDG paths; on an unusual setup, read it first or use the manual
> path below.

### 2. Let an AI agent do it

Open an agent (Claude Code, Codex, Gemini CLI, etc.) **in the cloned repo** and paste the
prompt in [`install/ai-install-prompt.md`](install/ai-install-prompt.md). It detects your
Caelestia paths, backs up, installs, and reloads — adapting to your machine instead of
assuming it.

### 3. Manual (most transparent)

```sh
git lfs install && git clone https://github.com/clorece/cumulus && cd cumulus

# 1. Back up any existing override, then drop in the cumulus shell
mv ~/.config/quickshell/caelestia ~/.config/quickshell/caelestia.bak 2>/dev/null || true
mkdir -p ~/.config/quickshell
cp -a shell ~/.config/quickshell/caelestia

# 2. Stage wallpapers + scheme state
mkdir -p ~/.local/share/cumulus
cp -a wallpapers ~/.local/share/cumulus/walls
cp -a schemes/state ~/.local/share/cumulus/state
cp wallpapers/wallmap.json ~/.local/share/cumulus/wallmap.json

# 3. Merge the skin's shell.json into your Caelestia config (deformScale:0,
#    border thickness/rounding:0, backgrounds on) — merge by hand, don't overwrite.
$EDITOR config/shell.json   # then apply the keys to ~/.config/caelestia/shell.json

# 4. Apply a preset — rootless (shell + wallpaper), or add install-schemes.sh for app theming
./schemes/apply.sh sunset-pitstop
#   full cross-app theming (sudo): ./schemes/install-schemes.sh && ./schemes/apply.sh sunset-pitstop

# 5. Reload the shell
qs -c caelestia kill; caelestia shell -d
```

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

Use the toggle — it snapshots your pre-Cumulus scheme + wallpaper on first enable, so `off`
restores *exactly* what you had:

```sh
./scripts/cumulus off      # move the override aside → stock Caelestia shows through
./scripts/cumulus on       # bring Cumulus back
./scripts/cumulus status   # what's active right now
```

Nothing is destroyed — `off` moves the override to `~/.config/quickshell/caelestia.cumulus-disabled`
and restores your saved scheme/wallpaper. See [docs/SWITCHING.md](docs/SWITCHING.md) for details.

Prefer to do it by hand? The override is just a directory:

```sh
mv ~/.config/quickshell/caelestia ~/.config/quickshell/caelestia.off
qs -c caelestia kill; caelestia shell -d
```

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
