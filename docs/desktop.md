# Desktop reference

[← Back to index](CONFIGURATION.md)

---

## `modules/desktop/Dms.nix`

**Applies to every user, not just one hardcoded account** - an earlier
version had this hardcoded, and the bug it caused was exactly what you'd
expect: a second account logged into a niri session with no shell
running in it at all.

**`settings = { ... }` is the only key that actually does anything.** An
older `default.settings = { ... }` shape looks plausible and just quietly
does nothing if you type it by accident.

**Wallpaper default**: seeded once into
`~/.local/state/DankMaterialShell/session.json`, only if that file
doesn't already exist - not force-declared the way `settings.json` is.
That distinction actually matters: `session.json` is DMS's own live
state, rewritten every time you pick a wallpaper or the carousel
advances, not a fixed preference like theme/layout settings. An earlier
version of this file force-declared it the same way as `settings.json`,
which worked right up until "pick a wallpaper, then rebuild for any
unrelated reason" quietly reset it back to the seed - a force-declared
state file gets symlinked back into the read-only store on *every*
activation. Seeding once and then leaving it alone lets DMS actually own
the file going forward, same as it would with none of this repo's config
involved at all.

**`DMS_ENABLE_GTK4_REFRESH=1`** on the `dms` systemd user service - not
a `programs.dank-material-shell` option, since upstream doesn't expose
one for this; overridden straight on the generated
`systemd.user.services.dms` unit instead, which merges cleanly with
whatever that module already sets (confirmed against the real built
unit file - `Environment=` sits alongside the existing `ExecStart=`/
`Restart=`, nothing clobbered). Found by reading DMS's own Go source,
not guessed: on every wallpaper/theme change, DMS deliberately flips
`org.gnome.desktop.interface color-scheme` to the opposite value and
back 400ms later, specifically because a plain GTK theme change doesn't
make already-running GTK4/libadwaita apps (Nautilus included) reload
their CSS, but this toggle-and-restore round trip does. That whole
mechanism is opt-in, off by default, behind exactly this environment
variable - DMS's own comment calls out *why* it defaults off (some apps
following the portal's color-scheme, Chromium named specifically, can
drop the restore signal mid-repaint and get stuck in the wrong mode),
but the trade-off favors "Nautilus's own chrome actually reflects the
current wallpaper without a restart" here.

**Section order in the settings block**, if you're hunting for
something: theme, compositor, weather, animation, blur, wallpaper, bar
widgets, control center, workspaces, media, greeter, launcher, dashboard,
fonts, notepad, sounds, power, matugen (per-app toggles - also themes
niri's own window borders), dock, notifications, lock screen, OSD, power
menu, updater, displays, desktop clock, system monitor, desktop widgets,
frame.

**Third-party plugins** come from a community registry that auto-generates
an option per plugin, off by default, opt-in one at a time. A widget-type
plugin still needs manually adding to a bar section to actually show up -
enabling it alone isn't enough.

- **`dankAsusControlCenter`** is a bar popout for asusctl (power
  profiles, battery charge limits) and supergfxctl (GPU mode). Everything
  it needs is already installed elsewhere in this repo. Switching GPU
  mode needs a session logout, which the widget handles itself. Honest
  caveat: this has never actually touched real ASUS hardware, since
  there's none available to test against here - if the popout can't
  reach the daemons, check `supergfxctl -g`/`asusctl -v` work from a
  plain terminal first.
- **System monitor plugins**: several are enabled but deliberately not
  placed on the bar. CPU/RAM ones are skipped because DMS's own built-in
  widgets already show the exact same numbers - no point doubling up.
  Disk/IO monitors are enabled-but-unplaced for a more honest reason:
  seven new bar icons at once risked real clutter, and there was no
  screen available in this environment to actually eyeball how it'd
  look. They're one drag-and-drop away in DMS's own settings once you
  can see the bar for yourself.
- **`dankQuickSearch`** is enabled but not placed anywhere either - its
  own description suggests it hooks into the existing launcher directly
  rather than needing its own bar icon, unlike the monitor plugins whose
  descriptions explicitly say "in your bar." Give it a widget slot too if
  it turns out to want one.
- **`dankBitwarden`** talks to `rbw` (a separate CLI vault), not the
  desktop app - it searches whatever's in `rbw`, full stop. Its default
  actions got changed from autotype to clipboard-copy, since autotyping
  a password into whatever window happens to have focus is a riskier
  default than copy-to-clipboard, which is what Bitwarden's own UI
  defaults to anyway.
- **`spotifyMatugen`** has no settings beyond "on" - the whole feature is
  locking DMS's dynamic color to whatever's on the album art currently
  playing, and that's the entirety of what enabling it does.
- **Three community plugins needed icon patches to actually match the
  rest of the bar.** They hand-roll their own layout instead of using
  DMS's shared bar-pill component, so nothing forces them to agree on
  icon size, spacing, or color with everything else - traced this
  directly against their QML source and DMS's own plugin docs, not
  guessed. The patches (applied via a small `runCommand` + `sed`, in
  place, so plugin updates still flow through normally):
  - The disk-usage widget used a font-size constant for its icon instead
    of the bar-aware size everything else uses, plus different spacing,
    plus an accent color at rest where every other bar icon uses a
    neutral one, plus hardcoded hex colors for its warning thresholds
    that bypassed the theme entirely. Fixed the sizing/spacing/color to
    match; kept the actual "turns red past a threshold" behavior intact,
    just pointed at the right theme colors instead of literal hex.
  - The Nix monitor's spacing and icon size were already fine - just the
    same baseline-color fix as above.
  - The ASUS control center's color already resolved correctly; only its
    fixed pixel size and one hardcoded spacing value needed the same
    treatment.
- Disk usage and Nix monitor both hide their Nix-store-size figure by
  default, since they'd otherwise both show it - no reason to report the
  same number twice. Disk usage also skips ZFS entirely, since this
  machine runs btrfs and has none to show.
- The ASUS widget hides its own battery icon, since a separate battery
  widget already covers that.
- **Nix monitor's rebuild/GC buttons read their commands from their own
  separate config file**, not the plugin-settings mechanism everything
  else uses - traced directly through the plugin's QML, confirmed against
  its own upstream docs. It streams `sudo`'s real stdout/stderr straight
  into its own live console panel, no terminal wrapper needed - which
  only works headlessly if `sudo` doesn't need a TTY to prompt in (see
  the sudo rule below). Since Nix can't know at eval time where the
  actual flake clone lives on whatever machine this runs on, the rebuild
  command searches a short list of likely spots at runtime instead of
  guessing once, and fails loudly if none of them match rather than
  silently doing nothing.
- **A scoped sudo rule** lets every user run `nixos-rebuild`/
  `nix-collect-garbage` without a password - and *only* those two
  commands, with any arguments. Not blanket passwordless sudo, just
  enough for the Nix monitor's two buttons to actually work without a
  TTY to type a password into.
- **The app-launcher icon theme** is a separate icon pack fetched
  straight from its own repo (not in nixpkgs), scoped to DMS's launcher
  only via an env var DMS specifically documents for this - it doesn't
  touch Nautilus or anything else system-wide. Static install is fine
  here; unlike Papirus below, nothing ever needs to rewrite it at
  runtime.

---

## `modules/desktop/Niri.nix`

**`extraSettings` has to sit next to `settings`, not inside it.** Nest it
and it silently serializes into an invalid config node instead of using
the wrapper's actual mechanism for raw config.

**The `include` gotcha that took a while to track down**: DMS renders a
colors file on every theme change and includes it optionally, so niri
still boots even before DMS has run once. Problem: niri rejects two
separate top-level `layout` blocks in general, but an *included* one
quietly *merges* into the one already parsed - so DMS's include was
silently overwriting this repo's translucent border colors with
matugen's opaque ones. Fix: a second include, placed after DMS's, that
just re-asserts the one field that needs to stay put. Includes merge, so
the second one wins for that field while everything else stays live and
dynamically themed.

**Blur runs at 2 passes instead of niri's default 3** - each additional
pass roughly doubles the render cost, and this runs on the Intel iGPU,
not a dGPU. Looks basically identical, costs noticeably less.

**Two ways to spawn a command**: one execs directly, the other forks a
shell first. Most binds use the direct one; the brightness binds need the
shell version since they pipe one command's output through `awk`.

The keybind list lives as its own named binding instead of buried three
levels deep in the config attrset - purely for readability, doesn't
change the built output at all.

---

## `modules/desktop/Fonts.nix` / `Portals.nix`

- One font package for terminal/bar glyphs, one for DMS's icon font.
- Two portal backends registered: `xdg-desktop-portal-gnome` (needed for
  screencast/screenshot - niri itself doesn't implement those, and the
  plain GTK portal can't either) and `xdg-desktop-portal-gtk` (the
  generic file-chooser/settings backend most non-GNOME compositors use).
- **Explicit per-interface routing via `xdg.portal.config.niri`** -
  `default = [ "gtk" ]`, with `ScreenCast`/`Screenshot` specifically
  routed to `gnome`. This used to rely on `configPackages = [ pkgs.niri
  ];`, on the assumption niri's own package ships a portal config file
  the way some other compositor packages do. **That assumption was
  wrong, checked for real**: the actual built `pkgs.niri` output has no
  `share/xdg-desktop-portal/` directory at all, no `.conf` file, nothing
  - so that line was silently a no-op the whole time, and portal backend
  resolution was left to whatever xdg-desktop-portal's own default
  arbitration happened to pick between two registered, un-prioritized
  backends. That's a genuinely well-documented performance problem, not
  just a correctness nitpick: `xdg-desktop-portal-gnome` expects a real
  GNOME Shell underneath it, and GTK4/libadwaita apps (Nautilus very
  much included) query the portal's `Settings` interface on every
  single launch for color-scheme/accent-color - if that call lands on
  the GNOME backend instead of GTK under a non-GNOME compositor, it can
  stall for a real, user-visible amount of time before falling through.
  Widely reported for exactly this reason on sway/hyprland/niri setups,
  and niri's own wiki independently documents the exact fix now in
  place here: default to `gtk`, carve out just `ScreenCast`/`Screenshot`
  for `gnome`. Verified the corrected config actually resolves
  (`nix eval`'d against the real option schema, not guessed) - not
  verified against a live screen-share/screenshot session, which isn't
  possible in this environment.

**One font setting drives everything declarative**: system font, GTK app
text, terminal, and DMS's own UI all read the same shared font option.
Two things it doesn't reach: the SDDM login screen's clock/labels use a
font bundled inside the login theme itself, so changing it means
shipping a different font file, not flipping a setting. Qt apps also read
their font from Qt's own config instead, which matugen already manages
separately.

---

## `modules/desktop/Baseline.nix`

Applied to every user regardless of which apps they've opted into - GTK/Qt
theming is the one part of this whole rice nobody gets to skip. Lives
under `desktop/`, not `apps/`, for exactly that reason: it isn't an
opt-in pick, it's just part of what this desktop *is*.

- **This is where DMS's custom-template system actually gets assembled.**
  Every themed app in this repo contributes one small config block to a
  shared option; this file merges all of them into one file at the exact
  path DMS's own docs say to use. Needed its own real, separate option
  declaration to work properly - mixing it into the implicit config below
  it just makes it plain data at a literal path instead of an actual
  option, which was a real, if brief, mistake while building this. The
  actual template *content* each app points at lives in a separate
  shared file - see [Matugen.nix](#modulesdesktopmatugennix).
- **No extra trigger needed here, and it's worth explaining why not**: an
  earlier version of this file wrote the merged config to a *guessed*
  path, tested it, found DMS wasn't picking up custom templates live, and
  concluded a whole extra activation trigger was needed to force it.
  Wrong conclusion, right symptom. Re-tested against the actual
  documented path DMS really reads and everything just worked - every
  custom template regenerated automatically on a live wallpaper/theme
  change, no extra machinery required. "DMS doesn't apply custom
  templates live" turned out to really mean "DMS doesn't read a file it
  was never looking at in the first place" - obvious in hindsight, only
  actually caught by testing the *right* path more carefully, not the
  wrong one harder.
- **A whole GTK3 base theme was just missing.** Icon/cursor/font were all
  set, but no actual theme name or package - so GTK3 apps fell back to
  whatever's compiled in by default. This turned out to be the real
  reason matugen's live recoloring didn't visibly do anything on GTK
  apps: DMS always writes its color overrides file regardless of what
  theme is active, but those overrides are meant to be *consumed* by a
  libadwaita-aware stylesheet - with no such theme installed, they had
  nothing to attach to. Adding the standard GTK3-compatibility companion
  theme (adw-gtk3) fixed it.
- **A second, more specific gap on top of that**: the theme's checkbox/
  radio/slider icon assets only get found by DMS's helper script at a
  handful of hardcoded paths, and the normal "make the theme reachable"
  approach isn't one of them - without a symlink at the exact path this
  script actually checks, those controls render as solid blocks even
  with the theme name correctly set. One extra `home.file` entry closes
  that gap.
- One deprecation warning got silenced by explicitly adopting the newer
  default behavior directly, which also happens to be the semantically
  correct choice here - the GTK3 theme in use doesn't mean anything as a
  "GTK4 theme," GTK4/libadwaita apps get their look elsewhere.
- **XDG user dirs** get created and populated so the standard folders
  (Desktop, Documents, Downloads, etc.) actually show up as sidebar
  bookmarks in Nautilus and any other GTK file picker - without this
  they just don't exist anywhere for a fresh account. Session variables
  for the same paths get exported too, for the handful of apps that read
  those directly instead of parsing the file themselves.
- **GTK theming works through a plain CSS import**, since DMS always
  writes its color file but GTK itself never auto-loads anything but its
  own default stylesheet - one line importing the generated file is what
  actually wires it up, and it also happens to be the exact string DMS
  itself checks for before firing live refresh signals on theme changes.
  **That check turned out to be checking the wrong thing, though** - a
  real, previously-missed bug, found by reading DMS's own Go source
  rather than trusting the CSS content alone was enough. DMS decides
  whether to fire *any* live refresh at all (GTK3 theme reload, GTK4 CSS
  reload, accent-color sync - all three, gated by the same one check) by
  inspecting `~/.config/gtk-3.0/gtk.css`: if it's a symlink (which is
  exactly what `home.file`/`gtk3.extraCss` always produces), DMS checks
  whether the *symlink's target path* contains the literal string
  `"dank-colors.css"` - not the file's content. Using `gtk3.extraCss`/
  `gtk4.extraCss` directly, that target path is home-manager's own
  generic `hm_gtk3.0gtk.css`, which never contains that substring -
  confirmed against the real built symlink, not assumed. So the whole
  live-refresh pipeline was silently gated off this entire time,
  regardless of anything else configured (including
  `DMS_ENABLE_GTK4_REFRESH` - see [Dms.nix](#modulesdesktopdmsnix), which
  genuinely helps, but was never getting the chance to run at all). Fixed
  by bypassing `gtk3.extraCss`/`gtk4.extraCss` and declaring the files
  directly via `home.file.<path>.source = pkgs.writeText
  "dank-colors.css" ...` instead - same content, but now the symlink
  target is *named* `dank-colors.css`, which is exactly the string DMS
  is looking for. Confirmed against the real built symlink again after
  the fix.
- **Qt theming deliberately has no separate style override set.** An
  earlier version forced every Qt app onto a totally different theming
  engine regardless of the palette settings below, and matugen has no
  template for that engine at all - leaving it unset lets the actual
  matugen-driven palette apply the way it's supposed to.
- **The Qt palette files point at where matugen writes its output**,
  since matugen writes the palette itself but never points the Qt config
  *at* it - same "updates an existing setup, doesn't install one" pattern
  as everywhere else DMS integrates with something. This pointer is the
  one-time setup matugen assumes is already in place.
- **Papirus lives as a real, writable per-user copy, not the read-only
  Nix package directly.** The tool that recolors Papirus's folder icons
  to match the current accent needs to actually rewrite files in place,
  which it can't do against a read-only store path - confirmed by
  reading its actual script. Conveniently, that same script checks the
  user's own icon directory before any system one, so this writable copy
  just wins automatically with zero conflict. Copied with `rsync
  --delete`, not a full recursive delete-and-recopy, so a version bump
  only transfers what actually changed instead of recopying roughly
  300,000 files from scratch every time - checked this for real against
  the actual rendered command, not just eyeballed the intent.
- **Folder color-matching** uses matugen's own real, documented support
  for driving that recoloring tool - checked against the installed
  matugen binary directly, these aren't repo-specific hacks. It picks
  whichever preset color is closest to the current accent and runs the
  recoloring tool with it, no `sudo` needed since it's editing the
  writable copy directly as the regular user.
- **The recoloring tool's own `-u` (update icon caches) flag was
  silently doing nothing.** Checked its actual script: `-u` shells out to
  `gtk-update-icon-cache`, a `gtk3` binary this repo never installed
  anywhere - `papirus-folders` itself doesn't depend on it (confirmed via
  `nix why-depends`), so it was missing from `$PATH` entirely. The
  recoloring itself was working the whole time - the underlying icon
  files really were getting rewritten - but with nothing ever
  invalidating the cached icon index, every app (Nautilus very much
  included) just kept reading the stale one forever. `pkgs.gtk3` added
  alongside `papirus-folders`, scoped to the same Papirus-only block.
- **Nautilus's own window chrome not updating live is a separate,
  GTK4-specific gap, not this same bug.** The CSS-import mechanism above
  is real and does work, but modern libadwaita (GTK4) deliberately
  doesn't hot-reload from a plain CSS re-import the way GTK3 apps do -
  DMS's own upstream source confirms this in a comment, and ships a
  specific fix for it (a deliberate color-scheme toggle-and-restore
  round trip) that's opt-in behind an environment variable, off by
  default. See [Dms.nix](#modulesdesktopdmsnix) for where that gets
  turned on.

---

## `modules/desktop/Matugen.nix`

One shared attrset, one entry per themed app, each holding the raw
template content (a theme file, a CSS stylesheet, a Windows registry
file, an IDE color scheme) that would otherwise get duplicated inline in
every app's own module. Needed its own explicit option declaration to
actually merge correctly - it's not one of flake-parts' built-in outputs,
so nothing combines it automatically without that (shows up as a
harmless "unknown flake output" notice from `nix flake check` - purely
informational, not a failure).

Every app module reads its own entry straight off the shared flake
output - no extra plumbing needed, same pattern already used for other
shared inputs. Each app module still owns two things itself: writing that
content out to its own file under the matugen templates folder (matugen
doesn't care where this lives, it's this repo's own choice), and
registering the actual output path and any post-processing hook - those
depend on the real user's home directory at runtime, so they can't be
plain shared strings the way the template bodies themselves can.

**The Android Studio template is a function, not a plain string** -
because the color scheme file needs its own name baked into itself in a
couple of places, a value Android Studio's own module already computes
locally for other reasons anyway. Called with that name as an argument
rather than hardcoding the same string twice in two different files.

Every template here except Vesktop's was ported byte-for-byte from
[InioX/matugen-themes](https://github.com/InioX/matugen-themes) - only
the wiring (where it gets written, what it's called) is specific to this
repo. Vesktop's is different: there's no InioX template for it, so it's
the real machine's own hand-curated QuickCSS theme with matugen values
spliced in instead - see its own section for the full story on that one.
