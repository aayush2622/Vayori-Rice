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
- [modules/apps/spicetify.nix](#modulesappsspicetifynix)
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

**`vayori.theme`** is declared right here, inline in `host.nix`'s own
module - deliberately *not* split into a separate shared file the way
`vayori.users`/`vayori.apps` are (those live in `users.nix` because
they're genuine cross-host framework; theme is a per-host preference, and
this repo only has the one host). `options.vayori.theme = lib.mkOption {
type = lib.types.submodule { ... }; };` declares a submodule with sane
defaults baked in (JetBrainsMono Nerd Font, Bibata-Modern-Ice,
Tela-circle - what this host actually uses), so **a host doesn't have to
set anything to get a working theme, and overriding is a single line**
inside `config`: `vayori.theme.font = "Fira Code";` changes it everywhere
at once - fontconfig, GTK, kitty, and DMS all read from the same option,
no separate edits. Each field is independently overridable - override
just `vayori.theme.cursorSize` without redeclaring the whole thing.

**Reaching every consumer**: NixOS-level modules (`fonts.nix`, `dms.nix`,
`host.nix` itself) just read `config.vayori.theme.*` directly - it's a
normal option, always available via `config` regardless of which file
declared it, no special plumbing needed. home-manager per-app modules
(`baseline.nix`, `terminal.nix`) are the one place that still needs help:
home-manager's per-user submodules are a *separate* module system
instantiation that never sees the parent NixOS `config` at all -
`users.nix` re-exports the resolved attrset into
`home-manager.extraSpecialArgs = { vayoriTheme = config.vayori.theme; ... };`,
which is what makes it available to every home-manager app module.

Left out on purpose: the SDDM greeter's bundled font and GRUB's theme
package aren't wired to `vayori.theme` - see
[fonts.nix / portals.nix](#modulesfeaturesfontsnix--portalsnix) for why.

**A module can't mix `options.x = ...` with implicit-config keys at the
same level.** Once `host.nix`'s inline module declares
`options.vayori.theme`, every other setting in that same module (
`vayori.users`, `networking.hostName`, all of it) has to move under an
explicit `config = { ... };` - the usual shorthand where any non-reserved
top-level key is implicitly treated as config only applies when the
module has *no* `options`/`config` key at all. Skipping this produces
`Module '...' has an unsupported attribute 'boot'. ... introducing a
top-level 'config' or 'options' attribute` - a real error hit while
building this option inline, not a hypothetical.

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

**Cursor on the SDDM login screen** - three separate gaps, each real and
independently confirmed, not guessed at:

1. `services.displayManager.sddm`'s Wayland greeter runs under Weston as
   its own systemd service (`display-manager.service`), so it never sees
   `environment.sessionVariables` (only exported to login shells via PAM,
   *after* you're already logged in) - hence
   `systemd.services.display-manager.environment` is set separately, with
   the same values, specifically for Weston.
2. **Weston itself doesn't reach the greeter's own process environment.**
   Traced through SDDM's actual C++ source (`Backend.cpp`): when SDDM
   spawns the greeter, it explicitly re-applies `GreeterEnvironment` on
   top of whatever the greeter would otherwise inherit, specifically when
   `XDG_SESSION_CLASS == "greeter"` - meaning env vars set at the Weston/
   systemd-service level are **not** guaranteed to reach the greeter
   client itself. `services.displayManager.sddm.settings.General.GreeterEnvironment`
   (a comma-separated `VAR=value` string, confirmed from source - not the
   NixOS module's usual attrset shape) is the documented, direct
   mechanism for this.
3. **NixOS isn't FHS - `/usr/share/icons` doesn't exist.** Xcursor's
   default search path falls back to that hardcoded path, and to
   `$XDG_DATA_DIRS/icons`, when `XCURSOR_PATH` isn't set - on NixOS
   neither resolves to anything useful for a system-level service like
   SDDM (no equivalent of a normal login session's `XDG_DATA_DIRS`,
   which usually comes from PAM/systemd user setup this process never
   goes through). Getting `XCURSOR_THEME` right doesn't matter if nothing
   can locate the actual theme files - `XCURSOR_PATH` is set explicitly
   to `${config.vayori.theme.cursorPackage}/share/icons`, the exact
   store path, removing all ambiguity about search-path fallbacks.
   `config.vayori.theme.cursorPackage` also has to be in
   `environment.systemPackages` (system-wide), not just pulled in via
   home-manager for a user - SDDM runs before any user session exists.

All three were verified against source (Weston's own `libweston`/
`kiosk-shell`/`desktop-shell` - confirmed zero server-side cursor
fallback either way, cursor rendering is 100% client-responsibility) and
against real evaluated config values, and the built VM was actually
booted and screenshotted via QMP to check. **Caveat worth knowing**:
QEMU's `screendump` captures the primary framebuffer surface and is a
known-unreliable way to check for a cursor - many DRM/KMS drivers
composite the pointer via a separate hardware cursor plane that
`screendump` doesn't necessarily include, so "not visible in a
screendump" isn't conclusive proof it's still broken on real display
output (VNC/SPICE/real hardware). All three fixes above are independently
correct regardless of what the screendump did or didn't show.

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
- **`services.asusd` and `services.supergfxd` are two entirely separate
  daemons**, despite both being part of the asus-linux project and both
  living in `nixpkgs/nixos/modules/services/hardware/`.
  `services.asusd` is `asusctl` - keyboard LEDs, fan curves, battery
  charge limits. **It does not touch GPU switching at all.** GPU mux
  switching (Integrated/Hybrid/dGPU) is `supergfxctl`, a completely
  different binary/daemon/systemd unit, gated behind its own
  `services.supergfxd.enable`. Enabling only `services.asusd` - which
  this repo did for a while - leaves `supergfxd` never actually running,
  so nothing ever issues the mux switch back to Hybrid: whatever state
  the firmware/EC left the dGPU in (commonly fully powered off, to save
  battery) just persists forever, indistinguishable from "the dGPU is
  properly connected but the nvidia driver still can't see anything" -
  which looks exactly like the black-screen-in-VM symptom above, but
  isn't fixable the same way, because here the GPU really is physically
  off, not merely mismatched with the display backend.
  `services.supergfxd.settings.mode = "Hybrid"` (confirmed against
  supergfxctl's own Rust source, `src/config.rs` - a plain JSON file at
  `/etc/supergfxd.conf`, `mode` matching the `GfxMode` enum variant name
  exactly) makes this declarative instead of a one-time
  `supergfxctl -m Hybrid && reboot` that has to be remembered and redone
  on every fresh install. `supergfxctl -g` still checks the current mode
  live if something ever looks off.
- `systemd.services.supergfxd.path = [ pkgs.pciutils ]` works around a
  known nixpkgs bug where supergfxd can't find the dGPU without pciutils
  on its `PATH` - [NixOS/nixpkgs#239059](https://github.com/NixOS/nixpkgs/issues/239059).
  This override was silently inert before `services.supergfxd.enable`
  was actually set - overriding a systemd unit that doesn't exist yet is
  accepted without error, it just has nothing to attach to.

**`virtualisation.vmVariant`** fixes niri showing a black screen under
`nixos-rebuild build-vm`: that command evaluates this *exact* config,
Nvidia driver stack included, but QEMU has no Nvidia GPU for it to bind
to, so niri never gets a working DRM device. `services.xserver.videoDrivers`
gates NixOS's entire Nvidia module internally via `mkIf (elem "nvidia"
... videoDrivers)`, so clearing just that one option for the VM build is
enough to disable the whole stack and let niri fall back to the generic
`modesetting` driver, which QEMU's virtual GPU works with out of the box.
`virtualisation.vmVariant.*` is the standard NixOS mechanism for this -
config nested under it only ever applies to `system.build.vm`/
`nixos-rebuild build-vm`, never to the real system (confirmed by
evaluating both: the real config keeps `videoDrivers = [ "nvidia" ]`,
only `config.virtualisation.vmVariant.services.xserver.videoDrivers`
- note: no `.config` in the middle, that option's value *is* the merged
config directly - changes). `services.asusd`/`services.supergfxd` are
disabled the same way for the VM, since there's no ASUS hardware to
switch there either.

Clearing the Nvidia stack still left the VM stuck black after "Reached
target Graphical Interface" - a second, separate bug, confirmed by
logging into the VM over a bidirectional QEMU serial socket (SDDM's
Wayland greeter has no serial/TTY output of its own, so this required
reading `journalctl -u display-manager` as root): every process (sddm,
weston, sddm-greeter-qt6) was alive and healthy, weston's own compositor
even initialized OpenGL fine over `llvmpipe`, but the *greeter's* QML
frontend (`sddm-greeter-qt6`, a separate process that talks to weston as
a Wayland client) logged `libEGL warning: failed to get driver name for
fd -1` then `MESA: error: ZINK: failed to choose pdev` and produced
nothing else, ever - no crash, just a permanently blank surface. Cause:
QEMU's `bochs-drm` device is a dumb framebuffer with no DRI2 driver, so
a Wayland *client* requesting a hardware-accelerated EGL context (as
opposed to weston's own server-side renderer, which talks to
`/dev/dri/card0` directly) can't authenticate one; Mesa's automatic
fallback to `zink` (OpenGL-over-Vulkan) then also fails because there's
no Vulkan ICD (lavapipe) available either. Fix: force the greeter's Qt
Quick scene graph to skip EGL/GL entirely via `QT_QUICK_BACKEND=software`
in the VM's `GreeterEnvironment` (`_hardware.nix`, `virtualisation.vmVariant`
only - real hardware has a proper Intel iGPU with working DRI2/dmabuf, so
it doesn't need this and shouldn't pay the software-rendering cost).
`GreeterEnvironment` is a single flat string option, so the VM override
uses `lib.mkForce` to fully re-specify it (cursor vars included) rather
than trying to merge/append onto `host.nix`'s copy.

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
- Every user's `home-manager-<name>.service` is given
  `after`/`wants = [ "network-online.target" ]` here, generically for
  all `vayori.users` - not specific to any one app module. Any app's
  home-manager activation script that touches the network (currently
  [zen-browser.nix](#modulesappszen-browsernix)'s mods/profile fetch) is
  otherwise racing whatever NIC/DHCP state boot happens to be in.

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

- **The profile is always `~/.zen/default`** - this repo owns that one
  fixed, predictable path rather than discovering or importing whatever
  profile a previous Arch/Flatpak install happened to name. Earlier
  versions of this file tried to locate an existing profile (globbing on
  directory names, then parsing `profiles.ini`'s `[InstallXXXX]
  Default=` line), which existed to migrate an already-configured
  profile - unneeded complexity once the goal is just "apply this
  theme/mods/extensions/settings," not "carry over whatever's already
  there." If `~/.zen/default` doesn't exist yet, the activation script
  creates it (see the bootstrap note below); if it does, it's reused
  and re-synced on every `home-manager switch`.
- `zenPrefs`: check these out at `about:config`.
- **`zenUserPrefs`/`zenUserJs`**: the actual look-and-feel state
  (compact mode, floating urlbar, hidden sidebar, and - critically -
  every installed mod's *tuned* preference values: background image,
  blur amount, colors, custom font) extracted directly from a real
  running profile's `prefs.js`, not guessed at or left to each mod's own
  defaults. Written to a declarative `user.js` in the profile (same
  `pkgs.writeText` + `ln -sf` pattern as `userChrome.css`) rather than
  locked via `zenPrefs`/`lockPref`, on purpose: these are values you'd
  reasonably keep tweaking live through Zen's own Settings UI (background
  image, blur amount, ...), and `lockPref` would freeze them forever.
  `user.js` gets re-applied on every browser launch, so - same trade-off
  already accepted for DMS's `settings.json` and the Zen Mods registry -
  a live tweak through the UI resets back to what's declared here on the
  next restart, not just the next `nixos-rebuild switch`. Left out on
  purpose: Firefox Sync/`identity.fxaccounts.*` state (account-tied, not
  config), `network.proxy.*` (real IP visible in the source profile,
  and inactive anyway - `network.proxy.type` was `0`/direct), and
  `browser.backup.location` (hardcodes the source machine's home path,
  which may not match whatever username ends up used here).
- **Adding an extension** (`zenExtensions`): find the `slug` in the
  addon's `addons.mozilla.org` URL, then look up its actual `guid` at
  `https://addons.mozilla.org/api/v5/addons/addon/!SLUG!/` (or the search
  endpoint, `.../api/v5/addons/search/?q=!NAME!&app=firefox`, if you don't
  have the exact slug - useful since some extensions have several
  same-named listings from different authors; match on `summary` text and
  `average_daily_users` to find the real one).
  **Why both `slug` and `guid`, and why hardcoded rather than resolved
  automatically like `zenMods` are**: `slug` is AMO's URL-friendly listing
  name (used for the `.../downloads/latest/<slug>/latest.xpi` download
  URL) and can be renamed by the author; `guid` is the extension's actual
  manifest id (`browser_specific_settings.gecko.id`), fixed forever, which
  is what Firefox's `ExtensionSettings` policy keys on to match an
  installed extension to its policy entry - neither can substitute for
  the other, and Firefox's policy schema requires the real `guid` as the
  key, full stop. Unlike `zenMods`' registry (which lives in the mutable
  `$HOME` profile and gets populated by an *activation script*, free to
  hit the network at apply-time), `ExtensionSettings` gets baked into
  `policies.json` **inside the immutable Nix-built package itself** at
  eval/build time - and flakes evaluate purely, without network access,
  specifically so the same config produces the same result on any machine
  regardless of network state. There's no build-time equivalent of "just
  curl the AMO API to resolve a slug to its guid" available here.
- **Dynamic wallpaper-matched theming**: Zen doesn't support Pywalfox or
  Firefox theme extensions - theming works through `userChrome.css`
  instead. DMS renders `~/.config/DankMaterialShell/zen.css` from the
  current wallpaper's palette (`matugenTemplateZenBrowser = true`, in
  [dms.nix](#modulesfeaturesdmsnix)); `home.activation.zenBrowserConfig`
  here symlinks that file to `chrome/userChrome.css` in `~/.zen/default`.
  `toolkit.legacyUserProfileCustomizations.stylesheets` (required for any
  `userChrome.css` to take effect at all) is locked on via `zenPrefs`, so
  there's no manual `about:config` step. If `~/.zen/default` doesn't
  exist yet (a genuinely fresh install that's never launched Zen), the
  activation script bootstraps it via
  `zen -CreateProfile "default $HOME/.zen/default"` before symlinking
  anything. That command still goes through GTK's normal init path even
  though it never opens a window, so it fails with "no DISPLAY
  environment variable specified" when run headless from a systemd
  activation service - it's wrapped in `pkgs.xvfb-run` (a throwaway
  virtual X server) specifically to satisfy that. First-run theming and
  mods now apply with zero manual steps.
- **Zen Mods** (`zenMods`, also inside `home.activation.zenBrowserConfig`
  - one activation script handles theming, `user.js`, and mods together,
  since they all need the same resolved `$PROFILE_DIR`) are a completely
  separate system from the `userChrome.css` theming above - traced
  through Zen's actual source
  (`src/zen/mods/ZenMods.mjs`/`ZenStyleSheetCache.h` in
  [zen-browser/desktop](https://github.com/zen-browser/desktop)) rather
  than guessed at, since getting the storage format wrong would just
  silently do nothing:
  - `<profile>/zen-themes.json` is the registry - a JSON *object* keyed
    by mod `id` (not an array), each value the mod's metadata plus
    `enabled`.
  - `zenMods` in the Nix file is deliberately just a `name -> id` map,
    nothing richer - unlike `zenExtensions`, this one *can* be dynamic.
    [zen-browser/theme-store](https://github.com/zen-browser/theme-store)
    publishes `themes.json`, a single index with every mod's full
    metadata (name, description, author, version, tags, style/readme/
    image URLs, ...), keyed by the same `id`. The activation script
    fetches that index live, `jq`-filters it down to just the ids in
    `zenMods`, stamps `enabled: true` onto each, and writes the result
    straight to `<profile>/zen-themes.json` - no metadata is hand-copied
    into this repo at all, so it can't drift out of date the way a
    hardcoded copy would. This works here (and not for `zenExtensions`)
    because it happens at *activation* time, in the user's mutable
    `$HOME`, which is allowed to touch the network - `zenExtensions`
    bakes into the immutable Nix-built package itself at eval/build
    time, where flakes deliberately evaluate without network access.
  - Each mod's actual `chrome.css` (and `preferences.json`) gets fetched
    with `curl` into `<profile>/chrome/zen-themes/<id>/` separately -
    genuinely apart from `userChrome.css`, since Zen loads
    `zen-themes.css` natively via its own stylesheet cache, not through
    the chrome CSS Zen's own `#rebuildModsStylesheet` reads at startup.
    Fetched only if the file doesn't already exist
    (`[ -f ... ] || curl ...`), so this doesn't hit the network on every
    single `nixos-rebuild switch` - only once per mod, and it self-heals
    if a file goes missing. `preferences.json` is attempted for every
    mod unconditionally (harmless 404 + `|| true` for the ones without
    one - `curl -f` doesn't write anything to disk on a failed request).
  - **One broken mod can take down every mod.** Zen's own compile step
    (`#writeStylesheet` in `ZenMods.mjs`) loops over enabled mods and
    calls `IOUtils.readUTF8` on each one's `chrome.css` with no
    per-mod try/catch - if that file is missing for even one enabled
    mod, the whole rebuild throws, caught by one outer try/catch in
    `init()`, and *no* mod's CSS gets applied that session. One entry
    from the original request - "Remove Browser Padding"
    (`680424a8-...`) - is missing from `theme-store`'s `themes.json`
    entirely (confirmed directly against the index, not just a broken
    URL guess), so it's simply not in `zenMods` here: fetching the live
    index naturally omits it, rather than needing an explicit
    `enabled = false` override the way a hardcoded list would have.
    Add it back to `zenMods` if/when upstream restores it.
  - Every `curl` call in this activation script is `${pkgs.curl}/bin/curl`,
    never bare `curl` - found the hard way, by actually booting a fresh
    VM and checking: an interactive login shell's `PATH` includes
    `curl` (it's in `environment.systemPackages`), but the
    `home-manager-<user>.service` systemd unit that *runs* activation
    scripts has a much narrower `PATH`, so a bare `curl` there fails
    with "command not found" - silently, since `fetch_if_missing` and
    the mods-index fetch both already tolerate curl failing (that's
    what lets a machine with genuinely no network still apply the rest
    of the config). `${pkgs.jq}/bin/jq` a few lines below was already
    written the safe way; `curl` just hadn't been.
  - `home-manager-<user>.service` (defined per-user in
    [users.nix](#modulesusersusersnix)) is given
    `after`/`wants = [ "network-online.target" ]`, so activation - and
    this script's network calls - don't race a NIC that's still coming
    up during boot. `NetworkManager-wait-online.service` (which backs
    that target here, since `networking.networkmanager.enable = true`)
    reached it in ~1s in VM testing, so this mostly matters on real
    hardware with a slower DHCP/link-up negotiation.

## `modules/apps/spicetify.nix`

- **Custom font**: Spotify's own client CSS (`xpui`) reads its UI font
  from the `--font-family` CSS custom property, not a generic
  `font-family: sans-serif` that fontconfig's `defaultFonts` (set
  system-wide in [fonts.nix](#modulesfeaturesfontsnix)) could satisfy on
  its own - it has to be overridden explicitly, hence
  `theme.additionalCss` setting `--font-family: "${vayoriTheme.font}"`.
  `theme.extraPkgs = [ vayoriTheme.fontPackage ]` makes that font an
  explicit dependency of the spiced Spotify derivation itself, rather
  than relying on it happening to already be installed system-wide.
  `spicePkgs.themes.hazy // { ... }` merges these onto the theme's
  existing options rather than replacing them - `theme` accepts a
  freeform attrset (`freeformType = attrsOf anything`), so this is safe.

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

**The system font everywhere it's set declaratively comes from
`vayori.theme.font`** (see [host.nix](#moduleshostsnamehostnix)):
`fontconfig.defaultFonts.sansSerif` (fonts.nix), GTK app UI text
(`gtk.font`, baseline.nix - not set before `vayori.theme` existed, GTK
apps used to fall back to whatever the theme's own default was), kitty, and
DMS's own shell UI (`fontFamily`/`monoFontFamily`, dms.nix - previously
independent hardcoded values, `Inter Variable`/`Fira Code`). Left alone on
purpose: the SDDM greeter's
clock/labels use a bundled `Itim-Regular.ttf` file shipped inside the
"women-umbrella" theme itself
([features/sddm/Theme/font/](../modules/features/sddm/Theme/font/)), not
a system fontconfig reference - switching that font means shipping a
different `.ttf` file in the theme, a separate (larger) change from a
settings tweak. Qt apps aren't covered either: their font comes from
qt6ct's own config, which Noctalia/DMS's matugen templates already manage
(`matugenTemplateQt6ct`/`matugenTemplateQt5ct`) - hand-editing it here
would fight that.
