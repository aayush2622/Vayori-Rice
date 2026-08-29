# Gaming app reference

[← Back to index](CONFIGURATION.md)

---

## `modules/apps/gaming/Gaming.nix`

One `vayori.apps` toggle (`Gaming`), split across four files for
readability rather than one large one — `lutris` + `heroic` as the two
launchers, Steam alongside them, plus shared tooling:

- **`Gaming.nix`** is the actual `flake.homeModules.apps.Gaming` entry. It
  computes `gamesDir`/`shaderCacheDir` and `imports` the three fragments
  below, threading those two paths to them via `_module.args` (a plain
  function argument doesn't reach an imported module — `_module.args` is
  the module system's mechanism for that; `self` needs no such threading,
  it's already a home-manager `extraSpecialArg` visible to every module in
  the tree, imports included).
- **`_launchers.nix`**: `lutris`/`heroic`/`adwsteamgtk` packages, the
  `~/Games` folder + GTK bookmark, and the Heroic/Steam matugen themes.
- **`_proton.nix`**: Proton/Wine tooling (`umu-launcher`, `wine`,
  `winetricks`, `protontricks`, `protonup-qt`), `$WINEPREFIX`, the Wine
  matugen theme, and Lutris's default-runner config.
- **`_performance.nix`**: `gamescope` + the two `gamescope-*` wrapper
  scripts, MangoHud, and the NVIDIA shader-cache path.

  All three fragments are **underscore-prefixed on purpose** — same
  reason as `_hardware.nix` (see
  [\_hardware.nix](core.md#moduleshostsname_hardwarenix)): import-tree skips any
  path containing `/_`, so these plain home-manager module fragments don't
  also get auto-imported as their own (invalid - they use `home.packages`
  etc, not flake-parts options) top-level flake-parts modules. They're
  only ever reached via `Gaming.nix`'s own `imports = [ ./_launchers.nix
  ./_proton.nix ./_performance.nix ];`.

- **Steam itself is enabled in `Host.nix`, not here**:
  `programs.steam.enable = true` is a NixOS-level option (32-bit
  graphics libs, firewall rules for Remote Play/in-home streaming,
  controller udev rules) — a per-user home-manager module can't set any
  of that, so it doesn't belong in this file even though every other
  launcher does. `umu-launcher` stays too — it's Lutris's native
  "Proton" runner (manages GE-Proton itself) and has nothing to do with
  Steam being present or not.

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
- **`programs.gamemode.enable = true`** lives in `Host.nix`, not here —
  it's a system-wide daemon (systemd *user* service + polkit +
  `cap_sys_nice` wrapper), not a per-user concern. Any launcher running
  games through `gamemoderun` (Lutris does, automatically) picks it up for
  free; use it explicitly as a prefix to combine with the rest, e.g.
  `gamemoderun gamescope-fsr --mangoapp -- %command%`.
- **GPU offload (Optimus laptop only)**: none of the above make a game use
  the dGPU — it runs on the weaker iGPU by default. `nvidia-offload` (from
  `hardware.nvidia.prime.offload.enableOffloadCmd`, see
  [\_hardware.nix](core.md#moduleshostsname_hardwarenix)) is NixOS's own
  ready-made wrapper for this — no separate script needed here. Use as a
  launch-option prefix, e.g. `nvidia-offload gamemoderun -- %command%`. The
  `dankAsusControlCenter` DMS widget's "GPU Mode" switch does the same
  thing at the whole-laptop level instead of per-launch.
- **Heroic matugen theme**: content (`self.matugenTemplates.heroic`)
  ported from [InioX/matugen-themes](https://github.com/InioX/matugen-themes),
  registered as `vayori.matugenTemplates.heroic` — DMS's documented
  custom-template mechanism, same as every other app here (see
  [Baseline.nix](desktop.md#modulesdesktopbaselinenix)/
  [Matugen.nix](desktop.md#modulesdesktopmatugennix)). Heroic has no fixed theme
  path — it only supports a user-configured "custom themes folder"
  (`customThemesPath`, set once in Settings → Accessibility) containing a
  `.css` + matching `.json` metadata pair. This writes both to
  `~/.local/share/heroic-matugen-theme/` (the `.json` is static, the
  `.css` is matugen-rewritten on every wallpaper change), but **does
  not** touch Heroic's own `config.json` to point `customThemesPath`
  there or auto-select the theme — its settings schema isn't fully
  documented publicly, and guessing wrong risks corrupting a real
  settings file other than just failing to theme. Point Heroic at the
  folder and pick "Matugen" from the theme dropdown once, manually.
- **Steam matugen theme, via AdwSteamGtk**: Steam's own UI has no
  supported custom-CSS hook; `pkgs.adwsteamgtk` (added to
  `home.packages` here) is the community skin installer that patches
  Steam's client UI to read `~/.config/AdwSteamGtk/custom.css` — the
  exact path `vayori.matugenTemplates.steam` writes to, content
  (`self.matugenTemplates.steam`) ported from InioX unmodified. Same
  one-time manual step as Heroic: run `adwsteamgtk` once (installs/
  updates the skin into Steam's own directory) — matugen keeps the CSS
  it reads recolored automatically after that.
- **Wine matugen theme**: `vayori.matugenTemplates.wine` writes a
  templated `.reg` file (content `self.matugenTemplates.wine`, InioX's
  unmodified — Win32 Control Panel colors plus disabling window
  decorations/enabling classic theme, for native apps that still read
  system colors) to `/tmp/wine.reg`, matching InioX's own documented
  path, then its `post_hook` imports it with `wine regedit` against this
  file's own shared prefix (`${gamesDir}/.wineprefix`, the same one
  `WINEPREFIX` below points at) — gated behind `test -d` so it's a no-op
  until that prefix actually exists (e.g. before first running anything
  through plain `wine`/`winetricks`). Only covers that shared prefix, not
  Lutris/Heroic's own independently-managed per-game ones, for the same
  reason `WINEPREFIX` itself doesn't reach them (see below).

