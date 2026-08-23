# vayori

Personal NixOS flake config. [niri](https://github.com/YaLTeR/niri) (scrolling
Wayland compositor) + [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
(bar/launcher/lock/wallpaper shell, dynamic matugen theming) + a themed SDDM
greeter and GRUB, wired together with
[flake-parts](https://flake.parts/) and
[import-tree](https://github.com/vic/import-tree) so every `.nix` file under
`modules/` is auto-imported - nothing to register by hand.

## Quick start

```bash
# from a NixOS live ISO or an existing NixOS install
sudo nixos-rebuild switch --flake .#Diablo
```

`Diablo` is currently the only host (see [Adding a host](#adding-a-host) to
add another). First login password for any user without a `hashedPassword`
set is `changeme` - run `passwd` after logging in.

## Layout

```
flake.nix                    inputs + `import-tree ./modules` (see modules/parts.nix, registry.nix)
modules/
  parts.nix                  supported `systems` for flake-parts
  registry.nix                declares the flake.homeModules option (flake-parts has no builtin one)
  hosts/<name>/
    default.nix                nixosConfigurations.<name>, lists which nixosModules this host gets
    configuration.nix          host-specific settings: vayori.apps, locale, bootloader, base packages
    hardware.nix                hardware-configuration.nix equivalent (disks, GPU, etc.)
  users/
    users.nix                  the vayori.users / vayori.apps option definitions - read this first
    <name>.nix                 one file per person: vayori.users.<name> = { fullName, hashedPassword, extraGroups, shell, avatar, extraPackages }
  features/                    system-wide (NixOS) modules: niri, dms, fonts, portals, grub/sddm theming, dev-system
  apps/                        opt-in per-user (home-manager) modules, picked via vayori.apps
  home/
    baseline.nix                GTK/Qt theming every user gets, regardless of vayori.apps
  Wallpapers/                  default wallpaper set (session.json is seeded to point here, see features/dms.nix)
```

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
`vayori.apps`, bootloader, locale).

## Notable pieces

- **niri** ([features/niri.nix](modules/features/niri.nix)) - built via
  [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules)
  instead of home-manager's niri module, so the whole config lives in one
  Nix attrset. Ships with per-window blur/opacity/rounded corners and an
  `include` for the color file DMS regenerates on every wallpaper change.
- **DankMaterialShell** ([features/dms.nix](modules/features/dms.nix)) -
  applied to every user in `vayori.users` (not hardcoded to one account).
  `settings.json`/`plugin_settings.json`/`session.json` are force-written
  declaratively, so DMS resets to what's in this repo on every
  `nixos-rebuild switch`; the wallpaper picker/cycler default folder is
  seeded to point at `modules/Wallpapers`.
- **SDDM theme** ("women-umbrella",
  [features/sddm/](modules/features/sddm/)) - a hand-rolled Qt6/QML greeter
  theme, cursor-themed to match the desktop (`Bibata-Modern-Ice`) instead of
  the SDDM/Weston default.
- **GRUB theme** ([features/grub-theme.nix](modules/features/grub-theme.nix))
  - pulled from the `grub-theme` flake input (SekiroShadow).

## Keybinds (niri)

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

Full list in [features/niri.nix](modules/features/niri.nix).

## Known caveats

- `hardware.graphics.enable32Bit` is on ("needed for Steam/Proton") even
  though nothing gaming-related is installed yet - pulls in i686 Mesa/Nvidia
  libs for no current benefit. Drop it if that's not actually the plan.
- `android-studio` app currently only installs `jdk17` + `android-tools`;
  the actual `android-studio`/`flutter` packages are commented out.

