# AI-agent install prompt

Prefer to let an AI coding agent (Claude Code, Codex, Gemini CLI, etc.) install Cumulus and
adapt to your machine? Clone the repo, open the agent **inside the cloned `cumulus/`
directory**, and paste the prompt below.

> ⚠️ Review what the agent does before approving shell commands. It will move files in
> `~/.config` and `~/.local`. It should never need `sudo` unless you ask for system-wide
> scheme theming.

---

```
You are installing the "Cumulus" skin for the Caelestia Quickshell shell (Hyprland). You are
in the cloned repo. Do this carefully and reversibly:

1. VERIFY environment. Run `caelestia --version`, `qs --version`, `hyprctl version`. Confirm
   Caelestia is installed. Read docs/COMPATIBILITY.md and warn me if my caelestia-shell
   version differs from the supported one (2.0.3) — but let me decide whether to continue.

2. BACK UP. If ~/.config/quickshell/caelestia already exists, move it to
   ~/.config/quickshell/caelestia.pre-cumulus.<timestamp>. Never delete it.

3. INSTALL SHELL. Copy this repo's `shell/` to ~/.config/quickshell/caelestia (this is
   Caelestia's override path and shadows the system copy, so it's reversible).

4. STAGE ASSETS. Copy `wallpapers/*.jpg` -> ~/.local/share/cumulus/walls/,
   `schemes/state/*` -> ~/.local/share/cumulus/state/, and `wallpapers/wallmap.json` ->
   ~/.local/share/cumulus/wallmap.json. If the wallpapers are tiny text pointer files,
   Git LFS wasn't pulled — tell me to run `git lfs install && git lfs pull`.

5. MERGE CONFIG (do NOT overwrite). Merge the keys from this repo's `config/shell.json` into
   my existing ~/.config/caelestia/shell.json using `jq -s '.[0] * .[1]'`. Preserve all my
   existing settings. If ~/.config/caelestia/shell.json doesn't exist, copy it.

6. SCHEMES. Default to ROOTLESS: apply a preset by running `./schemes/apply.sh sunset-pitstop`
   (writes the shell scheme state, no sudo). Only if I explicitly ask for full cross-app
   theming, run `./schemes/install-schemes.sh` (uses sudo).

7. KEYBINDS. Show me the example keybinds from README.md for
   `scripts/cumulus-scheme-cycle.sh next|prev` and let me add them to my Hypr config myself
   (don't edit my Hypr keybinds without asking).

8. RELOAD. `qs -c caelestia kill; caelestia shell -d`.

9. TELL ME how to toggle back to stock Caelestia: `scripts/cumulus off` (and `on`), and that
   my previous scheme/wallpaper is snapshotted on first `on`.

Stop and ask me before anything destructive or anything needing sudo. Report each step's
result.
```
