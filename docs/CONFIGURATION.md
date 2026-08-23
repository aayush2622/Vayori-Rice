# Configuration reference

The `.nix` files in this repo are kept comment-free on purpose - this file
is where the "why" lives instead. It's organized to match `modules/`, so
if you're reading a file and wondering why something is the way it is,
find the matching heading here.

For "how do I add a host/user/app", see the README's
[Using this on your own machine](../README.md#using-this-on-your-own-machine)
and [Extending it](../README.md#extending-it) sections - this file is the
deeper reference, not the walkthrough.

## Contents

- [How it's wired together](#how-its-wired-together)
- [modules/hosts/\<name\>/host.nix](#moduleshostsnamehostnix)
- [modules/hosts/\<name\>/\_hardware.nix](#moduleshostsname_hardwarenix)
- [modules/users/users.nix](#modulesusersusersnix)
- [modules/features/dms.nix](#modulesfeaturesdmsnix)
- [modules/features/niri.nix](#modulesfeaturesnirinix)
- [modules/features/dev-system.nix](#modulesfeaturesdev-systemnix)
- [modules/features/grub-theme.nix](#modulesfeaturesgrub-themenix)
- [modules/apps/zen-browser.nix](#modulesappszen-browsernix)
- [modules/apps/nautilus.nix](#modulesappsnautilusnix)
- [modules/apps/android-studio.nix](#modulesappsandroid-studionix)
- [modules/apps/dev-tools.nix](#modulesappsdev-toolsnix)
- [modules/apps/terminal/terminal.nix](#modulesappsterminalterminalnix)
- [modules/home/baseline.nix](#moduleshomebaselinenix)
- [modules/features/fonts.nix / portals.nix](#modulesfeaturesfontsnix--portalsnix)

---

## How it's wired together

`flake.nix` calls `inputs.import-tree ./modules`, which recursively
imports every `.nix` file under `modules/` as a flake-parts module - there
is no manual import list anywhere. Two consequences that aren't obvious
from reading any single file:

- **Any path containing `/_` is skipped** by import-tree. This repo uses
  that deliberately for `_hardware.nix` (see below) so it can be a plain
  NixOS module instead of a named `flake.nixosModules.*` one.
- **Nix flakes only see git-tracked files.** When working in this repo
  locally, a new `.nix` file that hasn't been `git add`ed yet is invisible
  to `nix flake check`/`nix build` - it'll silently evaluate as if the
  file doesn't exist (e.g. `nixosConfigurations` coming back empty) rather
  than erroring. `git add` new files before troubleshooting an "it's not
  picking this up" problem.

Two flake-parts option namespaces get populated across all those files:

| Namespace | Who sets it | Who reads it |
| --- | --- | --- |
| `flake.nixosModules.*` | hosts, features, `users.nix` | `host.nix`'s `modules` list |
| `flake.homeModules.apps.*` | `modules/apps/*.nix` | `users.nix`, via `vayori.apps` |

## `modules/hosts/<name>/host.nix`

**A bare inline lambda module right after a `path` list element parses as
function application, not two list elements.** Concretely:

```nix
modules = [
  ./_hardware.nix
  { pkgs, ... }: { ... }   # BROKEN - parses as `./_hardware.nix { pkgs, ... }`
];
```

Nix sees `./_hardware.nix` followed by `{`, and because whitespace is also
how function application works in Nix, it tries to apply the path to what
looks like an attrset argument - then fails parsing `{ pkgs, lib, ... }`
as a *set* (not a lambda pattern, since a bare lambda isn't valid in an
applied-argument position), with a confusing `unexpected ','` error. The
fix is wrapping the inline module in parens: `({ pkgs, ... }: { ... })`,
which is what `host.nix` does. Keep the parens if you add another inline
module to the list.

**Build/closure settings**: `nix.settings.auto-optimise-store = true`
hardlinks identical files across store paths (free disk savings, tiny CPU
cost per build). `documentation.nixos.enable = false` skips building the
local NixOS manual + `nixos-help`, which saves real build time and store
space; `man configuration.nix` still works, and `nixos-option`/the online
search still cover option docs.

**Cursor on the SDDM login screen**: `services.displayManager.sddm`'s
Wayland greeter runs under Weston as its own systemd service
(`display-manager.service`), so it never sees `environment.sessionVariables`
(that's only exported to login shells via PAM, i.e. *after* you're already
logged in). Without `XCURSOR_THEME`/`XCURSOR_SIZE` in the service's own
environment, Weston has no cursor theme to load and draws no pointer at
all - hence `systemd.services.display-manager.environment` is set
separately, with the same values, specifically for this. The cursor
package (`bibata-cursors`) also has to be in `environment.systemPackages`
(system-wide), not just pulled in via home-manager for a user - SDDM runs
before any user session exists.

**Apps** (`vayori.apps`): pick from whatever file names exist under
`modules/apps/`. This is the one setting a new machine's config usually
needs to change.

**Users** (`vayori.users`): each entry corresponds to a real account (see
[users.nix](#modulesusersusersnix) below for what each field does).
Generate a password hash with `mkpasswd -m sha-512`.

## `modules/hosts/<name>/_hardware.nix`

Unlike every other file under `modules/`, this one is a **plain NixOS
module** - no `flake.nixosModules.X = ...` wrapper. It's imported directly
by relative path from `host.nix` (`./_hardware.nix`), and the leading
underscore in the filename is what makes import-tree skip it, so it never
gets independently registered as its own flake-parts module (which would
fail - a raw NixOS module's top-level keys like `boot`/`fileSystems`
aren't valid flake-parts options).

To generate your own for a different machine: boot the target machine
(live ISO or existing install) and run

```bash
sudo nixos-generate-config --show-hardware-config > modules/hosts/<name>/_hardware.nix
```

then drop the Nvidia/Optimus block entirely unless you also have an
Nvidia Optimus laptop - `intelBusId`/`nvidiaBusId` are PCI addresses
specific to this one machine (`lspci` to find yours if you do need it).

The Nvidia block itself, for reference:
- `powerManagement.enable`/`finegrained` - laptop-specific: lets the dGPU
  power all the way down when nothing is using it via PRIME offload,
  instead of staying on and draining battery.
- `open = false` - the RTX 3050 (Ampere) supports the open kernel module
  (`open = true`), but closed is the safer default.
- `prime.offload` - iGPU drives the display, dGPU spins up only for apps
  launched explicitly with `nvidia-offload <cmd>` (best battery life). For
  "dGPU renders everything, always on" instead, swap for `prime.sync.enable
  = true` and drop the two `powerManagement` lines.
- `services.asusd` - ASUS ROG GPU switching (supergfxctl). If the dGPU
  doesn't show up in `lspci` at all, supergfxctl likely has it fully
  powered off in Integrated mode - run `supergfxctl -m Hybrid` (needs a
  reboot) and `supergfxctl -g` to check the current mode.
- `systemd.services.supergfxd.path = [ pkgs.pciutils ]` works around a
  known nixpkgs bug where supergfxd can't find the dGPU without pciutils
  on its `PATH` - [NixOS/nixpkgs#239059](https://github.com/NixOS/nixpkgs/issues/239059).

## `modules/users/users.nix`

Shared framework - defines what a `vayori.users.<name>` entry can contain
and how it turns into an actual account. Never touch this file to add a
*person* (that's inline in a host's `host.nix`); only touch it to change
what options a user entry supports.

- `hashedPassword`: generate with `mkpasswd -m sha-512`. Leave `null` to
  fall back to `initialPassword = "changeme"` (run `passwd` after first
  login).
- `extraGroups`: add `"wheel"` for sudo access, `"adbusers"` for Android
  debugging (see [android-studio.nix](#modulesappsandroid-studionix)),
  etc.
- `availableApps` is auto-discovered from `modules/apps/*.nix` - add a new
  app by dropping a file there; nothing here needs to change.

## `modules/features/dms.nix`

**Applied to every user in `vayori.users`**, not hardcoded to one account
- `home-manager.users = lib.genAttrs (builtins.attrNames config.vayori.users) (name: { ... })`.
  Hardcoding it to one user was an earlier bug in this repo: a second
  account would get a niri session with no shell running in it at all.

**`settings = { ... }` is the only valid key.** DMS's home-manager module
also has an older `default.settings = { ... }` shape from a previous
version - using that instead is a silent no-op. If a setting you set isn't
taking effect, check you're under `programs.dank-material-shell.settings`,
not `default.settings`.

**Wallpaper default folder**: `xdg.stateFile."DankMaterialShell/session.json"`
seeds `wallpaperPath` (the current wallpaper) and `wallpaperCyclingFolderPath`
(the auto-cycle/browse-default folder) to point at `modules/wallpapers`.
Both live in DMS's *session* state (`~/.local/state/DankMaterialShell/session.json`),
separate from `settings.json`. Like `settings.json`/`plugin_settings.json`,
this is force-written declaratively, so DMS can still switch wallpapers
live between rebuilds, but it resets back to this default on the next
`nixos-rebuild switch`.

**Section map** (the settings block, in order): theme, compositor, weather,
animation, blur, wallpaper, bar/general widgets, control center,
workspaces, media, greeter, launcher, dashboard, fonts, notepad, sounds,
power, matugen (per-app template toggles - this is what themes niri's
window borders too, see below), dock, notifications, lock screen,
notification/OSD, power menu, updater, displays, desktop clock, system
monitor, desktop widgets, frame.

## `modules/features/niri.nix`

**`extraSettings` has to be a sibling of `settings`**, not nested inside
it - `wrapper-modules.wrappers.niri.wrap { settings = { extraSettings = [...]; }; }`
would serialize `extraSettings` as a literal (invalid) KDL node instead of
using the wrapper's actual `extraSettings` mechanism.

**The `include "dms/colors.kdl"` gotcha**: DMS (via
`matugenTemplateNiri = true`, see [dms.nix](#modulesfeaturesdmsnix))
renders `~/.config/niri/dms/colors.kdl` from the current wallpaper's
palette on every theme change, and this file's `extraSettings` includes it
so niri picks up the dynamic colors. `optional = true` on that include so
niri still starts before DMS has run once and generated the file.

The problem: niri's config format hard-rejects **two static top-level
`layout { }` nodes** in the same file (`niri validate` errors with
`duplicate node 'layout', single node expected`) - but an `include`'d
`layout { }` block *merges* into the already-parsed one instead of
erroring, which is exactly how DMS's color theming is meant to work. That
merge means DMS's include silently overwrote this repo's translucent
`layout.border` colors with matugen's fully-opaque ones. The fix is a
*second* `include`, listed after DMS's, pointing at a small
`pkgs.writeText`-generated KDL file that re-asserts just
`layout.border` - since includes merge (not duplicate-error), the second
one wins and undoes just the border override, while shadow/focus-ring/
insert-hint/etc. from DMS stay dynamically themed. (Passing that
`pkgs.writeText` derivation to `include` needs `"${...}"` string
interpolation, not the bare derivation - `wlib.toKdl` recurses into a bare
derivation attrset as if it were nested KDL and stack-overflows.)

**`blur.passes = 2`** instead of niri's config default of 3: each pass
roughly doubles the render cost, and it's rendered on the Intel iGPU
(niri itself isn't PRIME-offloaded to the dGPU on this machine) -
visually near-identical to 3, cheaper to run.

**`spawn` vs `spawn-sh`**: plain `spawn = [ "cmd" ]` execs directly;
`spawn-sh = "cmd"` forks `sh -c "cmd"` first. Most binds here use `spawn`
since the commands don't need shell features (piping, `$(...)`, etc.) -
the brightness binds are the exception, since they pipe `dms ipc call
brightness list` through `awk` to find the actual backlight device name,
which does need a real shell.

## `modules/features/dev-system.nix`

`programs.adb.enable` was removed upstream - systemd 258+ handles the adb
uaccess udev rules automatically, and `pkgs.android-tools` (already in
[android-studio.nix](#modulesappsandroid-studionix)) is all that's needed
for the `adb` command itself. `users.groups.adbusers` is still declared
here purely so it's a valid `extraGroups` entry for anyone whose `host.nix`
still lists it - nothing actually grants special access through it anymore.

## `modules/features/grub-theme.nix`

`grub-theme` (the flake input) isn't a flake or a nix package, it's a
plain repo meant to be installed with its own shell script. This module
instead fetches its source via the flake input and points
`boot.loader.grub.theme` straight at the theme directory inside it, which
is exactly what that option expects (a directory containing `theme.txt`).

Double-check the exact subfolder name (`SekiroShadow` currently) after
your first `nixos-rebuild switch` - if GRUB doesn't pick it up, run
`ls ${inputs.grub-theme}` in `nix repl` and adjust the path to match.

## `modules/apps/zen-browser.nix`

- `zenPrefs`: check these out at `about:config`.
- Adding an extension: find the short ID in the addon's `addons.mozilla.org`
  URL, then look up its actual `guid` at
  `https://addons.mozilla.org/api/v5/addons/addon/!SHORT_ID!/`.
- Noctalia can also theme Zen directly (Settings -> Color Scheme ->
  Templates -> Zen Browser) via CSS injection - see
  <https://docs.noctalia.dev/v4/theming/program-specific/zenbrowser/>.

## `modules/apps/nautilus.nix`

- `thumbnail-limit = 200`: thumbnail bigger files instead of falling back
  to a generic icon.
- `mouse-use-extra-buttons`: back/forward mouse buttons navigate history.
- `open-folder-on-dnd-hover`: auto-enter a hovered folder mid drag-and-drop
  instead of requiring a manual click.
- `window-state.maximized`: open Files maximized instead of the cramped
  890x550 default.
- `media-handling`: drives/USB sticks/SD cards mount automatically, pop
  open a Files window when they do, and never auto-run scripts from them.
- `nautilus-open-any-terminal` defaults to gnome-terminal, which isn't
  installed here - pointed at kitty instead (see
  [terminal.nix](#modulesappsterminalterminalnix)).
- gvfs + tumbler (thumbnails/mounting) are enabled system-wide in
  `hosts/<name>/host.nix` since they're daemons, not per-user.

## `modules/apps/android-studio.nix`

`adb` device access works out of the box (systemd 258+ handles the
uaccess udev rules automatically, see
[dev-system.nix](#modulesfeaturesdev-systemnix)) - `"adbusers"` in a
user's `extraGroups` is optional compatibility, not required.

## `modules/apps/dev-tools.nix`

`git` itself isn't listed here - it's already in the base
`environment.systemPackages` (`host.nix`), since flakes need it
system-wide regardless of which apps are picked.

## `modules/apps/terminal/terminal.nix`

Kitty + zsh (oh-my-zsh) + fastfetch, as one selectable app. The
`initContent` shell script picks a random logo image from
`modules/apps/terminal/images/` on every new shell (falls back to
fastfetch's default logo if the directory is empty).

## `modules/home/baseline.nix`

Imported for every user regardless of `vayori.apps` - GTK/Qt theming is
the one piece of the rice nobody opts out of.

## `modules/features/fonts.nix` / `portals.nix`

- `nerd-fonts.jetbrains-mono`: kitty + bar monospace glyphs.
- `material-symbols`: DMS's icon font.
- `xdg-desktop-portal-gnome`: file pickers, screenshots, screencast (works
  well with niri).
- `xdg-desktop-portal-gtk`: GTK file chooser used by Nautilus & friends.
