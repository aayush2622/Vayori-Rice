# Utility apps reference

[← Back to index](CONFIGURATION.md)

---

## `modules/apps/utils/zenBrowser/ZenBrowser.nix`

**The profile always lives at `~/.zen/default`** - a fixed path this repo
owns outright, instead of trying to guess what a previous install named
it. Doesn't exist yet? The activation script creates it. Already there?
It gets reused and re-synced on every rebuild.

- `zenPrefs` are the settings you'd normally poke at through `about:config`.
- **`zenUserPrefs`/`zenUserJs`** hold look-and-feel state (compact mode,
  floating urlbar, hidden sidebar, every mod's tuned values) pulled out
  of a real profile's `prefs.js`. These go into `user.js` instead of
  being locked via `zenPrefs`, because they're things you'd realistically
  keep fiddling with through Zen's own Settings - locking them would
  freeze you out of your own UI. Downside: `user.js` reapplies on every
  *launch*, so a live tweak survives until the next restart, not the next
  rebuild. Deliberately left out: Sync state (tied to an account), proxy
  settings (dead anyway, and copying a real IP around is a bad idea), and
  a backup-location path that only made sense on the source machine.
- **Adding an extension** (`zenExtensions`) means finding two IDs on
  addons.mozilla.org: the `slug` (in the URL) and the `guid` (from the
  API, or the search endpoint if multiple listings share a name - go by
  daily users). You need both - `slug` is just the rename-able download
  name, `guid` is the actual manifest ID that policy enforcement keys on.
  This can't be automated the way mods can: extension policy gets baked
  into `policies.json` at build time, and flakes evaluate with no network
  access, on purpose.
- **Theming**: Zen has no Pywalfox-style plugin for this, so it's plain
  `userChrome.css`. DMS renders the wallpaper palette into a stylesheet,
  the activation script symlinks it into the profile, and the one prefs
  flag that makes custom stylesheets legal gets locked so there's no
  manual `about:config` step.
- **First-run bootstrap**: if the profile doesn't exist, the script runs
  Zen's own `-CreateProfile` command. That command still tries to talk to
  GTK even with no window to show, so it fails with "no DISPLAY" if run
  headless - it's wrapped in `xvfb-run` (a fake, disposable X server)
  purely to give it something to talk to.
- **That command, and every `curl` call in this file, is time-boxed.**
  Not paranoia - a real bug. `-CreateProfile` under Xvfb (no GPU, nothing
  for its telemetry pings to reach) doesn't always exit cleanly, and an
  activation script that never returns blocks the *entire* rebuild, not
  just Zen's little corner of it. Watched this actually happen while
  testing. An earlier, tighter timeout was too tight - `-CreateProfile`
  genuinely needs more than 45 seconds under these conditions, so it kept
  getting killed mid-setup instead of just being slow.
- **"Did it finish" is checked via a file, not a directory.** A killed
  `-CreateProfile` can leave a half-built profile folder behind - if the
  check were just "does the folder exist," that half-finished mess would
  look done forever and never get retried. `times.json` only gets written
  once profile creation genuinely completes, so a botched attempt leaves
  nothing behind to fool the next rebuild.
- **The script narrates itself** - profile creation starting/done/timed
  out, mods being fetched one by one - instead of running silently.
  That's on purpose: a slow-but-working setup and a genuinely stuck one
  look identical from the outside with zero output. This makes the
  difference visible in a normal terminal, not just buried in
  `journalctl`.
- **Zen Mods** live in the same activation script (theming, `user.js`,
  and mods all need the same resolved profile path), traced through
  Zen's own source rather than guessed at:
  - The mods file is a JSON object keyed by mod ID, each entry carrying
    its metadata plus `enabled`.
  - `zenMods` here is just a `name -> id` map. Unlike extensions, this
    *can* be resolved live -
    [zen-browser/theme-store](https://github.com/zen-browser/theme-store)
    publishes a full index, so the script fetches it, filters to the IDs
    listed, and writes the result straight out. No hand-copied metadata
    to drift out of date.
  - Each mod's actual CSS/prefs get fetched separately, only if missing -
    self-heals if a file disappears, doesn't refetch on every rebuild.
  - **One broken mod takes the rest down with it.** Zen loops over
    enabled mods with no per-mod error handling, so one missing file
    throws and nothing themes that session. One mod ("Remove Browser
    Padding") is simply missing from upstream's own index right now, so
    it's absent here too - add it back whenever upstream does.
  - **Every `curl` call spells out the full store path**, never bare
    `curl` - an interactive shell has `curl` on `PATH`, the systemd
    service running activation scripts has a much narrower one, and a
    missing `curl` there fails silently instead of loudly. Found this by
    actually booting a fresh VM, not by guessing.

---

## `modules/apps/utils/spicetify/Spicetify.nix`

**Custom font**: Spotify's client reads its UI font from a CSS custom
property, not plain `font-family`, so the theme CSS sets it explicitly
to the shared theme font and pulls the font package in as a dependency
of the themed build. The theme's own options get merged with, not
replaced by, this override - safe since Spicetify's theme option takes a
freeform attrset.

---

## `modules/apps/utils/nautilus/Nautilus.nix`

- Thumbnails kick in for bigger files instead of falling back to a
  generic icon.
- Mouse back/forward buttons navigate history.
- Drag a file over a folder and it opens automatically instead of making
  you wait.
- Opens maximized - the cramped default window size helps nobody.
- Drives/USB/SD cards auto-mount and pop a window open, but nothing ever
  auto-runs. Nobody needs that surprise.
- The open-terminal extension defaults to gnome-terminal, which isn't
  installed here, so it's pointed at kitty instead.
- gvfs and tumbler run system-wide via `Host.nix` - they're daemons, not
  a per-user concern.

---

## `modules/apps/utils/bitwarden/Bitwarden.nix`

Just the desktop app - nixpkgs calls it `bitwarden-desktop`, not
`bitwarden` (that name throws a "this package got renamed" error if you
try it). Signing in and syncing still needs doing once by hand; Nix just
makes sure the app itself is there.

**`programs.rbw`** is a separate CLI vault, unrelated to the desktop
app's own login - it's what the Bitwarden launcher plugin in DMS actually
talks to behind the scenes. The account email has no sensible default
and home-manager's own module requires *something*, so it's left unset
here on purpose: run `rbw config set email you@example.com` once, then
`rbw login`, and it works without a rebuild. Set it declaratively later
if you'd rather.

---

## `modules/apps/utils/terminal/Terminal.nix`

Kitty + zsh (oh-my-zsh) + fastfetch + Starship + eza, one toggle. Fastfetch
picks a random logo out of `modules/apps/utils/terminal/images/` every
time you open a shell, and falls back to its own default if that folder
ever ends up empty.

- **Starship replaced a hand-rolled prompt.** The old one was a manual
  `precmd` hook that could only show the current branch - no dirty/staged/
  ahead-behind state, nothing. Starship fully owns prompt rendering once
  enabled, so the old code got deleted rather than left fighting it for
  the prompt.
- **eza replaces `ls` outright** via zsh integration (`ls`/`la`/`ll`/
  `lla`/`lt` all get aliased automatically) - the goal was a better `ls`,
  not a second tool to remember on top of it.
- **btop gets an actual theme now.** It used to just be an unconfigured
  package. Now it's told to look for a theme literally called `matugen`,
  which gets rewritten to match the wallpaper on every change - through a
  plain file, deliberately *not* home-manager's own theme option, since
  that option writes an immutable file and would just fight matugen for
  control of it. Same class of problem this repo already solved for GTK,
  Qt, and Android Studio.
- **cava** gets the same treatment, minus the "theme vs settings" split
  btop has - it only has the one config file, so matugen just owns it
  outright and cava fills in every other setting with its own built-in
  defaults.
- **Spicetify and Starship were skipped when wiring up matugen
  everywhere else**, on purpose - both are hand-extracted, curated
  configs from the real machine, not generic templates, and there's no
  clean way to splice in a dynamic palette without undoing the actual
  point of extracting them "as they really are." Covering every possible
  app with matugen was never the goal; not clobbering deliberately-tuned
  settings mattered more.

---

## `modules/apps/utils/vesktop/Vesktop.nix`

Two real config files, pinned straight off the reference machine, plus a
matugen theme - same "capture what's actually there" approach as the
editors. Declared as plain Nix data and serialized out, not copied in as
opaque `.json` files, so it reads like everything else in this repo.

- **Vencord's settings and plugin list** are just every plugin actually
  enabled on the real machine, with any non-default tuning (blur amount,
  ignore lists, that kind of thing). Unlike JetBrains plugins, nothing
  here needed fetching - every Vencord plugin ships built into the app,
  so "installing" one is just flipping a boolean.
- **Vesktop's own settings** (tray behavior, update branch, spellcheck
  languages, splash colors) live in a separate, smaller file at a
  different path, captured the same way.
- **Plugins that are just plain "off" got left out entirely** rather than
  spelled out one by one - of about 172 real plugins, 68 made the cut
  (everything on, plus anything with non-default settings even while
  off, plus the framework "*API" plugins kept explicit either way, since
  other plugins hook into them and it costs nothing to be safe). Checked
  Vencord's own source for this rather than assuming: leaving a plugin
  out resolves to exactly the same default it'd get if it were "off" and
  unmentioned, for every single one of them.
- **Runs through home-manager's native Vesktop module** now, not
  hand-written files - it grew one after this was first set up, and it
  writes to the exact same two paths this repo always used, so nothing
  needed restructuring. One real difference: the native module doesn't
  force-overwrite, so a leftover file from an earlier manual Vesktop
  launch can collide with it on the very first switch - a one-time
  delete of those two files clears that up. The QuickCSS path stays on
  its own separate template rather than the module's built-in option,
  since matugen already owns that exact file.
- **QuickCSS is a real, curated theme, not a blank file** - it's
  DiscordRecolor, kept byte-for-byte the same structure as the original,
  with just the hardcoded colors swapped for matugen ones mapped by
  best-fit intent (DiscordRecolor wants brightness/elevation ramps,
  Material gives named roles - mapped brightest-to-darkest and
  container-by-container rather than 1:1). It's not a home-manager file
  either - matugen owns it outright and rewrites it on every wallpaper
  change, same as everything else it touches in this repo.
