# Cumulus — a matte skin for Caelestia

Reskin of the Caelestia shell from the design **`Caelestia Shell Preview.dc.html`**.
Treated as a *skin*: same UI layouts and element positions, new element appearance
(matte lighting/shading, rounded "bubble" surfaces) + a set of colour-scheme /
wallpaper presets.

## The design language (decoded from the .dc.html)

| Design token | Meaning | QML mapping |
|---|---|---|
| `--card-grad` | 165° gradient `cardLight → cardDark` | `Bubble` top→bottom gradient (`m3surfaceContainerHigh → m3surfaceContainer`) |
| `--matte` | outer drop shadow **+** inner top highlight **+** inner bottom shadow | `Bubble`: `Elevation` + top hairline + pooled bottom shade |
| `--rr` (≈1.05) | global roundness multiplier | `Tokens.rounding.*` (config-driven; already large/full) |
| `--accent` / `--accent-soft` / `--accent-ink` / `--accent2` | accent, +35% white, dark on-accent ink, secondary accent | `Colours.accent` / `accentSoft` / `accentInk` / `accent2` |
| `--hi` | accent-tinted card gradient | `Colours.bubbleAccentTop/Bottom` |
| 24 named schemes, each paired to a wallpaper `nw1..nw24` | colour presets | `schemes/cumulus/<flavour>/dark.txt` + `state/<flavour>.json` |

Signature look: **rounded matte bubbles lit from the top**, on an accent-tinted
wallpaper, with the left-edge bar composed of modular bubbles.

## What's implemented in this pass

1. **9 colour-scheme presets** (`generate_schemes.py` → `schemes/`, `state/`).
   Each design palette (`bg/cardLight/cardDark/accent/accentInk/accent2`) is mapped
   onto the full ~109-key Material You role set the shell + app templates consume.
2. **`shell/components/Bubble.qml`** — the reusable matte-bubble primitive
   (gradient + inner highlight/shade + outer `Elevation`). Drop-in for a
   `StyledRect { color: …surfaceContainer }`.
3. **`shell/services/Colours.qml`** — derived tokens `accent`, `accentSoft`,
   `accentInk`, `accent2`, `bubbleTop/Bottom`, `bubbleAccentTop/Bottom`, plus a
   `mixColour()` helper. Additive; nothing existing changed.
4. **`shell/modules/bar/components/Clock.qml`** — reference conversion of a real
   surface from `StyledRect` → `Bubble` (gated on the existing `clock.background`
   config, so behaviour is unchanged when that's off).

All new/changed QML passes `qmllint` clean.

## Apply / test

```bash
cd theme/skin

# Quick, no root — re-themes the shell live (writes state scheme.json + sets wallpaper).
# Wallpapers are read from ~/.local/share/cumulus/walls/nw1..nw24.jpg by default (WALL_SRC_DIR to override).
./apply.sh fleeting-moments        # or a number 1..24

# System-wide (themes terminal/GTK/discord/etc. too) — needs sudo once:
./install-schemes.sh
caelestia scheme set -n cumulus -f fleeting-moments -m dark
```

The shell QML changes are in `shell/…`. Per the package README, drop them into the
user override path `~/.config/quickshell/caelestia/` (mirroring the paths above) and
reload with `caelestia shell` / `qs`, or hand back this tree as a diff.

## Rollout — converting the remaining surfaces

The skin propagates by swapping container surfaces to `Bubble`. The canonical edit
(see `Clock.qml`) is:

```qml
// before
StyledRect { color: Colours.palette.m3surfaceContainer; radius: Tokens.rounding.large }
// after
Bubble { radius: Tokens.rounding.large }          // gradient + matte shading + shadow
// accent ("--hi") variant:
Bubble { topColor: Colours.bubbleAccentTop; bottomColor: Colours.bubbleAccentBottom }
```

Suggested order (highest visual leverage first), matching the design surfaces:

1. **bar/** — remaining bubbles: workspaces pill, tray bubble, status-icons bubble,
   OS-logo circle, and the bar's own background panel. (Clock done.)
2. **drawers/** panels + **dashboard/** cards (identity hero, clock, weather,
   resources ring, calendar, media) — the biggest bubble cluster.
3. **launcher/**, **session/**, **osd/** sliders, **utilities/** toggles,
   **notifications/** (featured vs condensed), **sidebar/**.
4. **nexus/** modal + nav rows, **lock/**.

Leave `services/` untouched. Keep using `Colours.*` roles (no hard-coded hex) so all
9 presets keep working. `Tokens.rounding/padding/font` come from the compiled
`Caelestia.Config` plugin — tune roundness via shell config, not here.

## Files

```
theme/skin/
  generate_schemes.py     regenerate all schemes from the design palettes
  schemes/cumulus/<f>/dark.txt   installable scheme files (caelestia format)
  state/<f>.json          drop-in ~/.local/state/caelestia/scheme.json
  apply.sh                apply a preset (wallpaper + scheme), no root
  install-schemes.sh      register schemes system-wide (sudo) + copy wallpapers
shell/components/Bubble.qml           new matte-bubble primitive
shell/services/Colours.qml            + derived accent/bubble tokens
shell/modules/bar/components/Clock.qml  reference StyledRect → Bubble conversion
```
