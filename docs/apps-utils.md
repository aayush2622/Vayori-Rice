# Utility apps reference

[← Back to index](CONFIGURATION.md)

---

## `modules/apps/utils/zenBrowser/ZenBrowser.nix`

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
- **That same command is wrapped in `timeout 120s`**, and every `curl`
  call in this file has `--max-time 15` — a real bug, not a
  precaution: a Firefox-based `-CreateProfile` invocation doesn't
  always exit cleanly under Xvfb (no real GPU, telemetry/update
  checks with nothing to talk to), and with no bound on it, an
  activation script that hangs waiting for it blocks
  `home-manager-ash.service` indefinitely - the entire rebuild, not
  just Zen Browser's own setup. Confirmed as a genuine failure mode
  (not just a theoretical one) while testing this repo's activation
  scripts more broadly; `curl`'s own `--retry 2` doesn't bound total
  time the way `--max-time` does, so both needed the same fix. An
  earlier, tighter 45s bound turned out to be too tight on a
  resource-constrained VM - `-CreateProfile` legitimately needs longer
  than that under Xvfb with no real GPU, so it got killed before
  finishing, not because it was actually stuck.
- **Completion is checked via `$PROFILE_DIR/times.json`, not `-d
  $PROFILE_DIR`** — a bare directory-exists check has a real failure
  mode: if `timeout` kills `-CreateProfile` partway through, it can
  leave a half-created profile directory behind, and a directory-only
  check would then treat that broken state as "already done" forever,
  never retrying. `times.json` is a file Firefox/Zen only ever writes
  once profile creation genuinely finishes, so a killed attempt leaves
  no false-positive behind — the next rebuild retries properly instead
  of silently skipping mods/settings every time after.
- **The script `echo`s progress at every step** (profile creation
  starting/done/timed-out, mods index fetch, each mod by name) rather
  than running silently — these lines aren't gated behind `$DRY_RUN_CMD`
  since they're pure output, and they show up live in a normal
  interactive `nixos-rebuild switch`/`home-manager switch` (home-manager
  streams its own activation output to the terminal), not just in
  `journalctl`. The point: a slow-but-working `-CreateProfile` and a
  genuinely stuck one look identical from the outside with no output at
  all - this makes the difference visible instead of just picking a
  bigger timeout and hoping.
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

---

## `modules/apps/utils/spicetify/Spicetify.nix`

**Custom font**: Spotify's client CSS reads its UI font from the
`--font-family` custom property, not generic `font-family: sans-serif` —
`theme.additionalCss` sets it to `vayoriTheme.font` explicitly.
`theme.extraPkgs = [ vayoriTheme.fontPackage ]` makes that font an
explicit dependency of the spiced Spotify derivation. `spicePkgs.themes.hazy
// { ... }` merges onto the theme's existing options — `theme` accepts a
freeform attrset, so this is safe.

---

## `modules/apps/utils/nautilus/Nautilus.nix`

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
- gvfs + tumbler are enabled system-wide in `Host.nix` — they're daemons,
  not per-user.

---

## `modules/apps/utils/bitwarden/Bitwarden.nix`

Just `pkgs.bitwarden-desktop` — the nixpkgs attribute name is
`bitwarden-desktop`, not `bitwarden` (that alias throws a
renamed-package error). Added so a fresh install has a working password
manager without a manual first-run setup step; vault contents still
require signing in once, syncing pulls everything else back down.

**`programs.rbw`** is a separate CLI vault client from the desktop app
above — it's what the `dankBitwarden` DMS launcher plugin
([Dms.nix](desktop.md#modulesdesktopdmsnix)) actually shells out to, an unrelated
session from the desktop app's own login. `settings.email` has no
default and is required by home-manager's own `rbw` module, so it's left
unset here pending the real account email — `rbw config set email
<you>` once, then `rbw login`, gets it working without needing a
rebuild. Once known, it can be set declaratively instead: `programs.rbw
= { enable = true; settings = { email = "you@example.com"; pinentry =
pkgs.pinentry-gtk2; }; };`.

---

## `modules/apps/utils/terminal/Terminal.nix`

Kitty + zsh (oh-my-zsh) + fastfetch + Starship + eza, one selectable app.
`initContent` picks a random logo from `modules/apps/utils/terminal/images/`
per shell (falls back to fastfetch's default if the directory is empty).
The zsh plugin list and fastfetch's `modules` array are named `let`
bindings (`zshPlugins`, `fastfetchModules`) rather than inlined — same
reasoning as `Niri.nix`'s `niriBinds`, purely readability, verified
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
- **`programs.btop` + a matugen theme**: `btop` used to be a bare
  `environment.systemPackages` entry with no config at all -
  `programs.btop.settings.color_theme = "matugen"` tells it to look for
  a theme literally named `matugen`, which the registered
  `vayori.matugenTemplates.btop` block (content from
  [Matugen.nix](desktop.md#modulesdesktopmatugennix), ported from
  [InioX/matugen-themes](https://github.com/InioX/matugen-themes))
  writes to `~/.config/btop/themes/matugen.theme` on every wallpaper
  change - deliberately *not* declared through home-manager's own
  `programs.btop.themes` option, since that writes a static, Nix-store-immutable
  file and would fight matugen for ownership of it, the same class of
  problem solved for GTK/Qt/Android Studio earlier.
- **`cava`**: no home-manager `programs.cava` module used here — cava has
  only one config file (no separate "theme" vs. "settings" split like
  btop), so matugen is given full ownership of it outright rather than
  fighting a home-manager-managed immutable symlink for the same path.
  `vayori.matugenTemplates.cava` points straight at
  `~/.config/cava/config`; the content (`self.matugenTemplates.cava`,
  from [Matugen.nix](desktop.md#modulesdesktopmatugennix)) is InioX's `[color]`
  block unmodified — cava fills in every other setting (bars, framerate,
  ...) with its own built-in defaults for anything the file doesn't
  mention.
- **Spicetify (Spotify) and Starship were deliberately skipped** when
  wiring up matugen from InioX/matugen-themes, even though both apps are
  covered there: `spicetify/spicetify.nix`'s theme (`hazy`,
  `colorScheme = "Base"`) and `starshipSettings` here are both direct,
  hand-extracted transcriptions of the real machine's actual config (see
  [spicetify.nix](#modulesappsutilsspicetifyspicetifynix) and the Starship
  note above) - InioX's templates are a completely different theme/
  prompt layout for each, not just different colors, and there's no
  clean way to splice in just a dynamic palette without restructuring
  what was deliberately extracted "as it is." Blanket-applying matugen
  everywhere isn't the goal; not clobbering curated settings is a bigger
  priority than covering every app InioX supports.

---

## `modules/apps/utils/vesktop/Vesktop.nix`

Two real config files pinned straight off the reference machine, plus a
matugen-driven theme — same "capture what's actually there, don't guess"
approach as [AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix).
Declared as plain Nix attrsets (`vesktopSettings`, `vencordSettings`,
`vencordPlugins`), written out with `builtins.toJSON` — not two static
`.json` files copied in — so the settings live and read as ordinary Nix
data like everywhere else in this repo, not as opaque blobs.

- **`vencordSettings`/`vencordPlugins`**: Vencord's own
  `settings/settings.json` — every plugin actually enabled on the real
  machine (and any non-default settings on them, e.g.
  `BlurNSFW.blurAmount`, `MessageLogger`'s ignore lists). Unlike Android
  Studio's JetBrains plugins, none of this needed fetching — every
  Vencord plugin ships built into the app itself; "installing" one is
  just flipping `enabled = true;` here, nothing external to pin.
- **`vesktopSettings`**: Vesktop's own separate, smaller settings block
  (tray behavior, Discord update branch, spellcheck languages, splash
  screen colors) — a different file at a different path
  (`~/.config/vesktop/settings.json`, not `.../settings/settings.json`),
  captured the same way.
- **Plain `{ enabled = false; }` plugin entries are omitted, not
  transcribed** — of the real machine's ~172 plugins, only 68 are kept
  (everything actually `enabled = true`, everything with non-default
  settings regardless of enabled state — e.g. `CustomIdle` and
  `NewGuildSettings` are both disabled but keep their non-default
  settings anyway, so those stick around if either is ever re-enabled
  through Vesktop's own UI — and the "*API" framework plugins kept
  explicit either way — see below). This is a verified
  no-op, not a guess: Vencord's own `src/api/Settings.ts`
  (`getDefaultValue`) resolves a *missing* plugin entry to
  `plugins[key].required || plugins[key].enabledByDefault || false` —
  i.e. `false` for any plugin not itself marked required/enabled-by-
  default in its own source. Checked Vencord's actual plugin source
  (not the docs) for every plugin with a static `required: true` or
  `enabledByDefault: true` — `DisableDeepLinks`, `BadgeAPI`,
  `CrashHandler`, `WebContextMenus`, `WebKeybinds`,
  `WebScreenShareFixes` — and every one of them is already `enabled =
  true` here, so the omission changes nothing observable. The "*API"
  plugins (`ChatInputButtonAPI`, `CommandsAPI`, ...) are kept explicit
  regardless — including the two disabled ones, `MessagePopoverAPI`/
  `ServerListAPI` — as a deliberate margin: they're framework plugins
  other plugins hook into, and nothing in Vencord's settings-resolution
  code rules out some *other* enabled plugin's dependency graph
  eventually mattering here, so keeping all twelve explicit costs
  little and removes the question entirely.
- **`programs.vesktop` / `programs.vesktop.vencord.settings`**, not
  hand-written `home.file` entries: home-manager grew a native module
  for this since this file was first written (confirmed present in the
  exact home-manager revision this flake already has locked before
  switching, not assumed from a newer one). It writes to the identical
  two paths this file always used
  (`~/.config/vesktop/settings.json` and
  `~/.config/vesktop/settings/settings.json`), so `vesktopSettings` and
  `vencordSettings // { plugins = vencordPlugins; }` slot straight into
  `settings`/`vencord.settings` with no restructuring. One real
  difference from the old `home.file … { force = true; }` approach: the
  native module doesn't force-overwrite, so a pre-existing *unmanaged*
  settings file from an earlier manual Vesktop launch (Vesktop rewrites
  these itself whenever a setting is toggled in its own UI, same
  in-app-change-until-next-rebuild trade-off as DMS's `settings.json` or
  Lutris's `runners/wine.yml`) could collide with home-manager's own
  file on the very first switch to this module — a one-time `rm` of
  those two files avoids it. Deliberately *not* using
  `programs.vesktop.vencord.extraQuickCss` for the CSS below - that
  writes a static file to the exact path matugen already regenerates
  live on every wallpaper change, so it stays as its own
  `home.file`/`vayori.matugenTemplates` entry, untouched by this
  migration.
- **QuickCSS + matugen**: the real machine's `settings/quickCss.css` was
  already a curated theme, not a blank slate — DiscordRecolor
  (mwittrien/BetterDiscordAddons), an `@import` plus a `:root` block of
  hardcoded `R,G,B` custom properties, plus a scrollbar-styling block.
  Rather than treat this like Spicetify/Starship (skip it entirely, too
  curated to touch) or like Heroic/Steam (drop in InioX's template
  as-is, no InioX Vesktop template exists anyway), the real file's
  *structure* is kept byte-for-byte in
  [Matugen.nix](desktop.md#modulesdesktopmatugennix) — same `@import`, same
  scrollbar rule and comments — and only the `:root` values it exposes
  for exactly this purpose are swapped from their original hardcoded
  triples to matugen ones. DiscordRecolor's variable contract doesn't
  map onto Material's roles 1:1 (it wants a 6-step text-brightness ramp
  and a 4-step background-elevation ramp; Material gives named semantic
  roles, not a ramp) — mapped by apparent intent: on_background →
  on_surface → on_surface_variant → outline → outline_variant →
  surface_container_highest for the text ramp (brightest to darkest),
  background/surface_container* for the background ramp
  (primary_container for the accent-tinted one, ascending surface
  containers for the rest). `--settingsicons` is a style-mode flag, not
  a color — left as the original's literal `0`. `quickCss.css` itself is
  deliberately *not* a `home.file` — matugen owns it outright, rewritten
  on every wallpaper change, same as every other app's matugen output in
  this repo; `useQuickCss = true;` in `vencordSettings` (already true on
  the real machine) is what makes Vesktop actually load it.

