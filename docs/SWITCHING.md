# Switching between Cumulus and stock Caelestia

Cumulus installs into Caelestia's **override path**
(`~/.config/quickshell/caelestia/`), which shadows the read-only system shell copy
(`/etc/xdg/quickshell/caelestia/`). So switching back to stock is just removing/relocating
the override — nothing about your Caelestia install is modified.

## The easy way — the toggle helper

```sh
scripts/cumulus on        # enable Cumulus (snapshots your current scheme+wallpaper first time)
scripts/cumulus on jade-aviator   # enable and jump to a specific preset
scripts/cumulus off       # back to stock Caelestia, restoring your previous scheme+wallpaper
scripts/cumulus status    # what's active right now
```

- The **first** time you run `cumulus on`, it snapshots your existing
  `~/.local/state/caelestia/scheme.json` and wallpaper path to
  `~/.local/state/cumulus/backup/`. `cumulus off` restores exactly that — so you land back
  on the look you had before Cumulus, not a random default.
- Put `scripts/cumulus` on your `PATH` (e.g. symlink into `~/.local/bin`) to just run
  `cumulus on|off`.

## The manual way

```sh
# turn OFF (stock shell shows through)
mv ~/.config/quickshell/caelestia ~/.config/quickshell/caelestia.cumulus-disabled
# restore your previous scheme (or delete to let caelestia pick):
caelestia scheme set -n <your-scheme> ...      # or: rm ~/.local/state/caelestia/scheme.json
qs -c caelestia kill; caelestia shell -d

# turn ON again
mv ~/.config/quickshell/caelestia.cumulus-disabled ~/.config/quickshell/caelestia
./schemes/apply.sh rose-arcade
qs -c caelestia kill; caelestia shell -d
```

## After a Caelestia upgrade

Upgrading `caelestia-shell` updates the **system** copy, but your override keeps the old
(Cumulus) files. After a major upgrade you may need to re-install Cumulus on top of the new
upstream — or toggle `off` to run the fresh stock shell. See
[COMPATIBILITY.md](COMPATIBILITY.md).

## Full uninstall

```sh
rm -rf ~/.config/quickshell/caelestia ~/.config/quickshell/caelestia.cumulus-disabled
mv ~/.config/quickshell/caelestia.pre-cumulus.* ~/.config/quickshell/caelestia 2>/dev/null || true
rm -rf ~/.local/share/cumulus ~/.local/state/cumulus
# revert the shell.json keys you merged (deformScale/border/…) by hand if desired
qs -c caelestia kill; caelestia shell -d
```
