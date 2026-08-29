# Desktop reference

[← Back to index](CONFIGURATION.md)

---

## `modules/desktop/Dms.nix`

**Applied to every user**, not hardcoded to one —
`home-manager.users = lib.genAttrs (builtins.attrNames config.vayori.users) (name: { ... })`.
Hardcoding it was an earlier bug: a second account got a niri session with
no shell running in it.

**`settings = { ... }` is the only valid key.** An older
`default.settings = { ... }` shape is a silent no-op if you use it by
mistake.

**Wallpaper default**: `session.json` (`~/.local/state/DankMaterialShell/session.json`)
seeds `wallpaperPath`/`wallpaperCyclingFolderPath` from
`modules/assets/wallpapers` — but via `home.activation.seedDmsSession`
(`if [ ! -e "$sessionFile" ]; then ...`), not a declarative
`xdg.stateFile`/`force = true` entry the way `settings.json`/
`plugin_settings.json` are. That distinction matters: `session.json` is
DMS's own *runtime* state, rewritten every time you actually pick a
wallpaper or the carousel advances, not a fixed preference like
`settings.json`'s theme/layout options. An earlier version of this file
did force it like `settings.json` - which worked, but meant "pick a
wallpaper, then rebuild for any other reason" silently reset it back to
this seeded default, since a `force`d `xdg.stateFile` gets symlinked back
into the (read-only) Nix store on every single activation. Seeding it
once, only if it doesn't already exist yet, is the actual fix: DMS is
free to own and rewrite the file afterward, same as `settings.json` and
`session.json` behave in upstream DMS without any of this repo's config
at all.

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
  satisfied by [\_hardware.nix](core.md#moduleshostsname_hardwarenix)/`Host.nix`.
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
- **`dankBitwarden`**: needs `programs.rbw` set up separately (its own
  vault client, unrelated to the `bitwarden-desktop` app) — searches
  `rbw`'s entries, not the desktop app's. Default actions changed from
  the plugin's own defaults (`autotype`/`type:number`) to
  `copy:password`/`copy:number` — autotyping into whatever window happens
  to be focused is a riskier default than clipboard-copy, which is what
  Bitwarden's own UI defaults to.
- **`spotifyMatugen`**: no settings component — its whole feature
  ("lock DMS's dynamic colors to Spotify album art while playing") is the
  entirety of what `enable = true` does; there's nothing else exposed.
- **`nixMonitor`/`dankDiskUsage`/`dankAsusControlCenter` icon
  theming**: third-party dms-plugin-registry plugins hand-roll their own
  bar-pill layout instead of going through `BasePill` like DMS's built-in
  widgets do, so nothing forces them to agree with each other on icon
  size/spacing/color — confirmed by reading all three plugins' QML
  directly against the built-in `CpuMonitor.qml`, and against the
  [DMS plugin dev docs](https://danklinux.com/docs/dankmaterialshell/plugin-development)
  (`Theme.primary`/`Theme.iconSize` is the documented convention).
  `registryPlugins` (a `pkgs.callPackage` of the registry's own
  `nix/default.nix`) is patched via `runCommand` + `substituteInPlace`/
  targeted `sed`, then wired back in via `plugins.<id>.src = lib.mkForce
  <patched>` — in place, not replaced, so `plugin_settings.json`/updates
  from the registry still apply to everything else normally:
  - `dankDiskUsageWidget.qml` used `Theme.fontSizeLarge` (a font-size
    constant) for its icon instead of `root.iconSize`
    (`PluginComponent`'s own bar-aware size, backed by
    `Theme.barIconSize(...)` — what `nixMonitor` already used
    correctly), and `Theme.spacingS` instead of `Theme.spacingXS` for its
    icon/text row (line 312 only — every other `Theme.spacingS` in that
    file is unrelated popout-content spacing). Its `usageColor()`
    function also returned `Theme.primary` at baseline (an accent color,
    not the neutral `Theme.widgetIconColor` every other bar icon uses at
    rest — this was the actual "different from everything else" color)
    and hardcoded hex for the alert thresholds (`#ff4444`/`#ffaa00`),
    bypassing matugen entirely instead of `Theme.error`/`Theme.warning`.
    Kept the alert behavior itself (icon/text go red/orange past a
    threshold) — mirrors `CpuMonitor`'s own convention exactly, just
    fixed what each state actually points at.
  - `NixMonitor.qml`'s spacing/icon size were already correct; only its
    baseline color needed the same `Theme.primary` →
    `Theme.widgetIconColor` fix (line 110), keeping the `Theme.error`
    override past `gcThresholdGB`.
  - `DankAsusControlCenter.qml`'s color already resolved correctly
    (`useThemeColors = true` → `Theme.primary`, matching the documented
    convention) — only size (`Theme.iconSize * 0.85`, a fixed 24px
    ignoring bar thickness) and spacing (a raw hardcoded `spacing: 4`,
    line 521 only) needed the same `root.iconSize`/`Theme.spacingXS`
    treatment.
- **`dankDiskUsage.showNixStore = false`**: `nixMonitor` already reports
  Nix store size — both default to showing it, which would report it
  twice. `showZfs = false` too — `_hardware.nix` is btrfs, not ZFS,
  nothing to ever show there.
- **`dankAsusControlCenter.showBatteryIcon = false`**: battery % already
  lives in the separate `"battery"` bar widget — showing it here too
  would duplicate it.
- **`nixMonitor`'s Rebuild/GC buttons read their commands from
  `~/.config/DankMaterialShell/plugins/NixMonitor/config.json`**, not
  `plugin_settings.json`/the standard settings mechanism above at all —
  confirmed by reading `NixMonitor.qml` directly (`updateInterval` is
  peculiarly the one property *only* this file reaches; the settings UI
  offers a slider for it, but the underlying `QML` property isn't wired
  to `pluginData` the way its neighbors are). Researched how the plugin
  is actually meant to be used
  ([antonjah/nix-monitor](https://github.com/antonjah/nix-monitor)) — it
  has its own real-time console panel ("Appears automatically when
  running Rebuild or GC. Shows real-time stdout/stderr.") that a plain
  `sudo ... 2>&1` streams into directly; no terminal wrapper needed or
  wanted. That only works headlessly if `sudo` doesn't need a TTY to
  prompt in, hence `security.sudo.extraRules` below.
  - The flake's real clone location on whatever machine this actually
    runs on isn't something Nix can know at eval time — `rebuildCommand`
    searches `~/vayori`, `~/dotfiles`, `~/.dotfiles`, `/etc/nixos` at
    runtime instead of hardcoding a single guess, and errors clearly if
    none match rather than silently doing nothing. The host name *is*
    known at eval time (`config.networking.hostName`) — no guessing
    needed there.
- **`security.sudo.extraRules`**: `NOPASSWD`, but scoped to exactly
  `nixos-rebuild`/`nix-collect-garbage` (any arguments) for every
  `vayori.users` entry — not blanket passwordless sudo. Everything else
  still needs a real password; this exists purely so nixMonitor's two
  buttons can run without a TTY to prompt in.
- **`materialOSIcons`**: not in nixpkgs, fetched straight from
  [materialos/Linux-Icon-Pack](https://github.com/materialos/Linux-Icon-Pack)
  (verified against the actual repo: a real `index.theme`, 1704 app
  icons, `Inherits=gnome,hicolor` for graceful fallback on anything
  missing). Scoped to DMS's own app launcher only, via
  `home.sessionVariables.QS_ICON_THEME = "MaterialOS"` — per
  [DMS's own icon-theming docs](https://danklinux.com/docs/dankmaterialshell/icon-theming),
  that env var overrides DMS's icon theme independently of the
  system-wide GTK/Qt one (Papirus, set in
  [Baseline.nix](#modulesdesktopbaselinenix)), so this doesn't touch
  Nautilus or any other app. Static, read-only install is fine here —
  unlike Papirus, nothing needs to rewrite it at runtime.

---

## `modules/desktop/Niri.nix`

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
same reasoning as `Gaming.nix`'s named bindings: a ~90-line keymap reads
easier as its own thing than buried three levels into the `packages.myNiri`
attrset. Purely cosmetic — the built `myNiri` derivation hash is unchanged
by this, confirmed by rebuilding before/after.

---

## `modules/desktop/Fonts.nix` / `Portals.nix`

- `nerd-fonts.jetbrains-mono`: kitty + bar monospace glyphs.
- `material-symbols`: DMS's icon font.
- `xdg-desktop-portal-gnome`: file pickers/screenshots/screencast for niri.
- `xdg-desktop-portal-gtk`: GTK file chooser for Nautilus & co.
- **`xdg.portal.configPackages = [ pkgs.niri ]`, not a hand-written
  `config.common.default` list**: niri's own package ships
  `share/xdg-desktop-portal/niri-portals.conf` (confirmed by building
  `pkgs.niri` and reading it directly, not assumed from docs), which
  routes `Access`/`Notification` to `gtk` and `Secret` to
  `gnome-keyring` explicitly - none of which the old hand-rolled config
  did. One correction worth recording: the shipped file's own
  `default=gnome;gtk;` is *identical* to what this repo already had, so
  switching to it does **not** change ScreenCast/Screenshot routing at
  all, despite that being the headline complaint in
  [niri-wm/niri#3798](https://github.com/niri-wm/niri/issues/3798) (a
  different distro's packaging issue, not something reproduced or fixed
  here). The real, verified value of this change is picking up niri's
  own upstream-maintained routing instead of a hand-guessed one going
  forward, not a screencast fix. `nixpkgs.overlays`/`configPackages`
  wiring confirmed via `nix eval` (`xdg.portal.configPackages` resolves
  to `["niri-26.04"]`) and `environment.pathsToLink` already carrying
  `/share/xdg-desktop-portal` — not tested against an actual live
  screen-share, which the VM/Xvfb methodology used elsewhere in this
  repo can't exercise.

**`vayori.theme.font` drives every declarative font setting**:
`fontconfig.defaultFonts.sansSerif`, GTK app UI text (`gtk.font`), kitty,
and DMS's own UI (`fontFamily`/`monoFontFamily`). Not covered: the SDDM
greeter's clock/labels use a bundled `Itim-Regular.ttf` shipped inside the
"women-umbrella" theme itself
([desktop/sddm/Theme/font/](../modules/desktop/sddm/Theme/font/)) —
changing that means shipping a different `.ttf`, not a settings tweak. Qt
apps also aren't covered — their font comes from qt6ct's own config, which
DMS's `matugenTemplateQt6ct`/`matugenTemplateQt5ct` already manages.

---

## `modules/desktop/Baseline.nix`

Imported for every user regardless of `vayori.apps` — GTK/Qt theming is
the one piece of the rice nobody opts out of. Lives under `desktop/`, not
`apps/`, for exactly that reason: it isn't an opt-in app pick, it's part
of what makes this desktop this desktop.

- **`options.vayori.matugenTemplates` + the merged `config.toml`**: this
  is where DMS's own documented custom-template mechanism
  ([Application Theming](https://danklinux.com/docs/dankmaterialshell/application-themes))
  is actually assembled. Every themed app in this repo contributes one
  `[templates.<id>]` TOML block (`input_path`/`output_path`, optionally
  `post_hook`) to `vayori.matugenTemplates.<name>`; `Baseline.nix` merges
  all of them under a single `[config]` header and writes the result to
  `~/.config/matugen/config.toml` — the literal path and format DMS's
  own docs show. The option has to be a real top-level `options`/`config`
  split, not mixed into the implicit-config `mkMerge` list below it —
  Nix doesn't declare a genuine option otherwise, it just becomes config
  data under a literal path (hit this once while building it). The
  template *content* each app points its `input_path` at lives in a
  separate shared file, not here — see
  [Matugen.nix](#modulesdesktopmatugennix).
- **No trigger is wired up here — none is needed.** An earlier version
  of this file wrote the merged config to
  `~/.config/quickshell/dms/matugen/config.toml` (assumed to be DMS's
  real config dir, not its docs' literal path) and, on live VM testing
  against *that* path, found DMS's own wallpaper-change/`theme toggle`
  handling only regenerated its built-in templates, never this repo's
  custom ones — so a `home.activation`/`systemd.user` trigger was added
  to force it via a direct `dms matugen generate` call. That whole
  premise was wrong: re-tested against `~/.config/matugen/config.toml`
  (this file's real, documented path) and DMS's own live
  `wallpaper set`/`theme toggle` handling regenerates every custom
  template correctly and automatically, with no extra machinery at
  all - confirmed by clearing every custom output file, triggering a
  plain `dms ipc call theme toggle`, and watching all six reappear
  within seconds with fresh, correctly-recolored content. The earlier
  "DMS doesn't apply user templates live" conclusion was really "DMS
  doesn't read `config.toml` from a location it never looks at" -
  obvious in hindsight, but only actually confirmed by testing the
  right path, not the wrong one more carefully.
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
- **GTK matugen theming works via a plain `@import`**: DMS's matugen GTK
  templates always write `dank-colors.css` (no detection gate on the
  write side — confirmed in `core/internal/matugen/matugen.go`,
  `TemplateKindGTK`'s `appendConfig` call passes `nil` check lists, which
  `appExists` treats as "unconditional"), but GTK itself only auto-loads
  `gtk.css` — nothing imports the generated file without
  `gtk.gtk3.extraCss`/`gtk4.extraCss` setting exactly that. It also
  doubles as the *read* side of DMS's own `isDMSGTKActive()` gate, which
  checks for this exact `"dank-colors.css"` substring before firing live
  GTK refresh signals on each matugen run.
- **`qt.platformTheme.name = "qtct"` with no `style.name` override**: an
  earlier `style.name = "kvantum"` set `QT_STYLE_OVERRIDE=kvantum`, which
  forces every Qt app onto Kvantum's own separate SVG theme regardless of
  `platformTheme` — and matugen only ever generates qt5ct/qt6ct's native
  palette format, no Kvantum template exists. Leaving `style` unset lets
  qt5ct/qt6ct's own palette (`qt5ct.conf`/`qt6ct.conf`, below) actually
  apply.
- **`qt5ct.conf`/`qt6ct.conf`'s `color_scheme_path`**: matugen writes the
  palette itself (`~/.config/qt{5,6}ct/colors/matugen.conf`, rewritten on
  every wallpaper change) but never points qt5ct/qt6ct *at* it — same
  "updates an existing setup, never installs one" pattern as everywhere
  else DMS integrates. This pointer is the one-time setup matugen assumes
  already exists (its own `refreshQt6ct()` just touches this file's
  mtime to nudge already-running apps, it never writes the file).
- **Papirus is a mutable, per-user copy, not the Nix-store package
  directly** (`home.activation.installPapirusIconTheme`, copying
  `theme.iconPackage`'s `share/icons/Papirus` into
  `~/.local/share/icons/Papirus`): `papirus-folders` (the tool that
  recolors Papirus's folder icons to match the current accent)
  rewrites the theme's own `index.theme` + folder icon symlinks in
  place — confirmed by reading its actual script:
  `get_theme_dir()` checks `[ -w "$THEME_DIR/..." ]` and only re-execs
  under `sudo` if that fails, which is impossible against the read-only
  `/nix/store` copy `gtk.iconTheme.package` installs. The same script
  also searches `$XDG_DATA_HOME/icons` (`~/.local/share/icons`) *before*
  any Nix-store path, so this copy wins automatically — no search-path
  conflict with the read-only one GTK/Qt still reference by name.
  Copied with `rsync -aL --delete --chmod=u+w`, not `rm -rf` + `cp -rL`
  - the stamp-file gate above already makes this a one-time cost on a
  given icon-package version, but the very first time it does run again
  (the icon theme package itself bumping) `rsync` only transfers what
  actually changed between two Papirus releases instead of recopying
  the whole ~297k-file tree from scratch every time; `--chmod=u+w`
  keeps the copy writable the same way the old `chmod -R u+w` did.
  Functionally verified directly (not just evaluated): ran the exact
  rendered command against the real store path, confirmed a full
  writable copy and a writable SVG file inside it.
- **Dynamic folder-color recoloring** (`vayori.matugenTemplates.papirusFolders`,
  one of the `[templates.<id>]` blocks merged into `config.toml` above):
  matugen has real, built-in support for driving `papirus-folders`
  (confirmed against the installed matugen 4.1.0 binary directly:
  `input_path`, `colors_to_compare`, `compare_to`, and `post_hook` are
  all real, documented config keys, not DMS-specific). Picks the
  `colors_to_compare` entry closest to the current primary accent and
  runs `papirus-folders` with it as the `post_hook` — `input_path` just
  needs to *exist* (an empty file at
  `~/.config/matugen/templates/papirus-color`), matugen
  never reads its content for this case; the actual work happens in
  `post_hook`. No `sudo` — targets the writable copy above directly by
  path, which `papirus-folders` can edit as the regular user.

---

## `modules/desktop/Matugen.nix`

`flake.matugenTemplates` — one plain attrset, one attribute per themed
app (`btop`, `cava`, `heroic`, `steam`, `wine`, `vesktop`,
`androidStudio`), each holding the raw template *content* (a btop theme
file, a cava INI, a CSS stylesheet, a Windows `.reg` file, an IntelliJ
`.icls` scheme) that would otherwise be duplicated inline in every app
module. Needs its own
`options.flake.matugenTemplates = lib.mkOption { ... };` declaration, the
same way `modules/core/Registry.nix` declares one for `flake.homeModules`
— it isn't one of flake-parts' built-in known flake outputs, so nothing
merges it in without an explicit option (shows up as a harmless "unknown
flake output 'matugenTemplates'" notice from `nix flake check` —
informational only, not a failure).

Each app module reads its own entry straight off `self` — `self` is
already in scope as the outer flake-parts module argument
(`{ self, inputs, ... }: { flake.homeModules.apps.X = { pkgs, ... }: ...
self.matugenTemplates.X ... }`), and the inner home-manager module
function closes over it lexically; no extra plumbing needed (the same
pattern this repo already used for `inputs.*` inside these modules
before this file existed). An app module still owns:

- writing that content to its own file under
  `~/.config/matugen/templates/` (the *input* matugen reads from — this
  path is entirely our own choice, matugen doesn't care where
  `input_path` lives — the merged `config.toml` itself lives right next
  to it, at `~/.config/matugen/config.toml`, see
  [Baseline.nix](#modulesdesktopbaselinenix)),
- registering the `[templates.<id>]` block itself in
  `vayori.matugenTemplates` (the *output* path, and any `post_hook` —
  these are runtime/`config.home.homeDirectory`-dependent, so they can't
  be plain shared strings the way the template bodies can).

**`androidStudio` is a function, not a plain string** — `schemeName: ''
...''` — because the `.icls` scheme needs its own name baked into itself
(`metaInfo/originalScheme`, the `<scheme name="...">` attribute), a value
[AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix) already
computes locally for three other reasons (the output filename, the
`global_color_scheme` XML pointer). Called as
`self.matugenTemplates.androidStudio matugenSchemeName` — still a "public
variable," just one that takes an argument, rather than duplicating the
scheme name as a separate hardcoded literal in two files.

Every template body here except `vesktop` was ported from
[InioX/matugen-themes](https://github.com/InioX/matugen-themes) and kept
byte-for-byte as published (only the file's own path/wiring is
repo-specific) — `vesktop` has no InioX equivalent, it's the real
machine's own curated QuickCSS theme with matugen values spliced in, see
its own section for why. See each app's own section for per-app caveats
(Cava/Btop under [Terminal.nix](apps-utils.md#modulesappsutilsterminalterminalnix), Heroic/
Steam/Wine under [Gaming.nix](apps-gaming.md#modulesappsgaminggamingnix), Vesktop under
[Vesktop.nix](apps-utils.md#modulesappsutilsvesktopvesktopnix)).

---

