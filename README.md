# vayori

<p>
  <img alt="Built with Nix" src="https://img.shields.io/badge/built%20with-Nix-5277C3?logo=nixos&logoColor=white">
  <img alt="NixOS" src="https://img.shields.io/badge/NixOS-unstable-informational?logo=nixos&logoColor=white">
  <img alt="Compositor" src="https://img.shields.io/badge/compositor-niri-blue">
  <img alt="Shell" src="https://img.shields.io/badge/shell-DankMaterialShell-purple">
  <img alt="License" src="https://img.shields.io/badge/license-unspecified-lightgrey">
</p>

A NixOS flake config built around [niri](https://github.com/YaLTeR/niri) (a
scrolling-tile Wayland compositor) and
[DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (bar,
app launcher, lock screen, notifications, wallpaper-driven theming), with a
themed SDDM greeter and GRUB on top. Everyone gets glassy blurred windows,
rounded corners, and a desktop that recolors itself to match your wallpaper.

Structured with [flake-parts](https://flake.parts/) and
[import-tree](https://github.com/vic/import-tree): every `.nix` file under
`modules/` is auto-imported, and adding a person/app/host is just "drop a
file in the right folder" - see [Extending it](#extending-it).

> [!WARNING]
> **This is one person's real machine config, not a generic template.**
> Disk UUIDs, GPU bus IDs, and account details in
> `modules/hosts/Diablo/Host.nix` and `_hardware.nix` are specific to the
> original author's laptop. Deploying it unmodified **will not boot** on
> different hardware. You can absolutely use this as a base - read
> [Using this on your own machine](#using-this-on-your-own-machine) first.

## Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start-on-the-reference-machines-exact-hardware)
- [Using this on your own machine](#using-this-on-your-own-machine)
- [Layout](#layout)
- [Extending it](#extending-it)
- [Documentation](#documentation)
- [Keybinds](#keybinds-niri)
- [Credits](#credits)
- [Known caveats](#known-caveats)

---

## Features

- **niri**, built via
  [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)
  instead of home-manager's niri module - the whole compositor config
  (binds, layout, window rules) lives in one readable Nix attrset.
- **DankMaterialShell** for the bar, launcher (`Mod+A`/`Mod+S`), clipboard,
  notifications, lock screen, and wallpaper carousel - themed dynamically
  from your current wallpaper via matugen, including niri's own window
  borders/shadows.
- **SDDM** login theme (`women-umbrella`, hand-rolled Qt6/QML) and a
  **GRUB** theme, both cursor-matched to the desktop.
- Terminal setup: kitty + zsh (oh-my-zsh, autosuggestions, syntax
  highlighting) + fastfetch with a randomized ASCII/image logo per shell
  start.
- Opt-in apps per machine, organized under `modules/apps/` into
  `development/`, `gaming/`, and `utils/`: Nautilus, Zen Browser
  (locked-down, privacy-leaning profile), Spicetify (custom font via CSS
  injection), Bitwarden, a dev-tools bundle (git, gh, lazygit,
  docker-compose), three editors (VS Code, Android Studio, Zed - Zed
  gets its own matugen-driven theme too, hand-authored against Zed's
  published theme schema), and Vesktop - all with the real
  settings/plugins/extensions from the reference machine pinned as Nix
  derivations, not a live importer - and a full gaming setup (Steam,
  Lutris + Heroic, GE-Proton via umu-launcher, gamescope presets,
  restyled MangoHud - Steam, Heroic, Vesktop, and even Wine's own
  dialogs pick up the current matugen palette too).
- Per-language dev setup under `modules/apps/development/languages/`
  (C/C++, Rust, Kotlin, Dart+Flutter, Nix, Qt, Python): each toggle installs
  that language's own LSP/toolchain and, in the same step, gates which
  of VS Code's, Android Studio's, and Zed's language-specific
  extensions/plugins actually get installed - drop a language from
  `vayori.apps` and its extensions disappear from every editor with it,
  no per-editor cleanup needed. See
  [docs/CONFIGURATION.md](docs/CONFIGURATION.md#modulescoredevlanguagesnix).
- [Free Claude Code](https://github.com/Alishahryar1/free-claude-code)
  runs as a background service, routing Claude Code's CLI, its VS Code
  extension, and Android Studio's JetBrains ACP integration through
  free-tier model providers (NVIDIA NIM by default) instead of
  Anthropic's paid API - needs a one-time free API key, see
  [docs/CONFIGURATION.md](docs/CONFIGURATION.md#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix).
- ASUS ROG-specific: a DankBar widget
  ([DankAsusControl](https://github.com/shazzaam7/DankAsusControl)) for
  switching power profiles and GPU mode (Integrated/Hybrid/Dedicated)
  without leaving the desktop.

## Prerequisites

- A NixOS install (or a NixOS live ISO to install fresh) with flakes
  available - either already enabled, or pass
  `--extra-experimental-features 'nix-command flakes'` to the commands
  below.
- UEFI boot (the GRUB config here assumes `efiSupport = true`).

---

## Quick start (on the reference machine's exact hardware)

```bash
git clone https://github.com/aayush2622/Vayori-Dotfiles.git vayori
cd vayori
sudo nixos-rebuild switch --flake .#Diablo
```

> [!NOTE]
> First login password for any user without a `hashedPassword` set is
> `changeme` - run `passwd` after logging in.

---

## Using this on your own machine

A host is exactly **two files**, both under `modules/hosts/<name>/`:
`Host.nix` (hostname, users, apps, timezone, bootloader, packages - all of
it) and `_hardware.nix` (disks, GPU - the `hardware-configuration.nix`
equivalent). Nothing in `modules/desktop/`, `modules/system/`, or
`modules/apps/` needs to change to move this to different hardware.

> [!TIP]
> `_hardware.nix` starts with an underscore on purpose - `import-tree`
> (which auto-imports every other `.nix` file under `modules/`) skips any
> path containing `/_`, so this one plain NixOS module doesn't get treated
> as its own flake-parts module. Keep the underscore if you rename it.

1. **Copy and rename the host directory**:

   ```bash
   cp -r modules/hosts/Diablo modules/hosts/<yourhostname>
   ```

2. **Replace `_hardware.nix`** with your own. Boot the live ISO (or your
   existing NixOS install) and run:

   ```bash
   sudo nixos-generate-config --show-hardware-config > modules/hosts/<yourhostname>/_hardware.nix
   ```

   **Drop the Nvidia/Optimus-specific block entirely** unless you also have
   an Nvidia Optimus laptop - `intelBusId`/`nvidiaBusId` are PCI addresses
   specific to that one machine (`lspci` to find yours if you do need it).

3. **Edit `Host.nix`**:
   - Change `Diablo` (the `flake.nixosConfigurations.Diablo` line and
     `networking.hostName`) to `<yourhostname>`.
   - Replace the `vayori.users` block with your own people - each entry
     takes `fullName`/`hashedPassword`/`extraGroups`/`shell`/`avatar`/
     `extraPackages` (see `modules/core/Users.nix` for what each does;
     generate a password hash with `mkpasswd -m sha-512`).
   - Adjust `vayori.apps` - the option itself is a plain list of names
     from `modules/apps/{development,gaming,utils}/**/*.nix` (language
     toggles under `development/languages/` included). `Host.nix` writes
     it as `{ development = [...]; gaming = [...]; utils = [...]; }`
     grouped by category, then flattens that with `lib.flatten
     (lib.attrValues ...)` before assigning - purely a readability
     convenience at the call site, not a type the option itself knows
     about, so a plain flat list works exactly as well.
   - Adjust timezone/locale/bootloader/packages further down as needed.

4. **Rebuild**:

   ```bash
   sudo nixos-rebuild switch --flake .#<yourhostname>
   ```

---

## Layout

<details>
<summary>Directory map (click to expand)</summary>

```text
flake.nix                    inputs + `import-tree ./modules` (see modules/core/)
modules/
  core/                       flake-parts wiring + the shared user/app framework, not per-host config
    Parts.nix                   supported `systems` for flake-parts
    Registry.nix                 declares the flake.homeModules option (flake-parts has no builtin one)
    Users.nix                     the vayori.users / vayori.apps option definitions
  hosts/<name>/               everything for one machine - just these two files:
    Host.nix                    nixosConfigurations.<name>: users, apps, timezone, bootloader, packages
    _hardware.nix                hardware-configuration.nix equivalent (disks, GPU) - leading `_` = import-tree ignores it
  desktop/                    the DE stack: compositor, shell, login theme, fonts, portals
    Niri.nix / Dms.nix / Fonts.nix / Portals.nix / Baseline.nix (GTK/Qt theming every user gets)
    Matugen.nix                 shared matugen template content, one attr per themed app / sddm/
  system/                     system-level infra unrelated to the desktop
    DevTooling.nix (docker/libvirtd/adbusers) / GrubTheme.nix
  apps/                       opt-in per-user (home-manager) modules, picked via vayori.apps - one folder each
    development/                editors, dev-tools, FreeClaudeCode
      editors/                     Vscode, AndroidStudio, Zed - one folder each
      languages/                   one folder per language (Cpp/Rust/Kotlin/Flutter[+Dart]/Nix/Qt/Python) -
                                    installs that language's LSP/toolchain and publishes
                                    self.devLanguages.<Lang>, which editors read to decide which of
                                    their own extensions/plugins to install (see core/DevLanguages.nix)
    gaming/                      Gaming.nix (aggregator) + _launchers/_proton/_performance.nix
                                    (underscore = plain fragments, not their own flake-parts modules)
    utils/                       everything else opt-in: Terminal, Nautilus, ZenBrowser, Vesktop, ...
  assets/
    wallpapers/                 default wallpaper set (session.json seeded to point here, see desktop/Dms.nix)
```

</details>

## Extending it

**Add a person** to an existing host: add another entry to the
`vayori.users` block in that host's `Host.nix` - no separate file, nothing
else to wire up. Apps are picked once per *machine* (`vayori.apps`, same
file), not per person - everyone on a host gets the same app set.

**Add an app**: drop a folder under `modules/apps/development/`,
`modules/apps/gaming/`, or `modules/apps/utils/` (e.g.
`modules/apps/utils/foo/Foo.nix`) that sets `flake.homeModules.apps.<Name>`.
It's automatically a valid entry for `vayori.apps` - nothing else to wire
up (see `modules/core/Users.nix`,
`availableApps = builtins.attrNames self.homeModules.apps`). The category
folder is purely organizational - only the `flake.homeModules.apps.<Name>`
key matters, so it can live anywhere under `modules/apps/`.

**Add a language**: drop a folder in `modules/apps/development/languages/`
that sets `flake.homeModules.apps.<Lang>` (its packages: LSP + toolchain)
and `flake.devLanguages.<Lang>` (which extensions/plugins editors should
install for it - see `modules/core/DevLanguages.nix` for the shape editors
expect). Add `<Lang>` to `vayori.apps` and every editor picks it up.

**Add a host**: copy `modules/hosts/Diablo/` to `modules/hosts/<name>/`
and edit its two files. Full walkthrough:
[Using this on your own machine](#using-this-on-your-own-machine).

---

## Documentation

The `.nix` files themselves are kept comment-free - every "why" behind a
setting (plus a few real gotchas worth knowing before you edit one) lives
in [docs/CONFIGURATION.md](docs/CONFIGURATION.md) instead, organized to
match `modules/`. Worth reading before touching `Host.nix`, `Niri.nix`, or
`Dms.nix` in particular - each has at least one non-obvious constraint
that'll bite silently otherwise.

---

## Keybinds (niri)

<details open>
<summary>Core bindings</summary>

| Key | Action |
| --- | --- |
| `Mod+Return` | terminal (kitty) |
| `Mod+E` | file manager (nautilus) |
| `Mod+C` | code (vscode) |
| `Mod+B` | browser (zen) |
| `Mod+A` / `Mod+S` | DMS app launcher (spotlight) |
| `Mod+V` | clipboard history |
| `Mod+Comma` | settings |
| `Mod+L` | lock |
| `Mod+Tab` | overview |
| `Mod+Shift+W` | wallpaper carousel |
| `Mod+Q` / `Alt+F4` | close window |
| `Mod+F` / `Shift+F11` | fullscreen |
| `Mod+W` | toggle floating |
| `Mod+←/→/↑/↓` | focus column/window |
| `Mod+Shift+←/→/↑/↓` | move column/window |
| `Mod+1`-`0`, `Mod+Shift+1`-`0` | switch / move to workspace 1-10 |
| `Mod+Shift+P` | color picker (hyprpicker) |
| `Print` / `Shift+Print` | screenshot region / screen |
| `Control+Shift+Escape` | btop |

</details>

Full list in [modules/desktop/Niri.nix](modules/desktop/Niri.nix).

---

## Credits

Built on top of (see `flake.nix` for the full input list):

| Project | What it's for |
| --- | --- |
| [niri](https://github.com/YaLTeR/niri) | scrolling Wayland compositor |
| [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | bar, launcher, lock, theming |
| [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules) | declarative niri config wrapper |
| [home-manager](https://github.com/nix-community/home-manager) | per-user configuration |
| [flake-parts](https://flake.parts/) | modular flake structure |
| [import-tree](https://github.com/vic/import-tree) | auto-import every module file |
| [zen-browser-flake](https://github.com/youwen5/zen-browser-flake) | Zen Browser packaging |
| [spicetify-nix](https://github.com/Gerg-L/spicetify-nix) | Spotify theming |
| [Grub-Themes](https://github.com/MrVivekRajan/Grub-Themes) | GRUB theme (SekiroShadow) |

---

## Known caveats

- The `dankAsusControlCenter` DMS widget (see [Features](#features)) is
  wired up and builds cleanly, but hasn't been exercised against real
  ASUS hardware yet - see [docs/CONFIGURATION.md](docs/CONFIGURATION.md#modulesdesktopdmsnix)
  if it can't reach `asusctl`/`supergfxctl`.
- No license file yet - ask before reusing/redistributing wholesale.
