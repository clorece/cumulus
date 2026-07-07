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
   ~/.local/share/cumulus/wallmap.json. If the wallpapers OR the sound samples under
   `shell/assets/sounds/**/*.wav` are tiny text pointer files, Git LFS wasn't pulled — tell me
   to run `git lfs install && git lfs pull`. (The sounds ride along inside `shell/` from step 3;
   the wake greeter and UI sound service are dead-silent without those .wav files.)

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

10. WAKE GREETER + SOUNDS (new). Point out that this build adds a wake greeter (typewriter
    "Welcome, <user>" with mechanical key-click SFX) on the lock screen, and a shell-wide UI
    sound service. The greeter plays on boot-lock and on wake (dpms-on / resume-from-suspend),
    not on plain idle-locks. The UI sound service auto-creates ~/.config/caelestia/sounds.json
    on first run (enable / master volume / per-category levels; toggle live with the `sounds`
    IPC or the `toggleSounds` shortcut). Greeter look/feel is tunable at the top of
    modules/lock/Greeter.qml (see docs/LOGIN-SCREEN.md). Nothing extra to install — it's all
    in the shell/ copy from step 3.

11. OPTIONAL — LOGIN-SCREEN BYPASS (only if I ask for it). Offer to make the Cumulus lock my
    actual login screen so I experience the greeter at boot. This is the "display-manager
    bypass": autologin the DM straight into Hyprland, then boot-lock Hyprland so the Cumulus
    lock (and greeter) is the first thing shown. It still requires my password to unlock — it
    just moves the prompt from the DM into the Cumulus lock. This needs sudo and edits system
    files, so DO NOT do it unless I explicitly ask, and confirm each change first. Follow
    docs/LOGIN-SCREEN.md exactly:
      a. Detect my display manager (`systemctl status display-manager`, readlink the unit) and
         list my sessions (`ls /usr/share/wayland-sessions/`). Pick a real Hyprland session
         name — do NOT guess a session that doesn't exist there.
      b. Write the DM autologin config for MY dm (SDDM -> /etc/sddm.conf.d/autologin.conf with
         [Autologin] User/Session; GDM/LightDM/greetd variants are in docs/LOGIN-SCREEN.md).
         Show me the exact file before writing it.
      c. Add a boot-lock hook to MY Hyprland config (Lua execs.lua, or an exec-once script for
         plain hyprland.conf) that polls `qs -c caelestia ipc call lock lock` until it succeeds,
         so the lock engages inside the ~25s boot-greet window. Confirm the shell is already
         started at boot (`caelestia shell -d`); add it if not.
      d. The keyring pass-through (`auth optional pam_gnome_keyring.so`) already ships in
         shell/assets/pam.d/passwd, so unlocking the lock also unlocks my keyring — just tell me
         it's handled.
      e. TELL ME how to revert (remove the autologin file + the boot-lock hook + reboot) and
         warn me to keep a TTY / live USB handy the first reboot in case the session name is
         wrong.

Stop and ask me before anything destructive or anything needing sudo. Report each step's
result.
```
