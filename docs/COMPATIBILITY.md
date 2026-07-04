# Compatibility

Cumulus is a fork of the Caelestia **shell**, so it is tied to a specific upstream version.
The `shell/` tree here was built and tested against:

| Component          | Supported version | Revision |
|--------------------|-------------------|----------|
| **caelestia-shell**| **2.0.3**         | `ebb01721a33722195b929e7105401cebe2e119d8` |
| **caelestia-cli**  | **1.1.0**         | — |
| **Quickshell**     | **0.3.0**         | `68c2c85c33845385f7ab8147b32f1450b1e468e0` |
| **Hyprland**       | **0.55.4**        | — |

Check yours with:

```sh
caelestia --version      # shell + cli
quickshell --version
hyprctl version
```

## What "supported" means

- The `shell/` QML expects the `Caelestia.Config` plugin API (`Tokens.rounding/padding/font`,
  `GlobalConfig.*`) shipped with **caelestia-shell 2.0.3**. That plugin is compiled into the
  package — it is **not** part of this repo — so a newer/older shell package can change the
  API the skin relies on.
- The scheme tooling imports Caelestia CLI internals
  (`caelestia.utils.theme.apply_colours`, `caelestia.utils.paths`). These are **1.1.0**
  internals; if the CLI refactors them, `install-schemes.sh` / the cycle script may need
  updating.

## If your Caelestia is newer

The safest path is to re-apply the Cumulus changes on top of the newer upstream shell rather
than dropping in this older tree wholesale. The isolated change-set (65 modified + 3 new QML
files) is listed in [PLAN.md](../PLAN.md); those are the files that carry the skin. A future
release may ship a **slim overlay** (only the changed files) to make tracking upstream easier.
