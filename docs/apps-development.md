# Development apps reference

[← Back to index](CONFIGURATION.md)

---

## `modules/apps/development/editors/androidStudio/AndroidStudio.nix`

`adb` device access works out of the box (systemd 258+ handles uaccess
udev rules automatically) — `"adbusers"` in `extraGroups` is optional
compatibility, not required.

Plugins and editor settings are captured as they exist on the real
machine, pinned as Nix derivations rather than fetched live at
activation time:

- **17 real user-installed JetBrains plugins** (with every language app
  enabled, the default on this host - fewer if one is turned off), split
  across three sources:
  - `androidStudioAutoPlugins` (8, generic - Catppuccin Theme, the Claude
    Code plugin, git-worktree-manager, Discord integration, lsp4ij,
    One Dark theme, `vcs-perforce`, `vcs-svn`): resolved through
    `inputs.nix-jetbrains-plugins.plugins.<system>."android-studio".<build>.<xmlId>`
    (the [nix-community/nix-jetbrains-plugins](https://github.com/nix-community/nix-jetbrains-plugins)
    input), where `<build>` is `pkgs.androidStudioPackages.stable.version`
    read live, not hardcoded - so this only ever asks for plugins
    compatible with the *exact* installed build, confirmed to exist as a
    literal index key (`"2026.1.3.7"`) before relying on it. Solves what
    used to be a real gap: manually-pinned marketplace "latest" isn't
    necessarily compatible with the installed build at all, it's just
    whatever's newest overall.
  - **7 more, language-specific, sourced the same way but from
    [DevLanguages.nix](core.md#modulescoredevlanguagesnix)**: `Flutter.nix`
    contributes 4 (`Dart`, Flutter Enhancement Suite, `flutter-intellij`,
    `flutter-intl` - Dart and Flutter are one language toggle here, see
    that section), `Kotlin.nix` contributes `kmm-plugin` (Kotlin
    Multiplatform - Android Studio's own Kotlin support is already built
    in, this is just the one bit that isn't), `Nix.nix` contributes
    NixIDEA, `Python.nix` contributes `python-ce`. `AndroidStudio.nix`
    filters `self.devLanguages` down to whichever language apps are in
    `vayori.apps` and folds each one's `androidStudio.autoPlugins` into
    the same `allAutoPlugins` list the 8 generic ones are already in -
    turn a language off and its plugins disappear from this list on the
    next rebuild, nothing to edit here.
  - `androidStudioManualPluginsSpec` (2 holdouts - `WakaTime.jar` and
    `github-copilot-intellij`, both generic): still fetched the original
    way, via `pkgs.fetchurl` from
    `plugins.jetbrains.com/plugin/download?pluginId=<id>&version=<version>`
    with a pinned content hash. WakaTime isn't in the auto index at all.
    GitHub Copilot *is*, but its build there runs `autoPatchelf` against
    a bundled native Node addon and fails outright - missing
    `libsecret`/`libglib`/`libX11`/`libpipewire`/`libei`/etc, a real
    build failure hit while migrating, not a guess - so it stays on the
    plain `fetchurl`+`unzip` path that never touches `autoPatchelf` and
    has always worked.
  - `flake.pluginPins.AndroidStudio` only exposes these 2 manual
    holdouts (plus any future language module's own `manualPlugins`,
    though none currently has one) - the 15 auto-tracked ones don't need
    [PluginUpdateCheck.nix](core.md#modulescorepluginupdatechecknix) watching
    them; they update whenever the `nix-jetbrains-plugins` input does.
  - Plugin ids and versions originally came straight from each installed
    plugin's own `META-INF/plugin.xml`; the marketplace download
    endpoint accepts the plugin's own XML id string directly, no numeric
    marketplace id needed. Bundled/built-in components (e.g.
    `marketplace`, `vcs-hg`) were excluded by cross-referencing the real
    install's own `bundled_plugins.txt`.
- **`pkgs.jetbrains.plugins.addPlugins` does not work here** — it assumes
  a plain (non-FHS) IDE layout with `plugins/` nested under
  `$out/<mainProgram>/`. `pkgs.androidStudioPackages.stable` is an
  FHS-wrapped launcher script derivation — the real IDE lives in a
  separate `unwrapped` derivation reached only via runtime closure, so
  that `plugins/` path never exists inside the wrapper's own `$out` and
  `addPlugins`' build step fails outright. Confirmed by a real failed
  build, not assumed.
- Instead, each plugin is placed with `home.file` directly into
  `~/.local/share/Google/<dataDirectoryName>/<real-plugin-dir-name>` —
  the same *user* plugins directory the IDE itself reads at startup when
  you install a plugin through Settings → Plugins, entirely separate
  from the read-only IDE installation. This sidesteps the FHS-wrapping
  problem completely and needed zero changes to the stock
  `androidStudioPackages.stable` package. Verified against the real
  machine's own `~/.local/share/Google/AndroidStudio2026.1.2/` — every
  directory/jar name here (`Catppuccin Theme`, `flutter-intellij`,
  `WakaTime.jar`, etc.) matches exactly.
- `<dataDirectoryName>` (`AndroidStudio2026.1.3`) is read out of the
  nixpkgs-built package's own `product-info.json`, not guessed from the
  package version string — the real machine's installed build
  (`2026.1.2`) and the pinned nixpkgs build (`2026.1.3.7`) don't share a
  version, and `product-info.json` is the only ground truth for which
  config directory an IDE build actually reads.
- The 5 XML files under `.config/Google/<dataDirectoryName>/options/`
  (font, LAF, color scheme, One Dark config, Vim emulation) are a
  straight transcription of the real machine's own files at that path.
- **Matugen-driven editor color scheme** (`DankMatugen`, replacing the
  static "One Dark" default): registers a `[templates.androidStudio]`
  block in `vayori.matugenTemplates` — DMS's own documented custom-
  template mechanism, assembled in
  [Baseline.nix](desktop.md#modulesdesktopbaselinenix) — since DMS has no built-in
  JetBrains/Android Studio matugen integration at all, this is a
  from-scratch template. The `.icls` body itself is a shared, public
  value (`self.matugenTemplates.androidStudio matugenSchemeName`, a
  function of the scheme name — see
  [Matugen.nix](desktop.md#modulesdesktopmatugennix)), not inlined here. The
  generated `.icls` file itself is deliberately *not* declared as a
  `home.file` — matugen writes `matugenOutputPath` itself at runtime, on
  every wallpaper change, and home-manager would just fight it for
  ownership of that file otherwise.
- **`androidStudioWithFcc`**: `androidStudioPackages.stable` wrapped
  (`pkgs.symlinkJoin` + `makeWrapper`) to `--set` the
  [Free Claude Code](#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix)
  `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN` env vars on the real
  `android-studio` binary specifically, not system-wide. Confirmed by
  inspecting the built wrapper directly: it exports the vars then
  `exec -a`s the real (renamed) binary, and the package's own
  `.desktop` entry references it by bare name (`Exec=android-studio`),
  so both the app launcher and a direct terminal launch resolve to this
  wrapped version via `PATH` — no separate desktop-file patching
  needed. `home.packages` uses this wrapped derivation in place of the
  raw `androidStudioPackages.stable`.

---

## `modules/apps/development/editors/vscode/Vscode.nix`

`programs.vscode.profiles.default` (`userSettings`, `keybindings`,
`extensions`), the current home-manager schema — not the older flat
`programs.vscode.userSettings` shape. Settings, the one custom
keybinding (`ctrl+y` unbound from `editor.action.deleteLines`), and every
extension are a direct transcription of the real `~/.config/Code/User/`
on this machine, not a live importer - but as of
[DevLanguages.nix](core.md#modulescoredevlanguagesnix), split between generic
ones declared right here and language-specific ones this file only
aggregates:

- `nixpkgsExtensions`/`vscodeAutoExtensions` here are the **generic**
  ones only - nothing tied to a specific language. `nixpkgsExtensions`:
  pre-packaged in `pkgs.vscode-extensions`. `vscodeAutoExtensions`:
  resolved through `pkgs.vscode-marketplace.<publisher>.<name>`, the
  overlay from the
  [nix-community/nix-vscode-extensions](https://github.com/nix-community/nix-vscode-extensions)
  input (`nixpkgs.overlays` in
  [Host.nix](core.md#moduleshostsnamehostnix)) - daily-refreshed, no hash to
  compute by hand; its tracked "latest" can lag the true Marketplace
  latest by a version, since it's a daily heuristic scrape, not strict
  semver - a real but minor tradeoff against never having a hash to bump
  manually again.
- **Every language-specific extension lives in
  `modules/apps/development/languages/*/*.nix` instead** (C/C++'s
  `cpptools`, Rust's `rust-analyzer`, Kotlin's `fwcd.kotlin` +
  `mathiasfrohlich.kotlin` + Gradle support, Dart's and Flutter's own
  extensions, Nix's `nix-ide` + `nix-forge`, Qt's `qt-core`/`qt-qml`,
  Python's `ms-python.*` + Pylance).
  This file's home-manager module filters `self.devLanguages` down to
  whichever language apps are actually in `vayori.apps`
  (`enabledLanguages`), then folds each one's `vscode.nixpkgsExtensions`/
  `.marketplaceExtensions`/`.manualExtensions`/`.settings` into its own
  lists/`vscodeSettings` before building `programs.vscode`. A
  `nixpkgsExtensions` entry here is a dotted string
  (`"rust-lang.rust-analyzer"`) rather than a direct `pkgs.vscode-
  extensions.rust-lang.rust-analyzer` reference, resolved via
  `lib.attrByPath (lib.splitString "." dotted) (throw "...")
  pkgs.vscode-extensions` - language modules don't have `pkgs` in scope
  when they publish this data (flake-level, evaluated once, not per
  system), only this file's own per-system module does.
- The one remaining manual (fetchurl-pinned) extension -
  `boundarystudio.cpp-extentions-pack` - moved with the rest of C/C++'s
  extensions into `Cpp.nix`'s `flake.devLanguages.Cpp.vscode
  .manualExtensions`, not in this file's own `let` anymore. It's still
  not on the nix-vscode-extensions index (checked, not assumed), so it
  stays on the original mechanism -
  `pkgs.vscode-utils.extensionsFromVscodeMarketplace`, pinned to
  `{ name, publisher, version, hash }` with a content hash from `nix
  store prefetch-file` against the Marketplace's VSIX asset URL. This
  file aggregates every enabled language's `manualExtensions` back into
  `flake.pluginPins.Vscode` itself (see the note in
  [PluginUpdateCheck.nix](core.md#modulescorepluginupdatechecknix) for why it
  has to stay under this one key rather than a per-language one) - so
  it's still the only one exposed there today; every
  nix-vscode-extensions-sourced one doesn't need
  [PluginUpdateCheck.nix](core.md#modulescorepluginupdatechecknix) to watch it
  at all.

VSCode itself moved out of `DevTools.nix` into its own module once it
needed this much dedicated configuration — `DevTools.nix` keeps only
`gh`, `lazygit`, `docker-compose`.

- **The DMS theme extension (`DankLinux.dms-theme`) is installed as a
  real, writable copy via `home.activation`, not through
  `programs.vscode.profiles.default.extensions`**: DMS bundles this vsix
  itself (`matugenTemplateVscode = true`, in
  [Dms.nix](desktop.md#modulesdesktopdmsnix)) and rewrites its `themes/*.json` on
  every wallpaper change (`appendVSCodeConfig` in
  `core/internal/matugen/matugen.go` writes straight into the installed
  extension's own directory) — but DMS never installs the vsix itself,
  only keeps an already-installed copy's theme files updated
  (`checkVSCodeExtension` there is purely a detection/UI check, confirmed
  by reading the source). The standard `extensions` list can't be used
  for it either: that symlinks straight into the read-only `/nix/store`,
  so matugen's writes would fail — hence the real copy instead, version
  tracked against DMS's own `vsix-build/package.json`.
- **The installed directory name must be lowercase
  `danklinux.dms-theme-<version>`**, even though the vsix's own
  `package.json` declares `"publisher": "DankLinux"` —
  `appendVSCodeConfig` globs for `extBaseDir/danklinux.dms-theme-*`
  verbatim (matching VSCode's own real `code --install-extension`
  convention of lowercasing the publisher for the on-disk id). Confirmed
  by booting this in a real VM: the capitalized version silently never
  matched, so matugen's write never actually ran — the theme file just
  held the vsix's own static bundled default the whole time, not a
  live-updated one.
- **One Dark syntax highlighting, layered on top of the matugen theme,
  not switched to instead of it**: `workbench.colorTheme` stays
  `"Dynamic Base16 DankShell"` (the matugen-driven theme above) - the
  general UI (sidebar, tabs, status bar, ...) keeps following the
  current wallpaper. `editor.tokenColorCustomizations.textMateRules`
  and `editor.semanticTokenColorCustomizations` are VS Code's
  documented mechanism for overriding *just* syntax highlighting on top
  of whatever theme is active, regardless of which one - so both are
  set to the real `tokenColors`/`semanticTokenColors` read directly out
  of the already-packaged `mskelton.one-dark-theme` extension's own
  `themes/one-dark.json` (not hand-picked or approximated), giving real
  One Dark syntax colors while the rest of the editor still tracks
  matugen. The pre-existing italic-comment rule is kept alongside One
  Dark's own (non-italic) comment color rule for the same scope - VS
  Code merges multiple rules matching the same scope rather than the
  later one replacing the earlier one outright, so comments end up both
  colored and italic, matching original intent plus the added color.

---

## `modules/apps/development/editors/zed/Zed.nix`

`programs.zed-editor` (home-manager's native module) — `extensions` and
`userSettings`, a direct transcription of the real `~/.config/zed/` on
this machine (both the installed-extensions list and `settings.json`),
split generic-vs-language-specific the same way as
[Vscode.nix](#modulesappsdevelopmenteditorsvscodevscodenix), one commit
after Vscode/AndroidStudio had already gone through this split - so this
file only ever had to *aggregate*
[DevLanguages.nix](core.md#modulescoredevlanguagesnix) contributions, never carry
language-specific settings of its own to begin with.

- **Extensions are just names, not files or hashes** — unlike VS Code's
  marketplace extensions (fetched and pinned as Nix derivations) or
  Android Studio's plugins (same), `programs.zed-editor.extensions`
  becomes Zed's own `auto_install_extensions` setting, and Zed resolves
  and downloads each one itself at its *own* next startup. Nix's only
  job here is writing the list of names - there's nothing to pin, hash,
  or feed to [PluginUpdateCheck.nix](core.md#modulescorepluginupdatechecknix)
  (see the note in that section for why Zed isn't one of the three
  editors it watches).
- **`mutableUserSettings` is left at its default (`true`)** — Zed's
  activation script merges this file's declared settings on top of
  whatever's already in `~/.config/zed/settings.json` (`jq '$dynamic *
  $static'`, confirmed by reading the real generated activation script)
  rather than replacing the file outright the way VSCode's `force`-style
  writes do. Declared settings still win on every rebuild; the file just
  stays a normal editable file in between, matching how Zed itself
  expects to be able to write to it (e.g. from its own settings UI).
- **The real `~/.config/zed/settings.json`'s WakaTime API key is
  deliberately NOT in this file** — `lsp.wakatime.initialization_options
  .api-key` held a live, real key in the source config; committing it
  here would mean shipping a real credential in a public git repo. Left
  out entirely rather than pinned/redacted, with a comment at the
  omission site pointing at the two real alternatives (set it locally
  through Zed's own settings, or wire it through a proper secrets
  mechanism like sops-nix/agenix if it needs to be declarative).
- **`ui_font_family`/`buffer_font_family` use `vayoriTheme.font`**, not
  the real config's literal `"JetBrains Mono"` — same reasoning as
  [Vscode.nix](#modulesappsdevelopmenteditorsvscodevscodenix)'s
  `editor.fontFamily`: every app's font should track the one shared
  `vayori.theme.font` setting, not carry its own independent copy of the
  font name that'd drift the next time that setting changes.
- **Kotlin's Zed contribution pulls in `java` and `groovy` alongside
  `kotlin`** — real Kotlin/Android projects mix in Java interop files and
  Groovy Gradle build scripts often enough that gating them independently
  would just mean two more toggles that are, in practice, always flipped
  together with Kotlin. Its settings block
  (`lsp.kotlin-language-server.settings.compiler.jvm.target`,
  `languages.Kotlin.language_servers`) is the one real case where
  [DevLanguages.nix](core.md#modulescoredevlanguagesnix)'s note about
  `lib.recursiveUpdate` vs. `//` matters in practice today.
- **`Cpp`'s only Zed extension is `neocmake`** — Zed ships C/C++ (clangd)
  support natively, so unlike VSCode there's no `cpptools`-equivalent
  extension to install; CMake project-file support is the one real gap
  it fills in.
- **`Rust` and `Python` have no Zed extension at all** — same reasoning
  as C/C++: Zed bundles both natively (rust-analyzer, and a Pyright-based
  Python language server). `flake.devLanguages.Rust`/`.Python` simply have
  no `zed` key, and `Zed.nix`'s `l.zed or { }` handles that the same way
  it handles any other language not contributing a `zed` block.
- **`arduino` was in the real installed-extensions list but is dropped
  here on request** — along with the `lsp.arduino-language-server`
  settings block it needed, since nothing here actually uses it.
- **Zed gets a real matugen-driven theme, not a static one** — the real
  config's `{mode: "system", light: "Ayu Light", dark: "One Dark Pro
  Night Flat"}` becomes a single `theme = "Matugen"` string instead (see
  `vayori.matugenTemplates.zed`, registered right below
  `programs.zed-editor` in this file, output to
  `~/.config/zed/themes/matugen.json`). The template itself is
  [Matugen.nix](desktop.md#modulesdesktopmatugennix)'s `zed` entry - unlike every
  other app's matugen template here, it wasn't ported from an existing
  static theme or community source; it's hand-authored directly against
  Zed's own published theme schema
  (`https://zed.dev/schema/themes/v0.2.0.json`, fetched and checked
  against, not guessed at) since `ThemeStyleContent` there has zero
  required keys - it sets the ~140 keys that cover the visible surface
  (editor, panels, terminal, git status colors, 19 syntax-highlighting
  scopes) and lets Zed fall back to its own defaults for the rest.
  Verified by rendering the actual built template with dummy colors
  substituted for every `{{ }}` placeholder and checking the result is
  valid JSON with every key present in the real schema's property list -
  not something a GUI app running headless could otherwise be confirmed
  against in this environment.

---

## `modules/apps/development/languages/*/*.nix`

Seven independent `vayori.apps` toggles, each installing one language's own
LSP/toolchain and telling the editors above what to install for it - see
[DevLanguages.nix](core.md#modulescoredevlanguagesnix) for the mechanism. All
seven are enabled on this host today - confirmed with a real build, not
just individually: every one flipped off *at once*, rebuilt, and each
editor's extension/plugin list dropped to exactly its generic set (VSCode
50→21, Android Studio 17→10, Zed 16→8) with zero language packages left
on `$PATH`, then flipped back on and rebuilt clean again.

| App | Packages | VSCode extension(s) | Android Studio | Zed |
| --- | --- | --- | --- | --- |
| `Cpp` | `clang-tools` (clangd + clang-format), `cmake`, `gdb` | `ms-vscode.cpptools`(-extension-pack), `cmake-tools`, `twxs.cmake`, `vadimcn.vscode-lldb`, `boundarystudio.cpp-extentions-pack` (manual) + 3 marketplace | - | `neocmake` |
| `Rust` | `rustc`, `cargo`, `rust-analyzer`, `rustfmt`, `clippy` | `rust-lang.rust-analyzer` | - | - (bundled) |
| `Kotlin` | `kotlin`, `kotlin-language-server` | `mathiasfrohlich.kotlin`, `vscjava.vscode-gradle` + `fwcd.kotlin`/`esafirm.kotlin-formatter`/`naco-siren.gradle-language` (marketplace) | `kmm-plugin` (Kotlin Multiplatform - regular Kotlin support is already built in) | `kotlin`, `java`, `groovy` + JVM target/language-server settings |
| `Flutter` | `flutter` (bundles its own Dart SDK - covers Dart too, see below) | `dart-code.dart-code` + `dart-code.flutter` | `Dart`, Flutter Enhancement Suite, `flutter-intellij`, `flutter-intl` | `dart`, `flutter-snippets` |
| `Nix` | `nil`, `nixfmt` | `jnoortheen.nix-ide`, `arrterian.nix-env-selector` + `ziyyun.nix-forge`/`pinage404.nix-extension-pack` (marketplace) | NixIDEA | `nix` |
| `Qt` | `kdePackages.qtdeclarative` (qmlls) | `theqtcompany.qt-core`/`qt-qml` (marketplace) | - | `qml` |
| `Python` | `python3` | `ms-python.python`/`vscode-pylance`/`debugpy`/`vscode-python-envs` + `kevinrose.vsc-python-indent`/`njqdev.vscode-python-typehint` (marketplace) | `python-ce` | - (bundled) |

- **`fwcd.kotlin` is a marketplace extension, not a `pkgs.vscode-
  extensions` one** - nixpkgs' own curated set only has
  `mathiasfrohlich`'s Kotlin extension. Caught by the `throw` in
  `Vscode.nix`'s dotted-string resolver failing a real build - not
  something documentation or a search would have surfaced, since
  `mathiasfrohlich.kotlin` (a similarly-named, actually-present
  extension) made the mistake easy to make.
- **`Flutter` is Dart too - one toggle, not two** - see the note in
  [Zed.nix](#modulesappsdevelopmenteditorszedzednix)'s section above for
  the two real reasons (bundled SDK, always used together in practice).
  A real build failure surfaced a second, sharper reason while these were
  still separate modules: `pkgs.dart` and `pkgs.flutter` both ship a
  top-level `version` file, and having both in the same `home.packages`
  broke `home-manager`'s `buildEnv` outright (`pkgs.buildEnv error: two
  given paths contain a conflicting subpath`) - not a style preference,
  a genuine conflict that merging them into one toggle sidesteps
  entirely rather than working around.
- **`Cpp` and `C` are one toggle, not two** - there's no extension or
  language-server story in this repo that treats plain C differently
  from C++ (`cpptools`, `clangd`, and `clang-format` all handle both), so
  splitting them would just be two toggles that always get enabled
  together in practice.
- **`Python`'s only real package is the interpreter itself** - Pylance
  (VSCode), `python-ce` (Android Studio), and Zed's own bundled Pyright
  all do their own analysis without a separate LSP binary on `$PATH`, so
  `pkgs.python3` is the one thing actually missing without this toggle.
  `github.copilot.enable.python = false` in `Vscode.nix`'s generic
  settings is left alone regardless - it's Copilot config, not gated on
  any extension actually being installed (Copilot itself isn't, see that
  section), same as its `cpp`/`html`/`css`/etc. siblings.
- **`pkgs.python314` already shows up on `$PATH` even with `Python`
  disabled** - not a bug in this toggle, confirmed while negative-testing
  it: [FreeClaudeCode.nix](#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix)
  installs it unconditionally for its own `uv sync` setup step, entirely
  independent of this language toggle. Both can be true at once - `Python`
  off still means no Pylance/`python-ce`/Python-specific settings in any
  editor, it just doesn't mean "no Python interpreter anywhere on this
  machine" as long as FreeClaudeCode is also enabled.
- **`Nix.nix`'s `nil`/`nixfmt` packages overlap with `Host.nix`'s
  system-wide `environment.systemPackages`** (installed there for
  root/system-level editing, independent of any user's `vayori.apps`) -
  deliberately left as-is rather than deduplicated, since the Nix store
  dedups the actual derivation either way and the two lists serve
  different scopes (system vs. per-user).

---

## `modules/apps/development/devTools/DevTools.nix`

`git` isn't listed here — it's already in `environment.systemPackages`
(`Host.nix`), since flakes need it system-wide regardless of which apps
are picked.

---

## `modules/apps/development/freeClaudeCode/FreeClaudeCode.nix`

Wires [Free Claude Code](https://github.com/Alishahryar1/free-claude-code)
(FCC) — a local proxy that lets Claude Code's CLI/extensions talk to
non-Anthropic model providers (NVIDIA NIM by default, matching upstream's
own documented Quick Start) instead of Anthropic's API — into the CLI,
the already-installed VS Code extension
([Vscode.nix](#modulesappsdevelopmenteditorsvscodevscodenix)), and Android Studio's
already-installed plugin
([AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)).

- **Not a from-scratch Nix derivation, deliberately**: FCC requires
  Python 3.14+ and pulls in ~20 dependencies (several, like `httpx2` and
  `nvidia-riva-client`, aren't packaged in nixpkgs), and moves fast
  enough that hash-pinning the whole closure would need constant
  upkeep. Instead: `pkgs.uv` is installed declaratively, and the actual
  `git clone`/`uv sync` work happens in its own
  `systemd.user.services.free-claude-code-bootstrap` (`Type = "oneshot"`) —
  `uv` manages the Python interpreter itself, nothing extra needed in
  `home.packages` for that. Same trade-off already made for Zen
  Browser's mods/profile fetch
  ([ZenBrowser.nix](apps-utils.md#modulesappsutilszenbrowserzenbrowsernix)) — a real
  network dependency for something too fast-moving to fully pin, not
  the norm elsewhere in this repo.
- **The bootstrap unit is deliberately *not* run inline in
  `home.activation`** — it was, originally, and that was a real bug:
  `uv sync` downloading Python 3.14 plus ~20 packages ran synchronously
  inside `home-manager-ash.service` itself, so the entire rebuild
  blocked on it (and, on a slow link, could run past home-manager's own
  default 5-minute activation timeout and kill the *whole* activation,
  not just this one app). Confirmed live: `home-manager-ash.service`
  hit exactly that "Read-only file system"-adjacent failure mode in
  testing. Fixed by moving the heavy work to
  `free-claude-code-bootstrap.service` and having
  `home.activation.freeClaudeCodeSetup` only kick it off with
  `systemctl --user --no-block restart free-claude-code.service` —
  activation returns immediately regardless of how long the clone/sync
  takes. `free-claude-code.service` declares
  `Wants`/`After = free-claude-code-bootstrap.service`, so starting the
  server always waits for a real, finished sync first, whether that
  start comes from activation's non-blocking kick or from
  `WantedBy = default.target` on a later login.
- **`fcc-server` runs as a `systemd.user` service**
  (`free-claude-code.service`, `WantedBy = [ "default.target" ]`), not
  launched manually — `ExecStart` points straight at the venv `uv sync`
  creates (`.venv/bin/fcc-server` inside the cloned repo).
  `Restart = "on-failure"` / `RestartSec = 10` / a 20-attempt,
  5-minute `StartLimit` window are deliberately generous — a leftover
  safety net from before the bootstrap split, kept because it's cheap
  insurance against any future slow first start.
- **`core/Users.nix`'s `home-manager-<name>.service` gets
  `TimeoutStartSec = lib.mkForce "30sec"`** — home-manager's own module
  defaults this to 5 minutes; it was first bumped up to `"10min"` here
  as a general safety margin for any slow synchronous activation step
  (Papirus's icon copy on a slow filesystem, say), then tightened back
  down to `"30sec"`. A live VM test of that `"30sec"` value showed
  activation getting killed by `Result: timeout` around 24 seconds in,
  before several steps (including ZenBrowser's) even ran - so on a slow
  first activation this value can genuinely cut work off short. Worth
  revisiting if a rebuild ever ends with a `home-manager-<name>.service`
  timeout in the logs.
- **`~/.fcc/.env` is seeded once, never overwritten** — confirmed
  against FCC's own source (`config/paths.py`, `managed_env_path()`)
  that this exact path, not the cloned repo's own `.env`, is what the
  running server actually reads its live config from and what its
  Admin UI writes provider keys back into. Force-declaring this file
  the way Vesktop's settings are would fight the Admin UI for ownership
  and wipe out a pasted-in API key on every rebuild, so it's only
  written if absent (`[ -f ... ] || cp ...`), same idempotent-seed
  pattern as Baseline.nix's Papirus icon copy. The seed sets
  `MODEL`/`PROXY_AUTH_ENABLED`/`ANTHROPIC_AUTH_TOKEN`/
  `FCC_OPEN_BROWSER=false` (no point popping a browser tab from a
  background service) and leaves `NVIDIA_NIM_API_KEY` commented out —
  getting one is a manual step by necessity (an API key can't be
  generated by this repo, and wouldn't belong committed to it even if
  it could) — build one free at
  [build.nvidia.com/settings/api-keys](https://build.nvidia.com/settings/api-keys)
  and either paste it into that line or set it through FCC's own Admin
  UI. Any other provider `.env.example` documents works too; NVIDIA NIM
  is just upstream's own default, not a hardcoded requirement.
- **`~/.claude.json`'s `hasCompletedOnboarding: true`**: documented by
  upstream as the fix for Claude Code still prompting a real Anthropic
  login even after the FCC URL/token are set. Merged in via `jq`, not a
  plain `home.file`, because this file is Claude Code's own real state
  (auth, project history) — a full overwrite would either destroy that
  or fight the CLI for ownership of a file it writes to constantly.
  Idempotent either way: creates `{}` first if the file doesn't exist
  yet, then merges the one key in on every rebuild without touching
  anything else already there.
- **`~/.jetbrains/acp.json`**: same reasoning, `jq`-merged rather than
  declared — this is JetBrains' own IDE-wide registry of external ACP
  (Agent Client Protocol) agents, potentially listing other agents
  entirely unrelated to Claude. The merge only ever touches
  `.acp.registry."claude-acp".env`, additively (`(existing // {}) +
  new`), so it can't clobber another registered agent or wipe fields
  the IDE itself puts on this same entry when Claude ACP is first
  enabled. Verified this merge behaves correctly both against an empty
  file and one with unrelated pre-existing content, not just assumed.
- **The JetBrains ACP registry patch here targets JetBrains' generic ACP
  mechanism, not necessarily the already-installed
  `com.anthropic.code.plugin` itself** (Anthropic's own dedicated
  JetBrains plugin) — upstream's README only documents the ACP path for
  JetBrains IDEs, and whether that dedicated plugin *also* reads the
  same `ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN` env vars from ACP's
  registry is genuinely unverified. Android Studio itself is covered a
  different, more direct way instead - see below.
- **`androidStudioWithFcc`** (in
  [AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)): the
  real fix for Android Studio specifically. `pkgs.symlinkJoin` +
  `makeWrapper` wraps the real `android-studio` binary, `--set`-ing the
  same FCC env vars VS Code's extension gets, scoped to Android Studio's
  own process tree only - the `.desktop` entry references the binary by
  bare name (`Exec=android-studio`), so both the app launcher and a
  direct terminal invocation resolve to the wrapped version via `PATH`,
  confirmed by inspecting the built wrapper script directly. This is
  more reliable than the ACP patch above: whatever the Claude Code
  JetBrains plugin spawns as a subprocess inherits Android Studio's own
  process environment by plain OS process inheritance, regardless of
  which specific mechanism the plugin uses internally to read its
  config - no dependency on ACP being the right registration point at
  all.
- **Deliberately not wired system-wide**: `ANTHROPIC_BASE_URL`/
  `ANTHROPIC_AUTH_TOKEN` are set only inside VS Code's own
  `claudeCode.environmentVariables`, the JetBrains ACP registry, and now
  Android Studio's own wrapped binary - never as a `home.sessionVariables`
  entry. Doing that would redirect *every* terminal's `claude` invocation
  through FCC too, silently breaking real authenticated Claude Code CLI
  usage anywhere else it's used. `fcc-claude` (FCC's own launcher, installed alongside
  `fcc-server`) is the deliberate opt-in path for terminal use instead
  — it sets these env vars only for itself, leaving the real `claude`
  binary untouched.
- **Only Claude Code is wired up** — FCC's own installer also offers
  Codex, Pi, OpenCode, Cline, Hermes, DeepSeek Harness, Grok, Muse, and
  Aider, each with their own third-party installer script it'd run by
  default. None of that runs here; only `fcc-server`'s own dependencies
  get installed.
- **The connection info (`baseUrl`, `authToken`, and the full client env
  var set) is published once as `flake.freeClaudeCode`**, not
  hardcoded separately in this file, `Vscode.nix`, and
  `AndroidStudio.nix` — it used to be, three copies of the same
  `localhost:8082`/`"freecc"` pair. Real bug that shape had: removing
  `"FreeClaudeCode"` from `vayori.apps` left VS Code's
  `claudeCode.environmentVariables` and Android Studio's wrapped binary
  still pointing at a proxy that was never started - no build error,
  just a Claude Code integration that silently tries to talk to a dead
  `localhost:8082` instead of falling back to the real Anthropic API.
  Fixed two ways together: the constants moved to one place
  (`self.freeClaudeCode`, same public-data pattern as
  `flake.matugenTemplates`/`flake.pluginPins`), and both consumers now
  gate the FCC-specific settings behind `builtins.elem "FreeClaudeCode"
  vayoriApps` - VS Code drops `claudeCode.environmentVariables`/
  `disableLoginPrompt` entirely (keeping `claudeCode.preferredLocation`,
  which doesn't depend on FCC) and Android Studio falls back to the
  plain unwrapped `androidStudioPackages.stable` package. `vayoriApps`
  is `config.vayori.apps` from the NixOS-level option, threaded into
  home-manager via `home-manager.extraSpecialArgs` in
  [core/Users.nix](core.md#modulescoreusersnix) - the same plumbing any other
  app can use to react to which sibling apps are actually enabled.
  Verified both ways: built the toplevel/activation packages with FCC
  enabled (identical output to before), then evaluated again with
  `"FreeClaudeCode"` and `"ZenBrowser"` stripped from `vayori.apps` and
  confirmed `claudeCode.environmentVariables` disappears from VS Code's
  settings and the Android Studio package resolves to the plain
  `android-studio-*` derivation, not the FCC-wrapped one.
- **`AndroidStudio.nix`'s `CHROME_EXECUTABLE = "zen"` has the same
  fix, same reason**: it only gets set when `"ZenBrowser"` is actually
  in `vayori.apps` (`lib.optionalAttrs`), since it names a binary that
  doesn't exist otherwise. A repo-wide scan for this pattern (any app
  module hardcoding another app's binary name, URL, or port) turned up
  exactly these two couplings - Zen's own `zenExtensions` list has a
  "Bitwarden Password Manager" entry too, but that's a *browser
  add-on* pinned inside `ZenBrowser.nix` itself, unrelated to the
  separate standalone `Bitwarden.nix` app; not a real coupling.

