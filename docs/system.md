# System reference

[← Back to index](CONFIGURATION.md)

---

## `modules/system/DevTooling.nix`

Named for what it actually is — system-level enablement for development
workflows, not tied to any one app. Renamed from `dev-system.nix` during
the project restructure specifically to stop reading as a near-duplicate
of [apps/devTools/DevTools.nix](apps-development.md#modulesappsdevelopmentdevtoolsdevtoolsnix) (a
completely different, per-user file — VS Code/git/gh/lazygit/
docker-compose). `virtualisation.docker.enable`/`libvirtd.enable` are
the actual system daemons `dev-tools`' `docker-compose` and any VM
tooling need. `programs.adb.enable` was removed upstream — systemd 258+
handles the adb uaccess udev rules automatically, and
`pkgs.android-tools` (already in
[AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)) covers
the `adb` command itself — `users.groups.adbusers` stays declared here
purely as a valid `extraGroups` entry, it no longer grants anything on
its own.

---

## `modules/system/GrubTheme.nix`

`elegant-grub2-themes` ([vinceliuice/Elegant-grub2-themes](https://github.com/vinceliuice/Elegant-grub2-themes))
is unlike every other flake input here - it ships its own real NixOS flake
module (`nixosModules.default`, `boot.loader.elegant-grub2-theme.*`), so
this file is just `imports = [ inputs.elegant-grub2-themes.nixosModules.default
];` plus setting that module's options, not hand-rolling the packaging
the way this file used to for the
previous (`MrVivekRajan/Grub-Themes`) theme.

- **`theme = "wave"`** is the exact theme at
  [gnome-look.org/p/2206122](https://www.gnome-look.org/p/2206122)
  ("Elegant-wave-grub-themes") - that listing is a re-upload of this same
  upstream repo, which ships the "wave" background variant natively
  through its own `theme` option (`forest`/`mojave`/`mountain`/`wave`),
  confirmed by cloning the repo directly (gnome-look.org itself blocks
  automated fetches behind Anubis, an anti-bot challenge page) and reading
  its `flake.nix`/`README.md`.
  `type`/`side`/`color`/`screen` are the other real style knobs
  (window/float/sharp/blur; left/right; dark/light; 1080p/2k/4k) - see the
  upstream module's own option descriptions for the full list.
- **The theme is actually generated at build time**, not fetched
  pre-rendered - upstream's `nixosModules.default` runs its own
  `generate.sh` (needs `imagemagick`, pulled in as a `buildInputs` of the
  theme derivation) against the repo's source assets with whichever
  `theme`/`type`/`side`/`color`/`screen` combination is configured, then
  points `boot.loader.grub.theme`/`splashImage`/`gfxmodeEfi`/`gfxmodeBios`
  at the result. Verified by actually building the toplevel and reading
  the real generated `Elegant-wave-*` directory's `background.jpg`/
  `theme.txt`/fonts/icons out of the store, not assumed from the module
  source alone.
- **The flake input uses `git+https://github.com/...` instead of this
  repo's usual `github:owner/repo` shorthand**, and overrides upstream's
  own nested `elegant-grub2-theme-src` input the same way - both would
  otherwise resolve through `api.github.com`'s unauthenticated commit-
  lookup endpoint, which is rate-limited far more aggressively than git's
  own smart-HTTP protocol (`git+https://` talks to that directly, hit
  during this exact setup - `api.github.com` returned a 403 rate-limit
  error while `git clone`/`git+https://` fetches of the same repo kept
  working throughout).

---

