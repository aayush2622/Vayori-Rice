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
- [core/users.nix](#modulescoreusersnix)
- [hosts/\<name\>/host.nix](#moduleshostsnamehostnix)
- [hosts/\<name\>/\_hardware.nix](#moduleshostsname_hardwarenix)

**Desktop**
- [desktop/dms.nix](#modulesdesktopdmsnix)
- [desktop/niri.nix](#modulesdesktopnirinix)
- [desktop/fonts.nix / portals.nix](#modulesdesktopfontsnix--portalsnix)
- [desktop/baseline.nix](#modulesdesktopbaselinenix)

**System**
- [system/dev-tooling.nix](#modulessystemdev-toolingnix)
- [system/grub-theme.nix](#modulessystemgrub-themenix)

**Apps**
- [apps/zen-browser/zen-browser.nix](#modulesappszen-browserzen-browsernix)
- [apps/spicetify/spicetify.nix](#modulesappsspicetifyspicetifynix)
- [apps/gaming/gaming.nix](#modulesappsgaminggamingnix)
- [apps/nautilus/nautilus.nix](#modulesappsnautilusnautilusnix)
- [apps/android-studio/android-studio.nix](#modulesappsandroid-studioandroid-studionix)
- [apps/vscode/vscode.nix](#modulesappsvscodevscodenix)
- [apps/dev-tools/dev-tools.nix](#modulesappsdev-toolsdev-toolsnix)
- [apps/bitwarden/bitwarden.nix](#modulesappsbitwardenbitwardennix)
- [apps/terminal/terminal.nix](#modulesappsterminalterminalnix)

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
| `flake.nixosModules.*` | `hosts/`, `desktop/`, `system/`, `core/users.nix` | `host.nix`'s `modules` list |
| `flake.homeModules.apps.*` | `modules/apps/*/*.nix` | `core/users.nix`, via `vayori.apps` |

All of the above is attribute-name-based, not path-based — `host.nix`
imports `self.nixosModules.dms`, never a file path. Moving a file to a
different directory never requires touching `host.nix`'s `modules` list
or `vayori.apps`, only a rename of the attribute itself would.

## Project structure

```
modules/
  core/        flake-parts wiring + the shared user/app framework
  hosts/<name>/  one machine: host.nix + _hardware.nix, nothing else
  desktop/     the DE stack — compositor, shell, login theme, fonts,
               portals, and the GTK/Qt baseline every user gets
  system/      system-level infra unrelated to the desktop
  apps/        per-user opt-in modules (vayori.apps), one folder each
  assets/      static, non-code files (wallpapers)
```

`core`/`desktop`/`system` boundary, briefly: **core** is pure
framework/wiring, nothing here is itself a "setting" (`parts.nix`,
`registry.nix`, and the `vayori.users`/`vayori.apps` option definitions in
`users.nix`). **desktop** is everything that makes this specific rice look
and feel the way it does — swap the compositor or shell and this whole
category changes. **system** is infra that doesn't care what desktop
you're running (Docker, GRUB theming). The line between `desktop` and
`system` is "does this depend on niri/DMS specifically" — GRUB theming
doesn't, so it's `system`, not `desktop`, even though it's still
"theming."

`apps/` is deliberately flat by *category* (every app is a peer under
`apps/`) but consistent by *shape* — every app is a folder
(`apps/<name>/<name>.nix`) whether or not it currently has extra assets
alongside it, so adding a font file or script to an app later never means
restructuring it from a flat file into a folder.

---

## `modules/hosts/<name>/host.nix`

**`vayori.theme`** is a submodule option declared inline here (not in a
shared file like `vayori.users`/`vayori.apps` — it's a per-host preference,
and this repo only has one host), with sane defaults baked in (JetBrainsMono
Nerd Font, Bibata-Modern-Ice, Tela-circle). Override one field without
redeclaring the rest: `vayori.theme.font = "Fira Code";` changes it
everywhere at once — fontconfig, GTK, kitty, DMS all read the same option.

NixOS modules read `config.vayori.theme.*` directly, like any option.
Home-manager modules can't — they're a separate module instantiation that
never sees the parent NixOS `config` — so `users.nix` re-exports it via
`home-manager.extraSpecialArgs = { vayoriTheme = config.vayori.theme; };`.

Not wired to `vayori.theme`: the SDDM greeter's bundled font and GRUB's
theme package — see [fonts.nix / portals.nix](#modulesdesktopfontsnix--portalsnix).

**Two Nix gotchas hit while building this file:**

1. A module can't mix `options.x = ...` with implicit top-level config keys.
   Once `options.vayori.theme` is declared, everything else has to move
   under `config = { ... };`, or NixOS throws `unsupported attribute 'boot'`.
2. An inline lambda module right after a `path` list element parses as
   function application, not two list items:

   ```nix
   modules = [
     ./_hardware.nix
     { pkgs, ... }: { ... }   # BROKEN — parses as `./_hardware.nix { pkgs, ... }`
   ];
   ```

   Fix: wrap it in parens — `({ pkgs, ... }: { ... })`.

**Build/closure**: `nix.settings.auto-optimise-store = true` hardlinks
identical files across store paths. `documentation.nixos.enable = false`
skips building the local NixOS manual (`man configuration.nix` and
`nixos-option` still work). `nix.gc = { automatic = true; dates =
"weekly"; options = "--delete-older-than 30d"; };` runs garbage
collection on a schedule — without this, `/nix/store` only ever grows;
old generations older than 30 days get collected weekly instead of
needing a manual `nix-collect-garbage -d`.

**SDDM login-screen cursor** — three independent gaps, each confirmed
against source, not guessed:

1. SDDM's Wayland greeter runs under Weston as its own systemd service
   (`display-manager.service`), so it never sees
   `environment.sessionVariables` (PAM-only, post-login). Fix:
   `systemd.services.display-manager.environment` sets the same vars
   directly for Weston.
2. Weston itself doesn't guarantee those vars reach the greeter *client*.
   Per SDDM's own source (`Backend.cpp`), it re-applies
   `services.displayManager.sddm.settings.General.GreeterEnvironment` (a
   comma-separated `VAR=value` string — not the usual attrset shape) on top
   of whatever the greeter would inherit.
3. NixOS isn't FHS — `/usr/share/icons` doesn't exist, so Xcursor's default
   search path finds nothing. `XCURSOR_PATH` is set explicitly to
   `${cursorPackage}/share/icons`. That package also needs to be in
   `environment.systemPackages` — SDDM runs before any user session exists.

*Caveat*: QEMU's `screendump` doesn't reliably capture hardware cursor
planes, so a screenshot not showing a cursor isn't proof it's still broken
on real output.

**Apps** (`vayori.apps`): pick from file names under `modules/apps/` — the
one setting most new machines actually need to change.

**Users** (`vayori.users`): one entry per real account — see
[core/users.nix](#modulescoreusersnix) for field meanings. Generate a
password hash with `mkpasswd -m sha-512`.

## `modules/hosts/<name>/_hardware.nix`

Unlike everything else under `modules/`, this is a **plain NixOS module** —
no `flake.nixosModules.X` wrapper. The leading `_` makes import-tree skip
it, so it's only reachable via `host.nix`'s `./_hardware.nix` import (a raw
NixOS module's top-level keys like `boot`/`fileSystems` aren't valid
flake-parts options on their own).

To generate one for a different machine:

```bash
sudo nixos-generate-config --show-hardware-config > modules/hosts/<name>/_hardware.nix
```

Then drop the Nvidia/Optimus block entirely unless you also have an Nvidia
Optimus laptop — `intelBusId`/`nvidiaBusId` are this machine's PCI
addresses (`lspci` for yours).

**Nvidia block:**
- `powerManagement.enable`/`finegrained` — lets the dGPU fully power down
  via PRIME offload when idle, instead of draining battery while unused.
- `open = false` — the RTX 3050 (Ampere) supports the open kernel module,
  but closed is the safer default.
- `prime.offload` — iGPU drives the display; dGPU spins up only for apps
  launched via `nvidia-offload <cmd>`. For "dGPU renders everything,
  always on" instead, use `prime.sync.enable = true` and drop the
  `powerManagement` lines.

**`services.asusd` and `services.supergfxd` are separate daemons**, despite
both living under `nixos/modules/services/hardware/`. `asusd` (`asusctl`)
handles keyboard LEDs/fan curves/battery limits — **it does not touch GPU
switching**. GPU mux switching (Integrated/Hybrid/dGPU) is `supergfxctl`,
gated behind its own `services.supergfxd.enable`. Enabling only `asusd`
leaves `supergfxd` never running, so nothing ever mux-switches back to
Hybrid — the dGPU can stay powered off indefinitely, indistinguishable from
a real driver failure.

- `services.supergfxd.settings.mode = "Hybrid"` makes the mode declarative
  (confirmed against `supergfxctl`'s own source — `/etc/supergfxd.conf`,
  `mode` matching the `GfxMode` enum exactly) instead of a one-time
  `supergfxctl -m Hybrid && reboot` you'd have to remember on every install.
- `systemd.services.supergfxd.path = [ pkgs.pciutils ]` works around
  [nixpkgs#239059](https://github.com/NixOS/nixpkgs/issues/239059) — without
  it, `supergfxd` can't find the dGPU at all.
- **`services.power-profiles-daemon` is deliberately not enabled** once
  `asusd` is — `asusd` implements the same
  `org.freedesktop.UPower.PowerProfiles` D-Bus name itself, so running both
  is a straight name collision: whichever starts second silently loses
  profile switching.

**`virtualisation.vmVariant`** — two independent fixes for
`nixos-rebuild build-vm`:

1. QEMU has no Nvidia GPU, so the real Nvidia driver stack (gated via
   `services.xserver.videoDrivers`) leaves niri with no working DRM device.
   Clearing `videoDrivers` for the VM build falls back to `modesetting`,
   which QEMU's virtual GPU supports natively. `asusd`/`supergfxd` are
   disabled the same way — no ASUS hardware in a VM either.
2. Clearing the Nvidia stack still left the VM black after "Reached target
   Graphical Interface." Root cause: QEMU's `bochs-drm` has no real DRI2
   driver, so the greeter's QML frontend (a Wayland *client*, unlike
   Weston's own server-side renderer) can't get a hardware EGL context —
   Mesa's `zink` fallback then also fails (no Vulkan ICD). Fix:
   `QT_QUICK_BACKEND=software` in the VM's `GreeterEnvironment`, forcing
   the greeter to skip EGL/GL entirely. VM-only — real hardware has a
   working Intel iGPU and shouldn't pay the software-rendering cost.

## `modules/core/users.nix`

Shared framework — what a `vayori.users.<name>` entry can contain and how
it becomes an account. Add a *person* inline in a host's `host.nix`; only
touch this file to change what fields a user entry supports.

- `hashedPassword`: generate with `mkpasswd -m sha-512`. `null` falls back
  to `initialPassword = "changeme"`.
- `extraGroups`: `"wheel"` for sudo, `"adbusers"` for Android debugging
  (see [android-studio.nix](#modulesappsandroid-studioandroid-studionix)).
- `availableApps` auto-discovers from `modules/apps/*/*.nix` — add an app
  by dropping a folder there, nothing here changes.
- Every user's `home-manager-<name>.service` gets
  `after`/`wants = [ "network-online.target" ]` here, generically — any
  app's activation script that touches the network (currently
  [zen-browser.nix](#modulesappszen-browserzen-browsernix)'s mods/profile
  fetch) would otherwise race the NIC coming up during boot.

---

## `modules/desktop/dms.nix`

**Applied to every user**, not hardcoded to one —
`home-manager.users = lib.genAttrs (builtins.attrNames config.vayori.users) (name: { ... })`.
Hardcoding it was an earlier bug: a second account got a niri session with
no shell running in it.

**`settings = { ... }` is the only valid key.** An older
`default.settings = { ... }` shape is a silent no-op if you use it by
mistake.

**Wallpaper default**: `xdg.stateFile."DankMaterialShell/session.json"`
seeds `wallpaperPath`/`wallpaperCyclingFolderPath` from
`modules/wallpapers`. Force-written like `settings.json`, so DMS can still
switch wallpapers live between rebuilds, but resets to this default on the
next `nixos-rebuild switch`.

**Section map** (settings block order): theme, compositor, weather,
animation, blur, wallpaper, bar/general widgets, control center,
workspaces, media, greeter, launcher, dashboard, fonts, notepad, sounds,
power, matugen (per-app template toggles — themes niri's window borders
too), dock, notifications, lock screen, OSD, power menu, updater, displays,
desktop clock, system monitor, desktop widgets, frame.

**Third-party plugins**: `inputs.dms-plugin-registry.nixosModules.default`
auto-generates a `programs.dank-material-shell.plugins.<id>` option for
every plugin in
[AvengeMedia/dms-plugin-registry](https://github.com/AvengeMedia/dms-plugin-registry)
(`mkDefault false` — opt in per plugin). `<id>` is the plugin's own
`plugin.json` id, not the registry's filename slug. A `"type": "widget"`
plugin still needs adding to a bar section (`leftWidgets`/`centerWidgets`/
`rightWidgets`) with that same id to actually show up.

- **`dankAsusControlCenter`**: a DankBar popout for `asusctl`
  (Quiet/Balanced/Performance profiles, battery charge limit/One Shot) and
  `supergfxctl` (GPU mode) —
  [shazzaam7/DankAsusControl](https://github.com/shazzaam7/DankAsusControl).
  Its dependencies (`asusctl`, `supergfxctl`, `upower`) are already
  satisfied by [\_hardware.nix](#moduleshostsname_hardwarenix)/`host.nix`.
  Switching GPU mode needs a session logout — the widget detects niri and
  handles this itself. Not verified against real ASUS hardware (no
  physical device to test in this sandbox) — if the popout can't reach the
  daemons, check `supergfxctl -g`/`asusctl -v` work from a terminal first.
- **System monitors** (`cpuMonitor`, `ramMonitor`, `gpuMonitor`,
  `vramMonitor`, `diskMonitor`, `ioMonitor`, `intelGpuMonitor`) — only
  `gpuMonitor`/`vramMonitor`/`intelGpuMonitor` are actually placed in
  `rightWidgets`. `cpuMonitor`/`ramMonitor` are deliberately enabled but
  *not* added to the bar — DMS's own built-in `"cpuUsage"`/`"memUsage"`
  string widgets are already in `rightWidgets`, so adding the plugin
  versions too would just show the same CPU/RAM numbers twice.
  `diskMonitor`/`ioMonitor` are also enabled-but-unplaced, on purpose -
  genuinely useful, but seven new bar icons at once risked real clutter
  with no way to visually check the result from this sandbox (no display
  to actually look at). Both are one drag-and-drop away in DMS's own
  Settings UI once you can see how the bar actually looks.
- **`dankQuickSearch`**: enabled, deliberately *not* placed in any bar
  section — its own description is "web search from the launcher with
  engine prefixes," meaning it likely integrates into the existing
  Mod+A/Mod+S spotlight launcher directly rather than needing its own bar
  icon (unlike the monitor plugins, whose descriptions explicitly say "in
  your DankBar"). Add it to a widget list too if it turns out to want its
  own entry.

## `modules/desktop/niri.nix`

**`extraSettings` must be a sibling of `settings`**, not nested inside it —
nesting it serializes as a literal invalid KDL node instead of using the
wrapper's real mechanism.

**The `include "dms/colors.kdl"` gotcha**: DMS (via `matugenTemplateNiri`)
renders `~/.config/niri/dms/colors.kdl` on every theme change, included
with `optional = true` so niri still starts before DMS runs once. Problem:
niri rejects two static top-level `layout { }` nodes, but an *included*
one *merges* into the already-parsed one — so DMS's include silently
overwrote this repo's translucent `layout.border` colors with matugen's
opaque ones. Fix: a *second* include, after DMS's, pointing at a small
`pkgs.writeText` KDL file that re-asserts just `layout.border` — includes
merge, so the second one wins for that one field while everything else
stays dynamically themed. (Pass that derivation to `include` with
`"${...}"` interpolation, not bare — `wlib.toKdl` stack-overflows recursing
into a bare derivation attrset.)

**`blur.passes = 2`**, not niri's default of 3 — each pass roughly doubles
render cost, and it runs on the Intel iGPU (niri isn't PRIME-offloaded
here). Near-identical visually, cheaper to run.

**`spawn` vs `spawn-sh`**: `spawn` execs directly; `spawn-sh` forks
`sh -c` first. Most binds use `spawn`; the brightness binds use `spawn-sh`
since they pipe `dms ipc call brightness list` through `awk`.

`binds` is a named `niriBinds` in a `let`, not inlined into `settings` —
same reasoning as `gaming.nix`'s named bindings: a ~90-line keymap reads
easier as its own thing than buried three levels into the `packages.myNiri`
attrset. Purely cosmetic — the built `myNiri` derivation hash is unchanged
by this, confirmed by rebuilding before/after.

## `modules/desktop/fonts.nix` / `portals.nix`

- `nerd-fonts.jetbrains-mono`: kitty + bar monospace glyphs.
- `material-symbols`: DMS's icon font.
- `xdg-desktop-portal-gnome`: file pickers/screenshots/screencast for niri.
- `xdg-desktop-portal-gtk`: GTK file chooser for Nautilus & co.

**`vayori.theme.font` drives every declarative font setting**:
`fontconfig.defaultFonts.sansSerif`, GTK app UI text (`gtk.font`), kitty,
and DMS's own UI (`fontFamily`/`monoFontFamily`). Not covered: the SDDM
greeter's clock/labels use a bundled `Itim-Regular.ttf` shipped inside the
"women-umbrella" theme itself
([desktop/sddm/Theme/font/](../modules/desktop/sddm/Theme/font/)) —
changing that means shipping a different `.ttf`, not a settings tweak. Qt
apps also aren't covered — their font comes from qt6ct's own config, which
DMS's `matugenTemplateQt6ct`/`matugenTemplateQt5ct` already manages.

## `modules/desktop/baseline.nix`

Imported for every user regardless of `vayori.apps` — GTK/Qt theming is
the one piece of the rice nobody opts out of. Lives under `desktop/`, not
`apps/`, for exactly that reason: it isn't an opt-in app pick, it's part
of what makes this desktop this desktop.

- **`gtk.theme` (adw-gtk3) was missing entirely** — `iconTheme`/
  `cursorTheme`/`font` were always set, but no `gtk.theme.name`/`package`
  at all, so GTK3 apps had no explicit base theme and fell back to
  whatever GTK's own compiled-in default is. This is the actual reason
  matugen's dynamic wallpaper recoloring didn't visibly do anything on
  GTK apps: DMS's own `apply_gtk3_colors` (traced through its `gtk.sh`,
  bundled in the DMS source) always symlinks `gtk.css -> dank-colors.css`
  regardless of what theme is active, but those color values are
  `@define-color` overrides meant to be *consumed* by a libadwaita-aware
  theme's stylesheet - with no such theme active, the overrides had
  nothing to attach to. `adw-gtk3` is exactly that theme (the standard
  GTK3-compatibility companion for libadwaita/GNOME-style apps).
- **`home.file.".local/share/themes/adw-gtk3"`** closes a second, more
  specific gap in the same script: `link_gtk3_assets` (also in `gtk.sh`)
  only searches four hardcoded paths for the theme's checkbox/radio/
  slider glyph assets - `~/.local/share/themes/adw-gtk3/...`,
  `~/.themes/adw-gtk3/...`, and two `/usr/share`-rooted ones that don't
  exist on NixOS at all. `gtk.theme.package` alone makes the theme
  reachable via `XDG_DATA_DIRS` (fine for GTK's own theme *loading*),
  but that's not one of the four paths this specific script checks - so
  without this extra symlink, checkboxes/radios/sliders still render as
  solid blocks even with the theme name correctly set. Confirmed by
  reading `gtk.sh`'s own comment: *"without them checked boxes render as
  solid blocks."*
- **`gtk.gtk4.theme = null`**: silences a home-manager deprecation
  warning (`home.stateVersion` < `26.05` means the legacy default,
  `config.gtk.theme`, is used unless set explicitly) by adopting the new
  default directly, since it's also the semantically correct one here -
  `adw-gtk3` is a GTK3-only compatibility theme; applying it as a "GTK4
  theme" doesn't mean anything, GTK4/libadwaita apps get their look from
  the app itself plus matugen's `@import`ed `dank-colors.css`, not a
  named theme switch.
- **`xdg.userDirs`**: creates and populates `~/.config/user-dirs.dirs`
  with the standard XDG folders (Desktop/Documents/Downloads/Music/
  Pictures/Public/Templates/Videos) - this is what makes them show up as
  fixed sidebar bookmarks in Nautilus (and any other GTK file picker/file
  manager) automatically; without it, those entries just don't exist
  anywhere for a fresh user. `setSessionVariables = true` keeps the
  legacy behavior of also exporting `XDG_DOWNLOAD_DIR` etc. as real
  session env vars (some apps read these directly rather than parsing
  the file themselves) - explicit for the same reason as `gtk4.theme`,
  silencing the same class of stateVersion-driven default-change warning.

---

## `modules/system/dev-tooling.nix`

Named for what it actually is — system-level enablement for development
workflows, not tied to any one app. Renamed from `dev-system.nix` during
the project restructure specifically to stop reading as a near-duplicate
of [apps/dev-tools/dev-tools.nix](#modulesappsdev-toolsdev-toolsnix) (a
completely different, per-user file — VS Code/git/gh/lazygit/
docker-compose). `virtualisation.docker.enable`/`libvirtd.enable` are
the actual system daemons `dev-tools`' `docker-compose` and any VM
tooling need. `programs.adb.enable` was removed upstream — systemd 258+
handles the adb uaccess udev rules automatically, and
`pkgs.android-tools` (already in
[android-studio.nix](#modulesappsandroid-studioandroid-studionix)) covers
the `adb` command itself — `users.groups.adbusers` stays declared here
purely as a valid `extraGroups` entry, it no longer grants anything on
its own.

## `modules/system/grub-theme.nix`

`grub-theme` is a plain repo meant to be installed via its own shell
script, not a Nix package. This module fetches its source via the flake
input and points `boot.loader.grub.theme` straight at the theme directory
(what that option actually expects — a directory containing `theme.txt`).

Double-check the subfolder name (`SekiroShadow` currently) after your
first rebuild — if GRUB doesn't pick it up, `ls ${inputs.grub-theme}` in
`nix repl` and adjust the path.

---

## `modules/apps/zen-browser/zen-browser.nix`

**The profile is always `~/.zen/default`** — a fixed, predictable path
this repo owns, rather than discovering/importing whatever a previous
Arch/Flatpak install happened to name. If it doesn't exist yet, the
activation script creates it (see the bootstrap note below); if it does,
it's reused and re-synced on every `home-manager switch`.

- `zenPrefs`: check these out at `about:config`.
- **`zenUserPrefs`/`zenUserJs`**: look-and-feel state (compact mode,
  floating urlbar, hidden sidebar, and every installed mod's tuned
  values) extracted from a real profile's `prefs.js`. Written to a
  declarative `user.js` rather than locked via `zenPrefs` — these are
  values you'd reasonably keep tweaking through Zen's own Settings UI, and
  `lockPref` would freeze them forever. Trade-off: `user.js` re-applies on
  every launch, so a live UI tweak resets on next restart, not just next
  rebuild. Left out on purpose: Firefox Sync state (account-tied),
  `network.proxy.*` (inactive anyway, and the source profile's real IP
  shouldn't be copied), `browser.backup.location` (hardcodes a path from
  the source machine).
- **Adding an extension** (`zenExtensions`): find `slug` in the addon's
  `addons.mozilla.org` URL; look up `guid` at
  `https://addons.mozilla.org/api/v5/addons/addon/!SLUG!/` (or the search
  endpoint if you don't have the exact slug — some names have multiple
  listings from different authors, so match on `average_daily_users`).
  Both fields matter and neither substitutes for the other: `slug` is the
  renameable download-URL name; `guid` is the extension's real manifest
  id, which is what `ExtensionSettings` policy keys on. This can't be
  resolved automatically like `zenMods` — extension policy bakes into
  `policies.json` **inside the immutable package** at eval/build time,
  and flakes evaluate without network access on purpose.
- **Dynamic theming**: Zen has no Pywalfox/theme-extension support —
  theming is `userChrome.css`. DMS renders
  `~/.config/DankMaterialShell/zen.css` from the wallpaper palette
  (`matugenTemplateZenBrowser`); the activation script symlinks it into
  the profile. `toolkit.legacyUserProfileCustomizations.stylesheets` is
  locked via `zenPrefs` so no manual `about:config` step is needed.
- **Profile bootstrap**: if `~/.zen/default` doesn't exist, the activation
  script runs `zen -CreateProfile "default $HOME/.zen/default"`. That
  command still goes through GTK init even though it opens no window, so
  it fails with "no DISPLAY" when run headless from a systemd activation
  service — wrapped in `pkgs.xvfb-run` (a throwaway virtual X server)
  specifically for this.
- **Zen Mods** (`zenMods`, in the same activation script — theming,
  `user.js`, and mods all need the same resolved `$PROFILE_DIR`) — traced
  through Zen's actual source (`ZenMods.mjs`) rather than guessed:
  - `<profile>/zen-themes.json` is a JSON *object* keyed by mod id, each
    value the mod's metadata plus `enabled`.
  - `zenMods` here is just a `name -> id` map — unlike `zenExtensions`,
    this *can* be resolved live:
    [zen-browser/theme-store](https://github.com/zen-browser/theme-store)
    publishes a `themes.json` index with every mod's full metadata. The
    activation script fetches it, `jq`-filters to the ids in `zenMods`,
    stamps `enabled: true`, and writes the result straight out — no
    metadata is hand-copied, so it can't drift. This only works here
    because activation runs in the user's mutable `$HOME`, which is
    allowed to touch the network.
  - Each mod's `chrome.css`/`preferences.json` is fetched separately into
    `<profile>/chrome/zen-themes/<id>/`, only if missing (self-heals if a
    file goes missing, doesn't re-fetch every rebuild).
  - **One broken mod takes down every mod** — Zen's `#writeStylesheet`
    loops over enabled mods with no per-mod try/catch, so one missing
    `chrome.css` throws and *no* mod's CSS applies that session. One
    upstream entry ("Remove Browser Padding") is missing from
    `theme-store`'s index entirely, so it's simply absent from `zenMods` —
    fetching the live index naturally omits it. Add it back if/when
    upstream restores it.
  - **Every `curl` call is `${pkgs.curl}/bin/curl`, never bare `curl`** —
    an interactive shell's `PATH` has `curl`, but the
    `home-manager-<user>.service` systemd unit that runs activation
    scripts has a much narrower one. A bare `curl` there fails silently
    ("command not found," swallowed by the same error-tolerance that lets
    a network-less machine still apply the rest of the config) — found by
    actually booting a fresh VM and checking, not assumed.

## `modules/apps/spicetify/spicetify.nix`

**Custom font**: Spotify's client CSS reads its UI font from the
`--font-family` custom property, not generic `font-family: sans-serif` —
`theme.additionalCss` sets it to `vayoriTheme.font` explicitly.
`theme.extraPkgs = [ vayoriTheme.fontPackage ]` makes that font an
explicit dependency of the spiced Spotify derivation. `spicePkgs.themes.hazy
// { ... }` merges onto the theme's existing options — `theme` accepts a
freeform attrset, so this is safe.

## `modules/apps/gaming/gaming.nix`

One file, one `vayori.apps` toggle, for everything Windows-gaming related —
`lutris` + `heroic` as the two launchers, plus shared tooling. No Steam —
`proton-ge-bin` in nixpkgs refuses to install outside
`programs.steam.extraCompatPackages`; `umu-launcher` is the Steam-free
substitute (Lutris's native "Proton" runner, manages GE-Proton itself).

- **One games folder, one shared prefix**: `home.file` creates `~/Games`;
  `WINEPREFIX = ~/Games/.wineprefix`. Covers *plain* `wine`/`winetricks`
  invocations only — **Lutris/Heroic manage their own per-game prefixes
  independently of `$WINEPREFIX`**. To point a specific Lutris game at the
  shared prefix instead, set that same path in that game's Configure →
  Wine prefix field — a per-game UI choice, not something Nix enforces.
- **`gamescope-fhd`/`gamescope-fsr`**: two `writeShellScriptBin` wrappers
  (flags confirmed against `gamescope --help`). `gamescope-fhd`: borderless
  1920×1080, adaptive sync, no upscaling — for games fighting niri over
  fullscreen. `gamescope-fsr`: renders at 1600×900, FSR-upscales to
  1920×1080 — real performance headroom on the RTX 3050 for demanding
  titles, at some image softness. Both are Lutris/Heroic launch-option
  prefixes.
- **MangoHud**: restyled from defaults for readability — `horizontal` +
  `hud_compact` (one compact row), `legacy_layout = false`, rounded
  corners + translucent background, a coherent accent palette per stat.
  Same stats shown (fps/frametime/cpu+gpu load+temp/ram/vram), not
  session-wide (`enableSessionWide` would overlay every Vulkan/OpenGL app,
  not just games) — toggle per game with `MANGOHUD=1 %command%`, or
  `Shift+F12` once running. **Exception**: alongside a `gamescope-*`
  wrapper, use gamescope's own `--mangoapp` flag instead —
  `gamescope --help` explicitly says not to combine `MANGOHUD=1` with it.
- **NVIDIA shader cache**: `__GL_SHADER_DISK_CACHE_PATH` points at
  `~/Games/.cache/nv-shaders` (confirmed against NVIDIA's own driver
  README) — keeps shader cache growth inside the one games folder instead
  of scattered into `~/.cache`.
- **Lutris default runner**: `~/.config/lutris/runners/wine.yml` seeds
  `wine: { version: ge-proton }` — `ge-proton` is the literal sentinel
  string (confirmed in Lutris's own source, `GE_PROTON_LATEST`) that
  routes a new game through `umu-launcher`'s managed GE-Proton instead of
  Lutris's bundled Wine-GE build. `dxvk`/`vkd3d`/`esync`/`fsync`/
  `battleye`/`eac` are deliberately *not* set — checked Lutris's option
  schema, all already default to `true`. `force = true`, same trade-off as
  DMS `settings.json`: a manual change through Lutris's own Preferences UI
  resets on the next rebuild.
- **`~/Games` in the file picker sidebar**: `home.activation.gamesBookmark`
  appends it to `~/.config/gtk-3.0/bookmarks` (read by GTK3 and GTK4 file
  pickers/Nautilus) if not already present. Appends, not
  declarative-replaces — that file accumulates whatever else you drag into
  the sidebar, and shouldn't be owned/reset wholesale for one entry.
- **`programs.gamemode.enable = true`** lives in `host.nix`, not here —
  it's a system-wide daemon (systemd *user* service + polkit +
  `cap_sys_nice` wrapper), not a per-user concern. Any launcher running
  games through `gamemoderun` (Lutris does, automatically) picks it up for
  free; use it explicitly as a prefix to combine with the rest, e.g.
  `gamemoderun gamescope-fsr --mangoapp -- %command%`.
- **GPU offload (Optimus laptop only)**: none of the above make a game use
  the dGPU — it runs on the weaker iGPU by default. `nvidia-offload` (from
  `hardware.nvidia.prime.offload.enableOffloadCmd`, see
  [\_hardware.nix](#moduleshostsname_hardwarenix)) is NixOS's own
  ready-made wrapper for this — no separate script needed here. Use as a
  launch-option prefix, e.g. `nvidia-offload gamemoderun -- %command%`. The
  `dankAsusControlCenter` DMS widget's "GPU Mode" switch does the same
  thing at the whole-laptop level instead of per-launch.

## `modules/apps/nautilus/nautilus.nix`

- `thumbnail-limit = 200`: thumbnail bigger files instead of a generic
  icon.
- `mouse-use-extra-buttons`: back/forward mouse buttons navigate history.
- `open-folder-on-dnd-hover`: auto-enter a hovered folder mid drag-and-drop.
- `window-state.maximized`: open maximized instead of the cramped 890×550
  default.
- `media-handling`: drives/USB/SD auto-mount, pop open a window, never
  auto-run scripts.
- `nautilus-open-any-terminal` defaults to gnome-terminal (not installed
  here) — pointed at kitty instead.
- gvfs + tumbler are enabled system-wide in `host.nix` — they're daemons,
  not per-user.

## `modules/apps/android-studio/android-studio.nix`

`adb` device access works out of the box (systemd 258+ handles uaccess
udev rules automatically) — `"adbusers"` in `extraGroups` is optional
compatibility, not required.

Plugins and editor settings are captured as they exist on the real
machine, pinned as Nix derivations rather than fetched live at
activation time:

- **17 real user-installed JetBrains plugins**, each fetched via
  `pkgs.fetchurl` from `plugins.jetbrains.com/plugin/download?pluginId=<id>&version=<version>`
  with a pinned content hash (`nix store prefetch-file`). Plugin ids and
  versions came straight from each installed plugin's own
  `META-INF/plugin.xml`; the marketplace download endpoint accepts the
  plugin's own XML id string directly, no numeric marketplace id needed.
  Bundled/built-in components (e.g. `marketplace`, `vcs-hg`) were
  excluded by cross-referencing the real install's own
  `bundled_plugins.txt`.
- **`pkgs.jetbrains.plugins.addPlugins` does not work here** — it assumes
  a plain (non-FHS) IDE layout with `plugins/` nested under
  `$out/<mainProgram>/`. `pkgs.androidStudioPackages.stable` is an
  FHS-wrapped launcher script derivation — the real IDE lives in a
  separate `unwrapped` derivation reached only via runtime closure, so
  that `plugins/` path never exists inside the wrapper's own `$out` and
  `addPlugins`' build step fails outright. Confirmed by a real failed
  build, not assumed.
- Instead, each plugin is placed with `home.file` directly into
  `~/.local/share/Google/<dataDirectoryName>/<real-plugin-dir-name>` —
  the same *user* plugins directory the IDE itself reads at startup when
  you install a plugin through Settings → Plugins, entirely separate
  from the read-only IDE installation. This sidesteps the FHS-wrapping
  problem completely and needed zero changes to the stock
  `androidStudioPackages.stable` package. Verified against the real
  machine's own `~/.local/share/Google/AndroidStudio2026.1.2/` — every
  directory/jar name here (`Catppuccin Theme`, `flutter-intellij`,
  `WakaTime.jar`, etc.) matches exactly.
- `<dataDirectoryName>` (`AndroidStudio2026.1.3`) is read out of the
  nixpkgs-built package's own `product-info.json`, not guessed from the
  package version string — the real machine's installed build
  (`2026.1.2`) and the pinned nixpkgs build (`2026.1.3.7`) don't share a
  version, and `product-info.json` is the only ground truth for which
  config directory an IDE build actually reads.
- The 5 XML files under `.config/Google/<dataDirectoryName>/options/`
  (font, LAF, color scheme, One Dark config, Vim emulation) are a
  straight transcription of the real machine's own files at that path.

## `modules/apps/vscode/vscode.nix`

`programs.vscode.profiles.default` (`userSettings`, `keybindings`,
`extensions`), the current home-manager schema — not the older flat
`programs.vscode.userSettings` shape. Settings, the one custom
keybinding (`ctrl+y` unbound from `editor.action.deleteLines`), and all
47 extensions are a direct transcription of the real
`~/.config/Code/User/` on this machine, not a live importer:

- `nixpkgsExtensions`: extensions available pre-packaged in
  `pkgs.vscode-extensions`.
- `marketplaceExtensions`: the remaining extensions not in nixpkgs,
  built via `pkgs.vscode-utils.extensionsFromVscodeMarketplace`, each
  pinned to the installed `{ name, publisher, version, hash }` with a
  content hash from `nix store prefetch-file` against the Marketplace's
  VSIX asset URL.

VSCode itself moved out of `dev-tools.nix` into its own module once it
needed this much dedicated configuration — `dev-tools.nix` keeps only
`gh`, `lazygit`, `docker-compose`.

## `modules/apps/dev-tools/dev-tools.nix`

`git` isn't listed here — it's already in `environment.systemPackages`
(`host.nix`), since flakes need it system-wide regardless of which apps
are picked.

## `modules/apps/bitwarden/bitwarden.nix`

Just `pkgs.bitwarden-desktop` — the nixpkgs attribute name is
`bitwarden-desktop`, not `bitwarden` (that alias throws a
renamed-package error). Added so a fresh install has a working password
manager without a manual first-run setup step; vault contents still
require signing in once, syncing pulls everything else back down.

## `modules/apps/terminal/terminal.nix`

Kitty + zsh (oh-my-zsh) + fastfetch + Starship + eza, one selectable app.
`initContent` picks a random logo from `modules/apps/terminal/images/`
per shell (falls back to fastfetch's default if the directory is empty).
The zsh plugin list and fastfetch's `modules` array are named `let`
bindings (`zshPlugins`, `fastfetchModules`) rather than inlined — same
reasoning as `niri.nix`'s `niriBinds`, purely readability, verified
identical output by rebuilding before/after.

- **Prompt is Starship, not a hand-rolled `precmd`**: the previous prompt
  was a manual `autoload -Uz vcs_info` + `precmd()` function that only
  ever showed the branch name, no dirty/staged/ahead-behind state.
  `programs.starship.enableZshIntegration = true` fully owns prompt
  rendering once enabled (injects its own `precmd` hook via `starship
  init zsh`), so the old block was removed outright rather than left
  alongside it - two things fighting over `$PROMPT` isn't a real
  option. `git_status`'s `format = "[$all_status$ahead_behind]($style) "`
  is what actually adds the dirty/staged/stash/ahead-behind info the old
  prompt never had.
- **`eza`** replaces `ls` (`enableZshIntegration` wires the aliases -
  `ls`/`la`/`ll`/`lla`/`lt` - automatically, confirmed in the built
  `.zshrc`), not added as a separate command alongside it - the goal was
  a better `ls`, not a second tool to remember.
