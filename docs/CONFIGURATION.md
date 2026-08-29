# Configuration reference

The `.nix` files in this repo are kept comment-free on purpose — this file
holds the "why" instead. It's organized to match `modules/`: find a file
you're editing, jump to its section.

For "how do I add a host/user/app," see the README's
[Using this on your own machine](../README.md#using-this-on-your-own-machine)
and [Extending it](../README.md#extending-it) sections — this is the deeper
reference, not the walkthrough.

## Contents

- [How it's wired together](#how-its-wired-together)
- [Project structure](#project-structure)

**Core & hosts**
- [core/Users.nix](core.md#modulescoreusersnix)
- [core/DevLanguages.nix](core.md#modulescoredevlanguagesnix)
- [core/PluginUpdateCheck.nix](core.md#modulescorepluginupdatechecknix)
- [hosts/\<name\>/Host.nix](core.md#moduleshostsnamehostnix)
- [hosts/\<name\>/\_hardware.nix](core.md#moduleshostsname_hardwarenix)
- [hosts/\<name\>/Vm.nix](core.md#moduleshostsnamevmnix)

**Desktop**
- [desktop/Dms.nix](desktop.md#modulesdesktopdmsnix)
- [desktop/Niri.nix](desktop.md#modulesdesktopnirinix)
- [desktop/Fonts.nix / Portals.nix](desktop.md#modulesdesktopfontsnix--portalsnix)
- [desktop/Baseline.nix](desktop.md#modulesdesktopbaselinenix)
- [desktop/Matugen.nix](desktop.md#modulesdesktopmatugennix)

**System**
- [system/DevTooling.nix](system.md#modulessystemdevtoolingnix)
- [system/GrubTheme.nix](system.md#modulessystemgrubthemenix)

**Apps - development**
- [apps/development/editors/vscode/Vscode.nix](apps-development.md#modulesappsdevelopmenteditorsvscodevscodenix)
- [apps/development/editors/androidStudio/AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)
- [apps/development/editors/zed/Zed.nix](apps-development.md#modulesappsdevelopmenteditorszedzednix)
- [apps/development/devTools/DevTools.nix](apps-development.md#modulesappsdevelopmentdevtoolsdevtoolsnix)
- [apps/development/freeClaudeCode/FreeClaudeCode.nix](apps-development.md#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix)
- [apps/development/languages/\*/\*.nix](apps-development.md#modulesappsdevelopmentlanguagesnix) (Cpp, Rust, Kotlin, Flutter [+Dart], Nix, Qt)

**Apps - gaming**
- [apps/gaming/Gaming.nix](apps-gaming.md#modulesappsgaminggamingnix)

**Apps - utils**
- [apps/utils/zenBrowser/ZenBrowser.nix](apps-utils.md#modulesappsutilszenbrowserzenbrowsernix)
- [apps/utils/spicetify/Spicetify.nix](apps-utils.md#modulesappsutilsspicetifyspicetifynix)
- [apps/utils/nautilus/Nautilus.nix](apps-utils.md#modulesappsutilsnautilusnautilusnix)
- [apps/utils/bitwarden/Bitwarden.nix](apps-utils.md#modulesappsutilsbitwardenbitwardennix)
- [apps/utils/terminal/Terminal.nix](apps-utils.md#modulesappsutilsterminalterminalnix)
- [apps/utils/vesktop/Vesktop.nix](apps-utils.md#modulesappsutilsvesktopvesktopnix)

---

## How it's wired together

`flake.nix` calls `inputs.import-tree ./modules`, which recursively imports
every `.nix` file under `modules/` as a flake-parts module — no manual
import list anywhere. Two non-obvious consequences:

- **Any path containing `/_` is skipped.** Used deliberately for
  `_hardware.nix` so it can be a plain NixOS module instead of a named
  `flake.nixosModules.*` one.
- **Flakes only see git-tracked files.** A new `.nix` file that hasn't been
  `git add`ed is invisible to `nix flake check`/`nix build` — it silently
  evaluates as if it doesn't exist, rather than erroring. `git add` new
  files first if something "isn't picking up."

Two option namespaces get populated across these files:

| Namespace | Set by | Read by |
| --- | --- | --- |
| `flake.nixosModules.*` | `hosts/`, `desktop/`, `system/`, `core/Users.nix` | `Host.nix`'s `modules` list |
| `flake.homeModules.apps.*` | `modules/apps/**/*.nix` (any depth) | `core/Users.nix`, via `vayori.apps` |
| `flake.devLanguages.*` | `modules/apps/development/languages/*/*.nix` | `Vscode.nix`/`AndroidStudio.nix`, filtered by `vayori.apps` |

All of the above is attribute-name-based, not path-based — `Host.nix`
imports `self.nixosModules.dms`, never a file path. Moving a file to a
different directory never requires touching `Host.nix`'s `modules` list
or `vayori.apps`, only a rename of the attribute itself would.

## Project structure

```
modules/
  core/        flake-parts wiring + the shared user/app framework
  hosts/<name>/  one machine: Host.nix + _hardware.nix, nothing else
  desktop/     the DE stack — compositor, shell, login theme, fonts,
               portals, and the GTK/Qt baseline every user gets
  system/      system-level infra unrelated to the desktop
  apps/        per-user opt-in modules (vayori.apps), one folder each
  assets/      static, non-code files (wallpapers)
```

`core`/`desktop`/`system` boundary, briefly: **core** is pure
framework/wiring, nothing here is itself a "setting" (`Parts.nix`,
`Registry.nix`, and the `vayori.users`/`vayori.apps` option definitions in
`Users.nix`). **desktop** is everything that makes this specific rice look
and feel the way it does — swap the compositor or shell and this whole
category changes. **system** is infra that doesn't care what desktop
you're running (Docker, GRUB theming). The line between `desktop` and
`system` is "does this depend on niri/DMS specifically" — GRUB theming
doesn't, so it's `system`, not `desktop`, even though it's still
"theming."

`apps/` is split into three categories — `development/`, `gaming/`,
`utils/` — and every app is a folder (`apps/<category>/<name>/<name>.nix`)
whether or not it currently has extra assets alongside it, so adding a
font file or script to an app later never means restructuring it from a
flat file into a folder. The category is purely organizational: only the
`flake.homeModules.apps.<Name>` attribute name matters to the rest of the
repo (`vayori.apps`, `core/Users.nix`'s `availableApps`), so an app can
move between categories, or nest arbitrarily deep, without touching
anything outside its own folder.

`apps/development/editors/` holds the three editors (`Vscode`,
`AndroidStudio`, `Zed`), each a normal app plus a *consumer* of
`flake.devLanguages` (see below) — grouped in their own folder mainly so
"which apps are editors that read language data" is visible from the
directory listing alone, not something you'd otherwise have to grep for.

`apps/development/languages/` is its own thing within `development/`: one
folder per language (`Cpp`, `Rust`, `Kotlin`, `Flutter` — covers Dart too,
one toggle for both, see that section — `Nix`, `Qt`), each both a normal
app (`flake.homeModules.apps.<Lang>` installs that language's
LSP/toolchain) *and* a data source (`flake.devLanguages.<Lang>`) that
every editor above reads to decide which of its own extensions/plugins to
install — see [core/DevLanguages.nix](core.md#modulescoredevlanguagesnix).

`apps/gaming/` is one app (`Gaming`) split across multiple files for
readability: `Gaming.nix` is the actual `flake.homeModules.apps.Gaming`
entry, and `_launchers.nix`/`_proton.nix`/`_performance.nix` are plain
home-manager module fragments it `imports` by relative path — the leading
underscore keeps them out of import-tree's own auto-import (same trick as
`_hardware.nix`), since they aren't flake-parts modules on their own.

---

