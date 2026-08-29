# System reference

[← Back to index](CONFIGURATION.md)

---

## `modules/system/DevTooling.nix`

Named for what it is: system-level stuff for dev workflows, not tied to
any one app. Used to be called `dev-system.nix`, which read way too much
like [apps/devTools/DevTools.nix](apps-development.md#modulesappsdevelopmentdevtoolsdevtoolsnix)
- a completely different, per-user file (VS Code/git/gh/lazygit/
docker-compose) - so it got a better name.

`virtualisation.docker.enable`/`libvirtd.enable` are the actual daemons
that `docker-compose` and any VM tooling need running. `programs.adb.enable`
got dropped since systemd 258+ handles the adb udev rules on its own now,
and `pkgs.android-tools` (already pulled in by
[AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix))
covers the actual `adb` command. `users.groups.adbusers` sticks around
here purely so it's a valid group to put in `extraGroups` - it doesn't
grant anything on its own anymore, it's basically a fossil.

---

## `modules/system/GrubTheme.nix`

`elegant-grub2-themes` ([vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes))
is the one flake input here that does its own homework - it ships a real
NixOS module (`nixosModules.default`, `boot.loader.elegant-grub2-theme.*`),
so this file is just an `imports` line plus a handful of options. No
hand-rolled packaging like the old theme needed.

- **`theme = "wave"`** is the exact design from
  [gnome-look.org/p/2206122](https://www.gnome-look.org/p/2206122)
  ("Elegant-wave-grub-themes") - that listing turns out to just be a
  re-upload of this same repo. Confirmed by cloning it directly, since
  gnome-look.org blocks bots behind an "are you human" wall and wouldn't
  load. `type`/`side`/`color`/`screen` are the other knobs (window/float/
  sharp/blur, left/right, dark/light, 1080p/2k/4k) if you want to tweak
  the look.
- **The theme gets built, not downloaded pre-made.** Upstream's module
  runs its own `generate.sh` against the source art with whatever options
  are set, using imagemagick, and points GRUB at the result. Checked this
  by actually building the system and pulling the real theme folder out
  of the store - background image, fonts, icons, all there.
- **The flake input uses `git+https://` instead of the usual `github:`
  shorthand.** GitHub's API was rate-limiting this repo mid-setup (`403`,
  cheers), and `git+https://` talks to git directly instead of going
  through that API, so it just works regardless. Had to override
  upstream's own nested source input the same way for the same reason.

---
