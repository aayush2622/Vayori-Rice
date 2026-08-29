# Core & hosts reference

[← Back to index](CONFIGURATION.md)

---

## `modules/hosts/<name>/Host.nix`

**`vayori.theme`** is a submodule option declared inline here (not in a
shared file like `vayori.users`/`vayori.apps` — it's a per-host preference,
and this repo only has one host), with sane defaults baked in (JetBrainsMono
Nerd Font, Bibata-Modern-Ice, Tela-circle). Override one field without
redeclaring the rest: `vayori.theme.font = "Fira Code";` changes it
everywhere at once — fontconfig, GTK, kitty, DMS all read the same option.

NixOS modules read `config.vayori.theme.*` directly, like any option.
Home-manager modules can't — they're a separate module instantiation that
never sees the parent NixOS `config` — so `Users.nix` re-exports it via
`home-manager.extraSpecialArgs = { vayoriTheme = config.vayori.theme; };`.

Not wired to `vayori.theme`: the SDDM greeter's bundled font and GRUB's
theme package — see [Fonts.nix / Portals.nix](desktop.md#modulesdesktopfontsnix--portalsnix).

**Two Nix gotchas hit while building this file:**

1. A module can't mix `options.x = ...` with implicit top-level config keys.
   Once `options.vayori.theme` is declared, everything else has to move
   under `config = { ... };`, or NixOS throws `unsupported attribute 'boot'`.
2. An inline lambda module right after a `path` list element parses as
   function application, not two list items:

   ```nix
   modules = [
     ./_hardware.nix
     { pkgs, ... }: { ... }   # BROKEN — parses as `./_hardware.nix { pkgs, ... }`
   ];
   ```

   Fix: wrap it in parens — `({ pkgs, ... }: { ... })`.

**Build/closure**: `nix.settings.auto-optimise-store = true` hardlinks
identical files across store paths. `documentation.nixos.enable = false`
skips building the local NixOS manual (`man configuration.nix` and
`nixos-option` still work). `nix.gc = { automatic = true; dates =
"weekly"; options = "--delete-older-than 30d"; };` runs garbage
collection on a schedule — without this, `/nix/store` only ever grows;
old generations older than 30 days get collected weekly instead of
needing a manual `nix-collect-garbage -d`.

**SDDM login-screen cursor** — three independent gaps, each confirmed
against source, not guessed:

1. SDDM's Wayland greeter runs under Weston as its own systemd service
   (`display-manager.service`), so it never sees
   `environment.sessionVariables` (PAM-only, post-login). Fix:
   `systemd.services.display-manager.environment` sets the same vars
   directly for Weston.
2. Weston itself doesn't guarantee those vars reach the greeter *client*.
   Per SDDM's own source (`Backend.cpp`), it re-applies
   `services.displayManager.sddm.settings.General.GreeterEnvironment` (a
   comma-separated `VAR=value` string — not the usual attrset shape) on top
   of whatever the greeter would inherit.
3. NixOS isn't FHS — `/usr/share/icons` doesn't exist, so Xcursor's default
   search path finds nothing. `XCURSOR_PATH` is set explicitly to
   `${cursorPackage}/share/icons`. That package also needs to be in
   `environment.systemPackages` — SDDM runs before any user session exists.

*Caveat*: QEMU's `screendump` doesn't reliably capture hardware cursor
planes, so a screenshot not showing a cursor isn't proof it's still broken
on real output.

**Apps** (`vayori.apps`): pick from file names under `modules/apps/` — the
one setting most new machines actually need to change. Written here as
`{ development = [...]; gaming = [...]; utils = [...]; }`, flattened with
`lib.flatten (lib.attrValues appsByCategory)` before being assigned - the
option itself (`core/Users.nix`) only ever sees the flat list this
produces, so the grouping is a call-site convenience, not part of the
option's type. Every category is a plain list, so a language toggle
(`"Rust"`, `"Flutter"`, ...) sits inside `development` right alongside the
editors that read it.

**`programs.steam.enable = true`** lives here, not in
[Gaming.nix](apps-gaming.md#modulesappsgaminggamingnix) — see that section for why.

**Users** (`vayori.users`): one entry per real account — see
[core/Users.nix](#modulescoreusersnix) for field meanings. Generate a
password hash with `mkpasswd -m sha-512`.

---

## `modules/hosts/<name>/_hardware.nix`

Unlike everything else under `modules/`, this is a **plain NixOS module** —
no `flake.nixosModules.X` wrapper. The leading `_` makes import-tree skip
it, so it's only reachable via `Host.nix`'s `./_hardware.nix` import (a raw
NixOS module's top-level keys like `boot`/`fileSystems` aren't valid
flake-parts options on their own).

To generate one for a different machine:

```bash
sudo nixos-generate-config --show-hardware-config > modules/hosts/<name>/_hardware.nix
```

Then drop the Nvidia/Optimus block entirely unless you also have an Nvidia
Optimus laptop — `intelBusId`/`nvidiaBusId` are this machine's PCI
addresses (`lspci` for yours).

**Nvidia block:**
- `powerManagement.enable`/`finegrained` — lets the dGPU fully power down
  via PRIME offload when idle, instead of draining battery while unused.
- `open = false` — the RTX 3050 (Ampere) supports the open kernel module,
  but closed is the safer default.
- `prime.offload` — iGPU drives the display; dGPU spins up only for apps
  launched via `nvidia-offload <cmd>`. For "dGPU renders everything,
  always on" instead, use `prime.sync.enable = true` and drop the
  `powerManagement` lines.

**`services.asusd` and `services.supergfxd` are separate daemons**, despite
both living under `nixos/modules/services/hardware/`. `asusd` (`asusctl`)
handles keyboard LEDs/fan curves/battery limits — **it does not touch GPU
switching**. GPU mux switching (Integrated/Hybrid/dGPU) is `supergfxctl`,
gated behind its own `services.supergfxd.enable`. Enabling only `asusd`
leaves `supergfxd` never running, so nothing ever mux-switches back to
Hybrid — the dGPU can stay powered off indefinitely, indistinguishable from
a real driver failure.

- **`services.supergfxd.settings` is deliberately left unset** - it used
  to declare `{ mode = "Hybrid"; }`, which sounded like a reasonable way
  to make the mode declarative instead of a one-time `supergfxctl -m
  Hybrid` you'd have to remember on every install, but it's a real bug:
  `nixos/modules/services/hardware/supergfxd.nix` writes `settings` (when
  set) to `/etc/supergfxd.conf` as a symlink into the Nix store -
  `environment.etc."supergfxd.conf" = lib.mkIf (cfg.settings != null)
  { source = json.generate ...; };` - every `nixos-rebuild switch`
  re-creates that symlink pointing at the declared value, so switching
  GPU mode through `asusctl`/the DankAsusControl widget (which writes
  through to that same file) would appear to work for the rest of the
  session and then silently revert to `Hybrid` on the next rebuild for
  *any* reason, not just a GPU-related one. Leaving `settings` unset
  means NixOS never touches `/etc/supergfxd.conf` at all
  (`lib.mkIf (cfg.settings != null)` is then just false), so `supergfxd`
  owns it as an ordinary mutable file and mode switches actually persist.
  Confirmed by building and checking the produced system's `/etc` no
  longer contains a `supergfxd.conf` entry at all.
- `systemd.services.supergfxd.path = [ pkgs.pciutils ]` works around
  [nixpkgs#239059](https://github.com/NixOS/nixpkgs/issues/239059) — without
  it, `supergfxd` can't find the dGPU at all.
- **`services.power-profiles-daemon` is deliberately not enabled** once
  `asusd` is — `asusd` implements the same
  `org.freedesktop.UPower.PowerProfiles` D-Bus name itself, so running both
  is a straight name collision: whichever starts second silently loses
  profile switching.

---

## `modules/hosts/<name>/Vm.nix`

Everything `virtualisation.vmVariant` touches lives here, not scattered
across whichever file happens to reference the hardware it's disabling —
`nixos-rebuild build-vm`/`nix build .#nixosConfigurations.Diablo.config.system.build.vm`
is one concern, kept in one file. Three independent fixes, all only active
for the VM build (`config.system.build.toplevel`, the real deployed
system, never sees `vmVariant` at all):

1. QEMU has no Nvidia GPU and no ASUS hardware. The real Nvidia driver
   stack (gated via `services.xserver.videoDrivers`) leaves niri with no
   working DRM device if left enabled, so it's cleared for the VM build,
   falling back to `modesetting`, which QEMU's virtual GPU supports
   natively. `asusd`/`supergfxd` are force-disabled the same way.
2. Clearing the Nvidia stack still left the VM black after "Reached
   target Graphical Interface." Root cause: QEMU's `bochs-drm` has no real
   DRI2 driver, so the SDDM greeter's QML frontend (a Wayland *client*,
   unlike Weston's own server-side renderer) can't get a hardware EGL
   context — Mesa's `zink` fallback then also fails (no Vulkan ICD). Fix:
   `QT_QUICK_BACKEND=software` in the VM's `GreeterEnvironment`, forcing
   the greeter to skip EGL/GL entirely. VM-only — real hardware has a
   working Intel iGPU and shouldn't pay the software-rendering cost.
3. Getting past the greeter, niri's own TTY/DRM backend still had no real
   GPU allocator (`no allocator available for device`, zero outputs) with
   a plain `virtio`/`std` VGA device — needs `-device virtio-vga-gl` with
   a GL-enabled display (`gtk,gl=on`) instead, backed by the *host's* own
   GPU. The catch on a non-NixOS dev host (this one's EndeavourOS): the
   Nix-built qemu looks for mesa's GBM/DRI/EGL drivers under NixOS's own
   `/run/opengl-driver` convention, which doesn't exist here. Rather than
   requiring env vars at launch time, `qemuWithHostGL` wraps the qemu
   *binary itself* (`makeWrapper`) with this host's real Arch mesa paths
   (`/usr/lib/{dri,gbm}`) — so the plain, unmodified
   `nix build .../vm` + `./result/bin/run-<name>-vm` workflow just works,
   confirmed by booting it and watching the exact `MESA-LOADER`/
   `gbm_create_device failed` errors this fixes disappear. Dev-host-specific
   by nature — these are EndeavourOS/Arch's real mesa paths, not something
   portable to another distro's layout. On a real NixOS host this wrapper
   is actively wrong (`/usr/lib/dri` doesn't exist there, and the unwrapped
   `qemu_kvm` already finds `/run/opengl-driver` natively) — swap
   `qemuWithHostGL` back to plain `pkgs.qemu_kvm` if this ever moves off
   this specific dev machine.

---

## `modules/core/Users.nix`

Shared framework — what a `vayori.users.<name>` entry can contain and how
it becomes an account. Add a *person* inline in a host's `Host.nix`; only
touch this file to change what fields a user entry supports.

- `hashedPassword`: generate with `mkpasswd -m sha-512`. `null` falls back
  to `initialPassword = "changeme"`.
- `extraGroups`: `"wheel"` for sudo, `"adbusers"` for Android debugging
  (see [AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)).
- `availableApps` auto-discovers from `modules/apps/**/*.nix` (any depth)
  — add an app by dropping a folder anywhere under `modules/apps/`,
  nothing here changes.
- Every user's `home-manager-<name>.service` gets
  `after`/`wants = [ "network-online.target" ]` here, generically — any
  app's activation script that touches the network (currently
  [ZenBrowser.nix](apps-utils.md#modulesappsutilszenbrowserzenbrowsernix)'s mods/profile
  fetch) would otherwise race the NIC coming up during boot.

---

---

## `modules/core/DevLanguages.nix`

Declares `options.flake.devLanguages` — the same publish-data-at-`self`
pattern as `flake.pluginPins`/`flake.matugenTemplates`/`flake.freeClaudeCode`
— so that editors and language modules can be decoupled from each other
entirely: a language module has no idea which editors exist, and an editor
has no idea which languages exist, they only agree on this option's shape.

- **The problem this solves**: before this, `Vscode.nix` hardcoded a
  `dart-code.dart-code` reference and `AndroidStudio.nix` hardcoded a
  `Dart`/`io.flutter` plugin reference, with no connection to whether Dart
  tooling was actually installed anywhere — removing "Dart" as a concept
  wouldn't have removed anything from either editor, and the reverse
  (editors carrying extensions for languages you don't even have a
  compiler for) was the actual complaint that prompted this file.
- **Each `modules/apps/development/languages/<Lang>/<Lang>.nix`** sets
  two things:
  - `flake.homeModules.apps.<Lang>` — a completely normal app, installing
    that language's LSP + toolchain (`rust-analyzer`+`rustc`+`cargo` for
    Rust, `nil`+`nixfmt` for Nix, etc.). Toggled the same way as any other
    app, via `vayori.apps`.
  - `flake.devLanguages.<Lang>` — data only, no packages. Conventionally
    `{ vscode = { nixpkgsExtensions; marketplaceExtensions; manualExtensions; settings; }; androidStudio = { autoPlugins; manualPlugins; }; }`,
    but nothing here enforces that shape — an editor reads whichever
    sub-keys it understands (`l.vscode or {}`) and ignores the rest, so a
    language module can add an `androidStudio` block without every editor
    needing a matching one, and a future editor can start reading
    `flake.devLanguages` without every language module changing.
- **Editors do the filtering, not this file**: `self.devLanguages` itself
  is unfiltered (it's flake-level data, evaluated once, with no host to
  filter against). All three editors — `Vscode.nix`, `AndroidStudio.nix`,
  `Zed.nix` — each compute their own `enabledLanguages = lib.filterAttrs
  (name: _: builtins.elem name vayoriApps) self.devLanguages` inside their
  home-manager module (where `vayoriApps` — `config.vayori.apps`, threaded
  via `home-manager.extraSpecialArgs` in `core/Users.nix` — is actually
  available), then fold every enabled language's contribution into their
  own extension/plugin/settings lists. Remove a language from
  `vayori.apps` and its extensions vanish from every editor in the same
  rebuild, with nothing to update in the editor files themselves.
- **`Zed.nix` merges `settings` with `lib.recursiveUpdate`, not `//`
  like `Vscode.nix`** — Zed's own settings schema nests everything
  language-adjacent under a couple of shared top-level keys (`lsp.*`,
  `languages.*`), so two languages that both configure an `lsp.*` entry
  (or a language and this file's own generic settings, if a future
  generic `lsp.*` entry gets added) need to survive under the same `lsp`
  key rather than one clobbering the other - which is exactly what a
  shallow `//` would do the moment two contributions touched the same
  top-level settings key. `Kotlin.nix`'s `lsp.kotlin-language-server` /
  `languages.Kotlin` is the one real example of this shape today.
  VSCode's settings happen to never collide this way (every language uses
  a distinct top-level key like `"[cpp]"`/`"[dart]"`/`"nix.*"`), so `//`
  was safe there, but it's not a general guarantee - a future language
  colliding with another under the same VSCode top-level key would need
  the same fix.
- **`nixpkgsExtensions` are dotted strings** (`"rust-lang.rust-analyzer"`),
  not direct `pkgs.vscode-extensions.rust-lang.rust-analyzer` references —
  language modules don't have `pkgs` in scope at the point they publish
  this data (it's flake-level, evaluated once per flake, not per-system),
  so the string gets resolved inside `Vscode.nix`'s own home-manager
  module (which does have `pkgs`) via `lib.attrByPath (lib.splitString "."
  dotted) (throw "...") pkgs.vscode-extensions`. The `throw` on a missing
  path is deliberate — a typo'd extension name fails the build loudly
  instead of silently installing nothing, which is exactly how `Kotlin.nix`
  caught that `pkgs.vscode-extensions.fwcd.kotlin` doesn't actually exist
  (nixpkgs only curates `mathiasfrohlich`'s Kotlin extension natively;
  `fwcd`'s is marketplace-only) during a real build, not at review time.
- **Manual (fetchurl-pinned) extensions/plugins still funnel through
  `Vscode`/`AndroidStudio`'s own `flake.pluginPins` keys**, not a
  per-language one — see the note in
  [PluginUpdateCheck.nix](#modulescorepluginupdatechecknix) below for why
  (the checker script only knows those two names). `Cpp.nix`'s
  `cpp-extentions-pack` pin is the one example today: it lives in
  `flake.devLanguages.Cpp.vscode.manualExtensions`, and `Vscode.nix`
  aggregates every language's `manualExtensions` into
  `flake.pluginPins.Vscode` itself, unfiltered by `vayori.apps` (same
  reasoning as above — no host to filter against at that point).
- **Dart and Flutter are one language module, `Flutter.nix`, not two** —
  `pkgs.flutter` bundles its own Dart SDK, and every real Dart-using
  project on this machine is a Flutter one anyway, so there was never a
  case where splitting them into separate toggles bought anything. Its
  VSCode contribution installs both `dart-code.dart-code` and
  `dart-code.flutter` together (the Flutter extension doesn't work
  without the Dart one, so it's not optional), and its Android Studio
  contribution installs all 4 plugins (`Dart`, Flutter Enhancement Suite,
  `flutter-intellij`, `flutter-intl`) the same way.

---

---

## `modules/core/PluginUpdateCheck.nix`

A check-only, zero-extra-commands plugin/extension update reporter for
[Vscode.nix](apps-development.md#modulesappsdevelopmenteditorsvscodevscodenix),
[AndroidStudio.nix](apps-development.md#modulesappsdevelopmenteditorsandroidstudioandroidstudionix), and
[ZenBrowser.nix](apps-utils.md#modulesappsutilszenbrowserzenbrowsernix) - **not**
[Zed.nix](apps-development.md#modulesappsdevelopmenteditorszedzednix), which has nothing to
check in the first place: `programs.zed-editor.extensions` is just a list
of names Zed itself resolves and installs at its own startup (its
`auto_install_extensions` setting), with no version or hash pinned
anywhere in this repo to go stale - the same shape as ZenBrowser's own
extensions/mods, just without even ZenBrowser's existence-checking, since
there's no Nix-side fetch to fail in the first place. It never modifies a
pin itself - it only prints what's stale so you can bump the version/hash
by hand in the matching app file.

- **Where the pins come from**: each of the three app files hoists its
  pinned-plugin list out of its home-manager module into the file's outer
  `let`, then publishes it as `flake.pluginPins.<AppName>` (same
  public-data pattern as
  [Matugen.nix](desktop.md#modulesdesktopmatugennix)'s `flake.matugenTemplates`,
  requiring the same kind of `options.flake.pluginPins` declaration -
  that lives in `modules/core/PluginPins.nix`). The home-manager module
  then just references the outer binding (`marketplaceExtensions =
  extensionsFromVscodeMarketplace marketplaceExtensionsSpec;`, etc.), so
  this refactor changes nothing about what gets installed - confirmed by
  rebuilding the toplevel and activation packages before and after and
  getting the same derivations.
- **`Vscode`/`AndroidStudio`'s pins are now aggregated, not just hoisted**:
  since [DevLanguages.nix](#modulescoredevlanguagesnix) split each editor's
  language-specific extensions/plugins out into
  `modules/apps/development/languages/*/*.nix`, `flake.pluginPins.Vscode`/
  `.AndroidStudio` are built by folding every `self.devLanguages.*.vscode
  .manualExtensions`/`.androidStudio.manualPlugins` in, on top of each
  editor's own non-language-specific manual pins. This has to stay keyed
  by editor (`Vscode`, `AndroidStudio`), not split into a `pins.Cpp` /
  `pins.Rust` per language - the Python checker script below only ever
  looks at `pins.get("Vscode", ...)`/`pins.get("AndroidStudio", ...)` by
  name, so a per-language key would just be silently skipped, never
  checked.
- **Keys are `PascalCase`, matching `self.homeModules.apps`'s own
  attribute names exactly** (`Vscode`, `AndroidStudio`, `ZenBrowser`) -
  not the lowerCamelCase used for the *files'* folder names - so
  filtering pins down to "only the apps this host actually has enabled"
  is a plain `lib.filterAttrs (name: _: builtins.elem name
  config.vayori.apps)` with no translation table.
- **`environment.etc."vayori/plugin-pins.json"`**: that filtered result,
  serialized with `builtins.toJSON`, landing at
  `/etc/vayori/plugin-pins.json`. System-wide (not per-user) because
  `vayori.apps` itself is host-wide, and it keeps the checker script
  independent of which user's shell triggers it.
- **`ZenBrowser`'s pins have no version to compare against** - every
  extension/mod is always installed at whatever's currently `/latest/`
  (AMO's install URL, the theme-store's raw file), there's nothing
  pinned to diff. So for this app the checker instead confirms the
  `slug`/mod id still *resolves* (a 404 from AMO, or an id missing from
  the theme-store's `themes.json` index, means the add-on/mod was
  renamed or pulled) - existence-checking, not version-checking.
- **The checker itself is a stdlib-only Python script**
  (`pkgs.writers.writePython3Bin`, so it goes through `flake8` at build
  time - every line had to actually pass lint, not just parse), built as
  `vayori-check-plugin-updates` and put on `$PATH` via
  `environment.systemPackages`. No `requests` dependency - just
  `urllib.request` + a `ThreadPoolExecutor` so every check runs
  concurrently instead of one network round-trip at a time. Only manual
  (fetchurl-pinned) entries have a `version` to check - on this host
  that's currently 1 VS Code extension (`Cpp.nix`'s
  `cpp-extentions-pack`) + 2 Android Studio plugins (WakaTime,
  github-copilot-intellij) + 17 Zen extensions + 8 Zen mods; every
  nix-vscode-extensions/nix-jetbrains-plugins-sourced extension tracks
  upstream automatically and has nothing pinned to check.
  - VS Code: one POST per extension to the Marketplace's
    `extensionquery` API (`filterType 7` = exact `publisher.name`
    lookup, `flags 513` = versions + latest-only), comparing the
    pinned `version` against `versions[0].version` in the response.
  - Android Studio: `GET /plugins/list?pluginId=<xmlId>` on the
    JetBrains Marketplace's legacy repository endpoint - the modern
    `/api/plugins/<id>/updates` REST endpoint only accepts a *numeric*
    plugin id, not the string `xmlId` these pins actually store (e.g.
    `com.github.catppuccin.jetbrains`, `PythonCore`), and returns a 400
    for every entry in this repo when tried; confirmed by curling it
    directly before committing to the fix. The XML response lists every
    published release of the plugin with an `updatedDate`/`date`
    timestamp on each - "latest" is picked by that timestamp, not by
    comparing version strings, because some plugins' history mixes
    versioning schemes across their lifetime (e.g. `python-ce`'s
    JetBrains-platform-era `261.x` builds alongside a stray
    old-scheme `2019.2.192.7142.17` release) and a naive string/numeric
    max over all of them picks the wrong one. There's no IDE build
    number pinned anywhere in this repo (`configDataDir =
    "AndroidStudio2026.1.3"` is a marketing version string, not the
    numeric build JetBrains' stricter compatibility filtering wants),
    so this intentionally checks "is there a newer published version at
    all," not "is there a version compatible with this exact IDE
    build."
  - Comparison is plain string inequality, not semver-aware - these
    pins mix real semver (`0.3.0`), JetBrains build-number versions
    (`261.25134.120-AS`), and prerelease suffixes (`0.1.14-beta`), so
    "not equal to what's pinned" is the honest thing to report, not
    "newer than."
  - Every network call is wrapped in its own `try/except`; failures
    (timeouts, DNS, 5xx) are silently skipped rather than reported as
    "outdated" or as errors - only a genuine version mismatch or a
    confirmed 404/missing-from-index counts as a finding. A run where
    every single check failed (fully offline) doesn't write the cache
    at all, so the next invocation retries instead of going quiet for a
    full day on a coincidental network blip.
  - Results are cached at `~/.cache/vayori/plugin-update-check.json`
    with a 24-hour TTL (`VAYORI_PLUGIN_CHECK_TTL`, seconds) - a cache
    hit reprints the same report with no network calls at all, which is
    what makes repeated rebuilds in the same day fast.
    `VAYORI_PLUGIN_CHECK_FORCE=1` bypasses the cache for a manual
    re-check.
  - Silent when there's nothing to report (no pins file yet, nothing
    outdated) - it only ever prints something when there's an actual
    finding, so it doesn't add noise to every single build.
- **Wired in via a zsh `preexec` hook in
  [Terminal.nix](apps-utils.md#modulesappsutilsterminalterminalnix)**, not a shell
  alias/function - `preexec` fires for every command a user actually
  types before it runs, including ones prefixed with `sudo` (which
  bypasses a function/alias by doing its own `PATH` lookup). The hook
  pattern-matches the typed command against
  `nixos-rebuild`/`home-manager switch`/`nix build`/`nix flake`/`nix
  run` and, only then, runs `timeout 10s vayori-check-plugin-updates`
  before letting the real command through - so "run the normal rebuild
  command" is the only thing anyone has to do, and a hung/absent
  network can delay a rebuild by at most 10 seconds, never longer.

---

