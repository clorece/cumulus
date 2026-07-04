# Cumulus — build plan, exclusions, problems & recommendations

This document is the working plan behind the Cumulus repo: what it is, what's deliberately
left out, the risks to address before publishing, and recommendations.

---

## 1. The plan

**Goal:** package the "matte bubble" Caelestia redesign — the shell reskin, 24
wallpaper-paired colour schemes, and the wallpapers — into a shareable repo (**Cumulus**) so
others can apply it to their own Caelestia install, while leaving out anything tied to this
one machine.

**Shape:** a **fork of the Caelestia shell** (GPLv3). Cumulus ships the full shell tree so
installing is a clean drop-in (no per-file merging), delivered through Caelestia's user
**override path** (`~/.config/quickshell/caelestia/`) so it stays reversible.

**How our changes were identified:** diffed the live override
(`~/.config/quickshell/caelestia/`) against the pristine system copy
(`/etc/xdg/quickshell/caelestia/`, the AUR build the skin was made on). That isolates exactly
the skin's changes: **65 modified + 3 new QML files** (`Bubble.qml`, `BubbleGradient.qml`,
`FocusedTransparency.qml`).

**Repo layout:**

| Path | Contents |
|------|----------|
| `shell/` | Full forked shell tree (296 files) — the matte redesign. PAM reverted to upstream. |
| `schemes/` | `generate_schemes.py`, generated `schemes/matte/<flavour>/{dark,light}.txt`, `state/*.json`, `wallmap.json`, `install-schemes.sh`, `apply.sh`. |
| `wallpapers/` | 24 4K images (`nw1..nw24.jpg`) + `wallmap.json`. Git LFS. |
| `config/` | `shell.json` skin settings. |
| `scripts/` | `cumulus-scheme-cycle.sh` (preset cycler + app theming), `focus-transparency.lua`. |
| `install/` | `INSTALL.md`, `ai-install-prompt.md`, experimental `install.sh`. |
| `docs/` | Switching guide, troubleshooting. |

**Install, offered four ways:** manual instructions + dependency list · a copy-paste AI-agent
prompt · an experimental install script (flagged best-effort) · plus switch-back / toggle
instructions.

---

## 2. What is included (portable)

- **All 68 QML skin files** — the matte look (Bubble/BubbleGradient primitives, every
  StyledRect→Bubble conversion, `Colours.qml` derived tokens, structural frame/island
  changes). Pure QML; no machine assumptions.
- **24 colour schemes** — generator + generated schemes + per-flavour state + wallmap
  (16 dark, 8 true-light).
- **24 wallpapers** — 4K Real-ESRGAN upscales, via Git LFS.
- **`shell.json`** skin settings (`deformScale:0`, `border` 0, backgrounds on).
- **Cycle + app-sync script** — kept per decision: the apps it themes ship with Caelestia
  anyway, and if one is missing it fails silently. Recolours shell + wallpaper, plus
  terminals/spicetify/Discord/btop/htop/nvtop/cava/GTK/Qt/Zed if present.
- **Preset keybinds** — documented as an example; users rebind freely (they just need to
  reach all 24 variants).
- **Focus-transparency slider** (`FocusedTransparency.qml` + `focus-transparency.lua`) — a
  bespoke feature for this skin (dims unfocused windows). Not in stock Caelestia; included
  because it's tailored to Cumulus.
- **Weather.qml fix** — a timestamp-parsing/refresh fix. Bundled but **documented as
  optional**; it only touches weather rendering and cannot alter anyone's preset/colours.

---

## 3. What is excluded (and why)

Only genuinely machine-/account-specific things were removed. Nothing visual was dropped.

| Excluded | Why |
|----------|-----|
| **`assets/pam.d/passwd` gnome-keyring line** | Personal auth/keyring tweak. Reverted to upstream in the packaged tree. Shipping a PAM file others might blindly copy is unsafe. |
| **Spotify `chmod a+wr /opt/spotify` unlock** | A one-time manual privilege change on this box, never part of the shipped script. Auth/permission bypass — excluded. |
| **SDDM autologin / boot-to-lockscreen / greeter tweaks** | Separate system config (systemd/SDDM), not in the shell tree at all. Not shipped and no instructions provided for it. |
| **Hyprland keybind *file* + Wallpaper-Engine config** | Live in the user's own Hypr config and assume this machine's keybind layout / that Wallpaper Engine is installed. Shipped only as **example snippets**, not as drop-in files. |
| **Any LED / RGB hardware control** | **None exists.** Verified: no OpenRGB/liquidctl/ckb/razer/`/sys/class/leds` calls anywhere. (The one `i2c` reference is Caelestia's upstream monitor-brightness feature, untouched.) The original worry — "recolour my PC LEDs with the scheme" — is not in the codebase, so there is nothing to exclude. |

---

## 4. Potential problems to address before publishing

1. **Wallpaper copyright (biggest risk).** The 24 images are third-party art, 4K-upscaled
   with Real-ESRGAN. Redistributing them in a public repo (especially via LFS, which makes
   them the bulk of the download) is a licensing exposure. **Resolve before making the repo
   public.** Options: ship a manifest + downloader instead of the images; credit original
   sources and confirm each license; or replace with self-made / CC0 wallpapers and re-tune
   the paired palettes.

2. **Upstream version drift.** `shell/` is pinned to the Caelestia AUR build from when the
   skin was made. A user on a newer/older Caelestia may hit mismatches — most acutely with
   the compiled `Caelestia.Config` plugin (`Tokens.rounding/padding/font`), whose API the
   skin relies on. Needs a declared "tested against Caelestia commit/version X" and a compat
   note.

3. **Internal name is still `matte`.** The scheme namespace (`schemes/matte/…`, the
   `caelestia scheme set -n matte` selector), the staged asset dir
   (`~/.local/share/caelestia-matte/`), and the script/notification text all say "matte."
   Brand is now **Cumulus** — this is inconsistent and will confuse users.

4. **Script portability.** `cumulus-scheme-cycle.sh` hardcodes
   `$STAGE=~/.local/share/caelestia-matte` and imports Caelestia's Python internals
   (`caelestia.utils.theme.apply_colours`, `caelestia.utils.paths`). If those internals
   change upstream, the cycler breaks. Paths need generalising and the Python dependency
   documented/guarded.

5. **`install-schemes.sh` fragility.** It writes into Caelestia's scheme data dir under
   `site-packages` (needs root, and correct Python-version path detection). This is the least
   portable installer step across distros. The rootless state-file path
   (`~/.local/state/caelestia/scheme.json`) should be the default; root install optional for
   full app theming.

6. **`shell.json` merge hazard.** Users have their own `shell.json`. The install must **merge**
   the skin keys, not overwrite — otherwise it clobbers their settings. Manual step is called
   out in the README; the script/AI-prompt must do a real merge.

7. **Override shadows the system copy.** After a `caelestia-shell` upgrade, the override keeps
   the old (skinned) files. Users need to know to re-sync/re-install after upgrades.

8. **Focus-transparency depends on Hypr config.** `focus-transparency.lua` reads
   `variables.windowOpacity` from the user's Hypr config and uses a state file. Needs install
   docs; degrade gracefully if the variable is absent.

9. **Light-wallpaper contrast.** A few presets are true-light; the docs/gallery should make
   clear which are light so users aren't surprised by the mode flip in GTK/Qt/terminals.

10. **No gallery yet.** 24 presets with no screenshots is a hard sell and hides the
    light/dark split. Needs a rendered gallery.

11. **Git LFS required.** 45M of wallpapers via LFS means clones fail/blank without LFS
    installed. Must be documented, and `.gitattributes` must be committed *before* the images.

---

## 5. Recommendations

- **Settle wallpaper licensing first.** Nothing else matters if the repo can't ship legally.
  Safest default for a first public cut: **manifest + downloader** (no images committed), with
  the bundled-4K option behind a documented, rights-cleared path.
- **Rename `matte` → `cumulus`** everywhere user-facing (scheme namespace, staged dir, script
  names, notifications) for brand consistency. Regenerate schemes into `schemes/cumulus/`.
- **Add a real toggle.** `cumulus on|off` that snapshots the prior scheme + wallpaper on first
  enable and restores them on `off` — this is the reversible switch requested, done properly.
- **Declare a supported Caelestia version** and add a lightweight compat check to the
  installer/AI-prompt (warn if the plugin `Tokens` API or upstream shell differs).
- **Commit `.gitattributes` (LFS) before assets**, and pin LFS for `*.jpg`.
- **Make scheme install rootless-first**; treat the site-packages install as an optional
  "full app theming" extra.
- **Do a merge, not overwrite, for `shell.json`** in both the script and the AI prompt.
- **Test on a clean Caelestia install (VM/container)** end-to-end before tagging a release —
  this catches the drift, path, and merge problems above.
- **Add a screenshot gallery** of all 24 presets (mark light vs dark).
- Consider later offering a **slim overlay variant** (only the changed files) alongside the
  full fork, for users who want to track upstream more closely.

---

## 6. Status snapshot

- [x] Changes isolated (diff vs pristine upstream)
- [x] Repo scaffolded at `~/cumulus/` (shell tree, schemes, wallpapers, config, scripts)
- [x] PAM reverted to upstream; tree verified path-clean; no LED code confirmed
- [x] README + this plan drafted
- [x] Wallpaper licensing decided — credit **@XilmO@夕末 on pixiv**, repo under GPLv3 (see `CREDITS.md`)
- [x] `matte` → `cumulus` rename (scheme namespace, staged paths, state `name`, scripts, notifications)
- [x] Toggle script (`scripts/cumulus on|off|status`) + generalised paths (`~/.local/share/cumulus`)
- [x] `.gitattributes` (LFS for images), `LICENSE` (GPLv3), `CREDITS.md`
- [x] Supported Caelestia version pinned (`docs/COMPATIBILITY.md`)
- [x] Install script (merge-not-overwrite, compat check, rootless-first) + `INSTALL.md` + AI prompt
- [x] `git init` + `git lfs install` + first commit (`.gitattributes` before assets)
- [x] Gallery screenshots — all 24 presets (bar shots) + 7 dashboard shots, identified against
  the wallpapers, deduped (2 accidental exact dupes dropped), in `docs/GALLERY.md`
- [ ] Clean-install test (VM / container)
- [ ] Publish

> **Resolved since first draft:** wallpaper licensing (problem #1 — now credited to the
> artist, repo GPLv3 per Caelestia) and the internal `matte` name (problem #3 — renamed to
> `cumulus`). Remaining open items above.
