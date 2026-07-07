# Using the Cumulus lock as your login screen

Cumulus ships a **wake greeter** (a typewriter "Welcome, \<user\>" with mechanical
key-click SFX) that plays on the Caelestia/Cumulus lock screen at **boot** and on
**wake** (screen-on after dpms, or resume from suspend). Out of the box you only see it
when the shell locks — you still meet your display manager's login (SDDM/GDM/…) first.

To make the **Cumulus lock itself your login screen** — so the greeter is the first thing
you see at boot — you bypass the display manager's own prompt: autologin straight into the
Hyprland session, then have Hyprland lock immediately. Your password is still required (to
unlock the lock), so this is *not* a passwordless machine — you've just moved the password
prompt from the DM into the Cumulus lock.

> ⚠️ **This edits system files and needs `sudo`.** It's optional and fully reversible
> (see [Reverting](#reverting)). Keep a TTY (`Ctrl+Alt+F2`) or a live USB handy the first
> time in case a session name is wrong and you need to undo it.

There are three pieces:

1. **Autologin** the DM into your Hyprland session (skips the DM's own login form).
2. **Boot-lock** Hyprland so the Cumulus lock (and greeter) appears immediately.
3. **Keyring pass-through** so unlocking the lock also unlocks your GNOME keyring
   (already shipped — see step 3).

---

## 1. Autologin the display manager

Autologin is DM-specific. Set `User` to your username and `Session` to a session that
actually exists in `/usr/share/wayland-sessions/` (list them: `ls /usr/share/wayland-sessions/`).
Common Caelestia/Hyprland session names: `hyprland-uwsm`, `hyprland`, `hyprland-systemd`.

### SDDM (the setup Cumulus was developed against)

Create `/etc/sddm.conf.d/autologin.conf`:

```ini
[Autologin]
User=YOUR_USERNAME
Session=hyprland-uwsm
```

### GDM

In `/etc/gdm/custom.conf` (or `/etc/gdm3/custom.conf`), under `[daemon]`:

```ini
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=YOUR_USERNAME
```

### LightDM

In `/etc/lightdm/lightdm.conf` under `[Seat:*]`:

```ini
[Seat:*]
autologin-user=YOUR_USERNAME
autologin-session=hyprland
```

(LightDM autologin also needs your user in the `autologin` group on some distros:
`sudo groupadd -r autologin; sudo gpasswd -a YOUR_USERNAME autologin`.)

### greetd

In `/etc/greetd/config.toml`, set `initial_session` to the command that starts your
Hyprland session (e.g. `command = "uwsm start hyprland-uwsm.desktop"`, `user = "YOUR_USERNAME"`).

Reboot after this and you should land straight in Hyprland with no DM prompt.

---

## 2. Boot-lock Hyprland (so the greeter is your login)

Autologin alone drops you onto an *unlocked* desktop. To make the Cumulus lock the first
thing shown, have Hyprland lock as soon as the shell is up. The greeter only greets on locks
that engage within ~25s of shell start (the "boot lock" window), so lock **early**.

Add a boot-lock hook to **your** Hyprland config (it lives in your Caelestia Hypr config,
not in this repo). A robust approach polls until the shell's lock IPC is available, then
locks once:

```sh
# runs at Hyprland startup; waits for the Caelestia shell, then locks once
for i in $(seq 1 50); do
  qs -c caelestia ipc call lock lock >/dev/null 2>&1 && break
  sleep 0.2
done
```

- **Lua-based Hypr config** (Caelestia default): drop the poll into
  `~/.config/hypr/hyprland/execs.lua` as a startup exec (this is how the reference setup does it).
- **Plain `hyprland.conf`**: save the snippet as e.g. `~/.config/hypr/scripts/boot-lock.sh`
  (`chmod +x`) and add `exec-once = ~/.config/hypr/scripts/boot-lock.sh`.

Make sure the shell itself is also started at boot (`caelestia shell -d`, usually already an
`exec-once`). With both in place: boot → autologin → shell starts → lock engages → **greeter
plays** → type your password to log in.

---

## 3. Keyring pass-through (already included)

Because the DM no longer takes your password, the GNOME keyring would normally stay locked
and prompt you again after login. Cumulus's shell already appends
`auth optional pam_gnome_keyring.so` to the lock's own PAM stack
(`shell/assets/pam.d/passwd`, installed to
`~/.config/quickshell/caelestia/assets/pam.d/passwd`), so **unlocking the Cumulus lock unlocks
your keyring too** — no double prompt. Nothing to do here; it ships with the skin.

---

## Reverting

1. Remove the autologin config you added:
   - SDDM: `sudo rm /etc/sddm.conf.d/autologin.conf`
   - GDM: set `AutomaticLoginEnable=false` in `custom.conf`
   - LightDM: remove `autologin-user`
   - greetd: restore the default `initial_session`/`greeter`
2. Remove the boot-lock exec/poll from your Hyprland config.
3. Reboot — your DM's normal login screen is back.

The keyring PAM line is harmless to leave in place (it's part of the shell override and goes
away if you remove Cumulus).

---

## Tuning the greeter

Greeter look/feel is set at the top of
`~/.config/quickshell/caelestia/modules/lock/Greeter.qml`:

| property | default | what it does |
|---|---|---|
| `switchName` | `blackink-deep` | key-click sound pack (holypanda · cream · cream-deep · blackink · blackink-deep · topre · mxblack) |
| `charInterval` / `charJitter` | `62` / `26` | ms per character + randomness |
| `leadIn` / `holdAfter` | `850` / `520` | ms before typing starts / after it ends |
| `volume` | `0.9` | key-click volume |
| `soundEnabled` | `true` | mute the greeter clicks |
| `showLogo` | `true` | show the animated logo |
| `blurAmount` / `dimTint` | `1.0` / `0.42` | frosted-backdrop blur / dark tint |

Reload after edits: `caelestia shell -k; caelestia shell -d`.
