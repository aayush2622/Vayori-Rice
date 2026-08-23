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
> Disk UUIDs, GPU bus IDs, and account details in `modules/hosts/Diablo/`
> and `modules/users/` are specific to the original author's laptop.
> Deploying it unmodified **will not boot** on different hardware. You can
> absolutely use this as a base - read
> [Using this on your own machine](#using-this-on-your-own-machine) first.

## Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start-on-the-reference-machines-exact-hardware)
- [Using this on your own machine](#using-this-on-your-own-machine)
- [Layout](#layout)
- [Extending it](#extending-it)
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
- Opt-in apps per machine: Nautilus, Zen Browser (locked-down,
  privacy-leaning profile), Vesktop, Spicetify, a dev-tools bundle
  (VS Code, git, gh, lazygit, docker-compose), Android Studio scaffolding.

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

Everything below lives in `modules/hosts/Diablo/` and `modules/users/`.
Nothing in `modules/features/` or `modules/apps/` needs to change to move
this to different hardware.

1. **Rename the host** *(optional but recommended)* - copy
   `modules/hosts/Diablo/` to `modules/hosts/<yourhostname>/`, and update
   `networking.hostName` in its `configuration.nix`.

2. **Replace `hardware.nix`** with your own. Boot the live ISO (or your
   existing NixOS install) and run:

   ```bash
   sudo nixos-generate-config --show-hardware-config > modules/hosts/<yourhostname>/hardware.nix
   ```

   Then re-add the `flake.nixosModules.<Name>Hardware = { ... }: { ... };`
   wrapper around it (see the existing file for the shape), and **drop the
   Nvidia/Optimus-specific block entirely** unless you also have an Nvidia
   Optimus laptop - `intelBusId`/`nvidiaBusId` are PCI addresses specific
   to that one machine (`lspci` to find yours if you do need it).

3. **Add yourself as a user** - copy `modules/users/random.nix` to
   `modules/users/<you>.nix`, set `vayori.users.<you>` (fullName, groups,
   shell), generate a password hash with `mkpasswd -m sha-512`, and list
   `self.nixosModules.user<You>` in your host's `default.nix` instead of
   `userAsh`/`userRandom`.

4. **Pick your apps** - edit `vayori.apps` in your host's
   `configuration.nix`; it's a plain list of names from
   `modules/apps/*.nix`.

5. **Rebuild**:

   ```bash
   sudo nixos-rebuild switch --flake .#<yourhostname>
   ```

---

## Layout

<details>
<summary>Directory map (click to expand)</summary>

```text
flake.nix                    inputs + `import-tree ./modules` (see modules/parts.nix, registry.nix)
modules/
  parts.nix                  supported `systems` for flake-parts
  registry.nix                declares the flake.homeModules option (flake-parts has no builtin one)
  hosts/<name>/
    default.nix                nixosConfigurations.<name>, lists which nixosModules this host gets
    configuration.nix          host-specific settings: vayori.apps, locale, bootloader, base packages
    hardware.nix                hardware-configuration.nix equivalent (disks, GPU, etc.) - machine-specific
  users/
    users.nix                  the vayori.users / vayori.apps option definitions - read this first
    <name>.nix                 one file per person: vayori.users.<name> = { fullName, hashedPassword, extraGroups, shell, avatar, extraPackages }
  features/                    system-wide (NixOS) modules: niri, dms, fonts, portals, grub/sddm theming, dev-system
  apps/                        opt-in per-user (home-manager) modules, picked via vayori.apps
  home/
    baseline.nix                GTK/Qt theming every user gets, regardless of vayori.apps
  Wallpapers/                  default wallpaper set (session.json is seeded to point here, see features/dms.nix)
```

</details>

## Extending it

**Add a person** to an existing host: copy `modules/users/random.nix` to
`modules/users/<name>.nix`, fill in `vayori.users.<name>`, then add
`self.nixosModules.user<Name>` to that host's `default.nix`. Apps are picked
once per *machine* (`vayori.apps` in `hosts/<host>/configuration.nix`), not
per person - everyone on a host gets the same app set.

**Add an app**: drop a file in `modules/apps/` that sets
`flake.homeModules.apps."<name>"`. It's automatically a valid entry for
`vayori.apps` - nothing else to wire up (see `modules/users/users.nix`,
`availableApps = builtins.attrNames self.homeModules.apps`).

**Add a host**: copy `modules/hosts/Diablo/` to `modules/hosts/<name>/`,
regenerate `hardware.nix` from the target machine's own
`hardware-configuration.nix`, and adjust `configuration.nix` (hostname,
`vayori.apps`, bootloader, locale). Full walkthrough:
[Using this on your own machine](#using-this-on-your-own-machine).

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

Full list in [modules/features/niri.nix](modules/features/niri.nix).

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

- `hardware.graphics.enable32Bit` is on ("needed for Steam/Proton") even
  though nothing gaming-related is installed yet - pulls in i686 Mesa/Nvidia
  libs for no current benefit. Drop it if that's not actually your plan.
- `android-studio` app currently only installs `jdk17` + `android-tools`;
  the actual `android-studio`/`flutter` packages are commented out.
- No license file yet - ask before reusing/redistributing wholesale.
