# Configuration reference

The `.nix` files in this repo are kept comment-free on purpose — this file
holds the "why" instead. It's organized to match `modules/`: find a file
you're editing, jump to its section.

For "how do I add a host/user/app," see the README's
[Using this on your own machine](../README.md#using-this-on-your-own-machine)
and [Extending it](../README.md#extending-it) sections — this is the deeper
reference, not the walkthrough.

## Contents

- [How it's wired together](#how-its-wired-together)
- [Project structure](#project-structure)

**Core & hosts**
- [core/Users.nix](#modulescoreusersnix)
- [core/DevLanguages.nix](#modulescoredevlanguagesnix)
- [core/PluginUpdateCheck.nix](#modulescorepluginupdatechecknix)
- [hosts/\<name\>/Host.nix](#moduleshostsnamehostnix)
- [hosts/\<name\>/\_hardware.nix](#moduleshostsname_hardwarenix)
- [hosts/\<name\>/Vm.nix](#moduleshostsnamevmnix)

**Desktop**
- [desktop/Dms.nix](#modulesdesktopdmsnix)
- [desktop/Niri.nix](#modulesdesktopnirinix)
- [desktop/Fonts.nix / Portals.nix](#modulesdesktopfontsnix--portalsnix)
- [desktop/Baseline.nix](#modulesdesktopbaselinenix)
- [desktop/Matugen.nix](#modulesdesktopmatugennix)

**System**
- [system/DevTooling.nix](#modulessystemdev-toolingnix)
- [system/GrubTheme.nix](#modulessystemgrub-themenix)

**Apps - development**
- [apps/development/editors/vscode/Vscode.nix](#modulesappsdevelopmenteditorsvscodevscodenix)
- [apps/development/editors/androidStudio/AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)
- [apps/development/editors/zed/Zed.nix](#modulesappsdevelopmenteditorszedzednix)
- [apps/development/devTools/DevTools.nix](#modulesappsdevelopmentdevtoolsdevtoolsnix)
- [apps/development/freeClaudeCode/FreeClaudeCode.nix](#modulesappsdevelopmentfreeclaudecodefreeclaudecodenix)
- [apps/development/languages/\*/\*.nix](#modulesappsdevelopmentlanguagesnix) (Cpp, Rust, Kotlin, Flutter [+Dart], Nix, Qt)

**Apps - gaming**
- [apps/gaming/Gaming.nix](#modulesappsgaminggamingnix)

**Apps - utils**
- [apps/utils/zenBrowser/ZenBrowser.nix](#modulesappsutilszenbrowserzenbrowsernix)
- [apps/utils/spicetify/Spicetify.nix](#modulesappsutilsspicetifyspicetifynix)
- [apps/utils/nautilus/Nautilus.nix](#modulesappsutilsnautilusnautilusnix)
- [apps/utils/bitwarden/Bitwarden.nix](#modulesappsutilsbitwardenbitwardennix)
- [apps/utils/terminal/Terminal.nix](#modulesappsutilsterminalterminalnix)
- [apps/utils/vesktop/Vesktop.nix](#modulesappsutilsvesktopvesktopnix)

---

## How it's wired together

`flake.nix` calls `inputs.import-tree ./modules`, which recursively imports
every `.nix` file under `modules/` as a flake-parts module — no manual
import list anywhere. Two non-obvious consequences:

- **Any path containing `/_` is skipped.** Used deliberately for
  `_hardware.nix` so it can be a plain NixOS module instead of a named
  `flake.nixosModules.*` one.
- **Flakes only see git-tracked files.** A new `.nix` file that hasn't been
  `git add`ed is invisible to `nix flake check`/`nix build` — it silently
  evaluates as if it doesn't exist, rather than erroring. `git add` new
  files first if something "isn't picking up."

Two option namespaces get populated across these files:

| Namespace | Set by | Read by |
| --- | --- | --- |
| `flake.nixosModules.*` | `hosts/`, `desktop/`, `system/`, `core/Users.nix` | `Host.nix`'s `modules` list |
| `flake.homeModules.apps.*` | `modules/apps/**/*.nix` (any depth) | `core/Users.nix`, via `vayori.apps` |
| `flake.devLanguages.*` | `modules/apps/development/languages/*/*.nix` | `Vscode.nix`/`AndroidStudio.nix`, filtered by `vayori.apps` |

All of the above is attribute-name-based, not path-based — `Host.nix`
imports `self.nixosModules.dms`, never a file path. Moving a file to a
different directory never requires touching `Host.nix`'s `modules` list
or `vayori.apps`, only a rename of the attribute itself would.

## Project structure

```
modules/
  core/        flake-parts wiring + the shared user/app framework
  hosts/<name>/  one machine: Host.nix + _hardware.nix, nothing else
  desktop/     the DE stack — compositor, shell, login theme, fonts,
               portals, and the GTK/Qt baseline every user gets
  system/      system-level infra unrelated to the desktop
  apps/        per-user opt-in modules (vayori.apps), one folder each
  assets/      static, non-code files (wallpapers)
```

`core`/`desktop`/`system` boundary, briefly: **core** is pure
framework/wiring, nothing here is itself a "setting" (`Parts.nix`,
`Registry.nix`, and the `vayori.users`/`vayori.apps` option definitions in
`Users.nix`). **desktop** is everything that makes this specific rice look
and feel the way it does — swap the compositor or shell and this whole
category changes. **system** is infra that doesn't care what desktop
you're running (Docker, GRUB theming). The line between `desktop` and
`system` is "does this depend on niri/DMS specifically" — GRUB theming
doesn't, so it's `system`, not `desktop`, even though it's still
"theming."

`apps/` is split into three categories — `development/`, `gaming/`,
`utils/` — and every app is a folder (`apps/<category>/<name>/<name>.nix`)
whether or not it currently has extra assets alongside it, so adding a
font file or script to an app later never means restructuring it from a
flat file into a folder. The category is purely organizational: only the
`flake.homeModules.apps.<Name>` attribute name matters to the rest of the
repo (`vayori.apps`, `core/Users.nix`'s `availableApps`), so an app can
move between categories, or nest arbitrarily deep, without touching
anything outside its own folder.

`apps/development/editors/` holds the three editors (`Vscode`,
`AndroidStudio`, `Zed`), each a normal app plus a *consumer* of
`flake.devLanguages` (see below) — grouped in their own folder mainly so
"which apps are editors that read language data" is visible from the
directory listing alone, not something you'd otherwise have to grep for.

`apps/development/languages/` is its own thing within `development/`: one
folder per language (`Cpp`, `Rust`, `Kotlin`, `Flutter` — covers Dart too,
one toggle for both, see that section — `Nix`, `Qt`), each both a normal
app (`flake.homeModules.apps.<Lang>` installs that language's
LSP/toolchain) *and* a data source (`flake.devLanguages.<Lang>`) that
every editor above reads to decide which of its own extensions/plugins to
install — see [core/DevLanguages.nix](#modulescoredevlanguagesnix).

`apps/gaming/` is one app (`Gaming`) split across multiple files for
readability: `Gaming.nix` is the actual `flake.homeModules.apps.Gaming`
entry, and `_launchers.nix`/`_proton.nix`/`_performance.nix` are plain
home-manager module fragments it `imports` by relative path — the leading
underscore keeps them out of import-tree's own auto-import (same trick as
`_hardware.nix`), since they aren't flake-parts modules on their own.

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
theme package — see [Fonts.nix / Portals.nix](#modulesdesktopfontsnix--portalsnix).

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
[Gaming.nix](#modulesappsgaminggamingnix) — see that section for why.

**Users** (`vayori.users`): one entry per real account — see
[core/Users.nix](#modulescoreusersnix) for field meanings. Generate a
password hash with `mkpasswd -m sha-512`.

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

- `services.supergfxd.settings.mode = "Hybrid"` makes the mode declarative
  (confirmed against `supergfxctl`'s own source — `/etc/supergfxd.conf`,
  `mode` matching the `GfxMode` enum exactly) instead of a one-time
  `supergfxctl -m Hybrid && reboot` you'd have to remember on every install.
- `systemd.services.supergfxd.path = [ pkgs.pciutils ]` works around
  [nixpkgs#239059](https://github.com/NixOS/nixpkgs/issues/239059) — without
  it, `supergfxd` can't find the dGPU at all.
- **`services.power-profiles-daemon` is deliberately not enabled** once
  `asusd` is — `asusd` implements the same
  `org.freedesktop.UPower.PowerProfiles` D-Bus name itself, so running both
  is a straight name collision: whichever starts second silently loses
  profile switching.

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

## `modules/core/Users.nix`

Shared framework — what a `vayori.users.<name>` entry can contain and how
it becomes an account. Add a *person* inline in a host's `Host.nix`; only
touch this file to change what fields a user entry supports.

- `hashedPassword`: generate with `mkpasswd -m sha-512`. `null` falls back
  to `initialPassword = "changeme"`.
- `extraGroups`: `"wheel"` for sudo, `"adbusers"` for Android debugging
  (see [AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)).
- `availableApps` auto-discovers from `modules/apps/**/*.nix` (any depth)
  — add an app by dropping a folder anywhere under `modules/apps/`,
  nothing here changes.
- Every user's `home-manager-<name>.service` gets
  `after`/`wants = [ "network-online.target" ]` here, generically — any
  app's activation script that touches the network (currently
  [ZenBrowser.nix](#modulesappsutilszenbrowserzenbrowsernix)'s mods/profile
  fetch) would otherwise race the NIC coming up during boot.

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

## `modules/core/PluginUpdateCheck.nix`

A check-only, zero-extra-commands plugin/extension update reporter for
[Vscode.nix](#modulesappsdevelopmenteditorsvscodevscodenix),
[AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix), and
[ZenBrowser.nix](#modulesappsutilszenbrowserzenbrowsernix) - **not**
[Zed.nix](#modulesappsdevelopmenteditorszedzednix), which has nothing to
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
  [Matugen.nix](#modulesdesktopmatugennix)'s `flake.matugenTemplates`,
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
  [Terminal.nix](#modulesappsutilsterminalterminalnix)**, not a shell
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

## `modules/desktop/Dms.nix`

**Applied to every user**, not hardcoded to one —
`home-manager.users = lib.genAttrs (builtins.attrNames config.vayori.users) (name: { ... })`.
Hardcoding it was an earlier bug: a second account got a niri session with
no shell running in it.

**`settings = { ... }` is the only valid key.** An older
`default.settings = { ... }` shape is a silent no-op if you use it by
mistake.

**Wallpaper default**: `xdg.stateFile."DankMaterialShell/session.json"`
seeds `wallpaperPath`/`wallpaperCyclingFolderPath` from
`modules/wallpapers`. Force-written like `settings.json`, so DMS can still
switch wallpapers live between rebuilds, but resets to this default on the
next `nixos-rebuild switch`.

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
  satisfied by [\_hardware.nix](#moduleshostsname_hardwarenix)/`Host.nix`.
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
[AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix) already
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
(Cava/Btop under [Terminal.nix](#modulesappsutilsterminalterminalnix), Heroic/
Steam/Wine under [Gaming.nix](#modulesappsgaminggamingnix), Vesktop under
[Vesktop.nix](#modulesappsutilsvesktopvesktopnix)).

---

## `modules/system/DevTooling.nix`

Named for what it actually is — system-level enablement for development
workflows, not tied to any one app. Renamed from `dev-system.nix` during
the project restructure specifically to stop reading as a near-duplicate
of [apps/devTools/DevTools.nix](#modulesappsdevelopmentdevtoolsdevtoolsnix) (a
completely different, per-user file — VS Code/git/gh/lazygit/
docker-compose). `virtualisation.docker.enable`/`libvirtd.enable` are
the actual system daemons `dev-tools`' `docker-compose` and any VM
tooling need. `programs.adb.enable` was removed upstream — systemd 258+
handles the adb uaccess udev rules automatically, and
`pkgs.android-tools` (already in
[AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix)) covers
the `adb` command itself — `users.groups.adbusers` stays declared here
purely as a valid `extraGroups` entry, it no longer grants anything on
its own.

## `modules/system/GrubTheme.nix`

`grub-theme` is a plain repo meant to be installed via its own shell
script, not a Nix package. This module fetches its source via the flake
input and points `boot.loader.grub.theme` straight at the theme directory
(what that option actually expects — a directory containing `theme.txt`).

Double-check the subfolder name (`SekiroShadow` currently) after your
first rebuild — if GRUB doesn't pick it up, `ls ${inputs.grub-theme}` in
`nix repl` and adjust the path.

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

## `modules/apps/utils/spicetify/Spicetify.nix`

**Custom font**: Spotify's client CSS reads its UI font from the
`--font-family` custom property, not generic `font-family: sans-serif` —
`theme.additionalCss` sets it to `vayoriTheme.font` explicitly.
`theme.extraPkgs = [ vayoriTheme.fontPackage ]` makes that font an
explicit dependency of the spiced Spotify derivation. `spicePkgs.themes.hazy
// { ... }` merges onto the theme's existing options — `theme` accepts a
freeform attrset, so this is safe.

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
  [\_hardware.nix](#moduleshostsname_hardwarenix)): import-tree skips any
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
  [\_hardware.nix](#moduleshostsname_hardwarenix)) is NixOS's own
  ready-made wrapper for this — no separate script needed here. Use as a
  launch-option prefix, e.g. `nvidia-offload gamemoderun -- %command%`. The
  `dankAsusControlCenter` DMS widget's "GPU Mode" switch does the same
  thing at the whole-laptop level instead of per-launch.
- **Heroic matugen theme**: content (`self.matugenTemplates.heroic`)
  ported from [InioX/matugen-themes](https://github.com/InioX/matugen-themes),
  registered as `vayori.matugenTemplates.heroic` — DMS's documented
  custom-template mechanism, same as every other app here (see
  [Baseline.nix](#modulesdesktopbaselinenix)/
  [Matugen.nix](#modulesdesktopmatugennix)). Heroic has no fixed theme
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
    [DevLanguages.nix](#modulescoredevlanguagesnix)**: `Flutter.nix`
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
    [PluginUpdateCheck.nix](#modulescorepluginupdatechecknix) watching
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
  [Baseline.nix](#modulesdesktopbaselinenix) — since DMS has no built-in
  JetBrains/Android Studio matugen integration at all, this is a
  from-scratch template. The `.icls` body itself is a shared, public
  value (`self.matugenTemplates.androidStudio matugenSchemeName`, a
  function of the scheme name — see
  [Matugen.nix](#modulesdesktopmatugennix)), not inlined here. The
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

## `modules/apps/development/editors/vscode/Vscode.nix`

`programs.vscode.profiles.default` (`userSettings`, `keybindings`,
`extensions`), the current home-manager schema — not the older flat
`programs.vscode.userSettings` shape. Settings, the one custom
keybinding (`ctrl+y` unbound from `editor.action.deleteLines`), and every
extension are a direct transcription of the real `~/.config/Code/User/`
on this machine, not a live importer - but as of
[DevLanguages.nix](#modulescoredevlanguagesnix), split between generic
ones declared right here and language-specific ones this file only
aggregates:

- `nixpkgsExtensions`/`vscodeAutoExtensions` here are the **generic**
  ones only - nothing tied to a specific language. `nixpkgsExtensions`:
  pre-packaged in `pkgs.vscode-extensions`. `vscodeAutoExtensions`:
  resolved through `pkgs.vscode-marketplace.<publisher>.<name>`, the
  overlay from the
  [nix-community/nix-vscode-extensions](https://github.com/nix-community/nix-vscode-extensions)
  input (`nixpkgs.overlays` in
  [Host.nix](#moduleshostsdiablohostnix)) - daily-refreshed, no hash to
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
  [PluginUpdateCheck.nix](#modulescorepluginupdatechecknix) for why it
  has to stay under this one key rather than a per-language one) - so
  it's still the only one exposed there today; every
  nix-vscode-extensions-sourced one doesn't need
  [PluginUpdateCheck.nix](#modulescorepluginupdatechecknix) to watch it
  at all.

VSCode itself moved out of `DevTools.nix` into its own module once it
needed this much dedicated configuration — `DevTools.nix` keeps only
`gh`, `lazygit`, `docker-compose`.

- **The DMS theme extension (`DankLinux.dms-theme`) is installed as a
  real, writable copy via `home.activation`, not through
  `programs.vscode.profiles.default.extensions`**: DMS bundles this vsix
  itself (`matugenTemplateVscode = true`, in
  [Dms.nix](#modulesdesktopdmsnix)) and rewrites its `themes/*.json` on
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

## `modules/apps/development/editors/zed/Zed.nix`

`programs.zed-editor` (home-manager's native module) — `extensions` and
`userSettings`, a direct transcription of the real `~/.config/zed/` on
this machine (both the installed-extensions list and `settings.json`),
split generic-vs-language-specific the same way as
[Vscode.nix](#modulesappsdevelopmenteditorsvscodevscodenix), one commit
after Vscode/AndroidStudio had already gone through this split - so this
file only ever had to *aggregate*
[DevLanguages.nix](#modulescoredevlanguagesnix) contributions, never carry
language-specific settings of its own to begin with.

- **Extensions are just names, not files or hashes** — unlike VS Code's
  marketplace extensions (fetched and pinned as Nix derivations) or
  Android Studio's plugins (same), `programs.zed-editor.extensions`
  becomes Zed's own `auto_install_extensions` setting, and Zed resolves
  and downloads each one itself at its *own* next startup. Nix's only
  job here is writing the list of names - there's nothing to pin, hash,
  or feed to [PluginUpdateCheck.nix](#modulescorepluginupdatechecknix)
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
  [DevLanguages.nix](#modulescoredevlanguagesnix)'s note about
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
  [Matugen.nix](#modulesdesktopmatugennix)'s `zed` entry - unlike every
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

## `modules/apps/development/languages/*/*.nix`

Seven independent `vayori.apps` toggles, each installing one language's own
LSP/toolchain and telling the editors above what to install for it - see
[DevLanguages.nix](#modulescoredevlanguagesnix) for the mechanism. All
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

## `modules/apps/development/devTools/DevTools.nix`

`git` isn't listed here — it's already in `environment.systemPackages`
(`Host.nix`), since flakes need it system-wide regardless of which apps
are picked.

## `modules/apps/utils/bitwarden/Bitwarden.nix`

Just `pkgs.bitwarden-desktop` — the nixpkgs attribute name is
`bitwarden-desktop`, not `bitwarden` (that alias throws a
renamed-package error). Added so a fresh install has a working password
manager without a manual first-run setup step; vault contents still
require signing in once, syncing pulls everything else back down.

**`programs.rbw`** is a separate CLI vault client from the desktop app
above — it's what the `dankBitwarden` DMS launcher plugin
([Dms.nix](#modulesdesktopdmsnix)) actually shells out to, an unrelated
session from the desktop app's own login. `settings.email` has no
default and is required by home-manager's own `rbw` module, so it's left
unset here pending the real account email — `rbw config set email
<you>` once, then `rbw login`, gets it working without needing a
rebuild. Once known, it can be set declaratively instead: `programs.rbw
= { enable = true; settings = { email = "you@example.com"; pinentry =
pkgs.pinentry-gtk2; }; };`.

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
  [Matugen.nix](#modulesdesktopmatugennix), ported from
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
  from [Matugen.nix](#modulesdesktopmatugennix)) is InioX's `[color]`
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

## `modules/apps/utils/vesktop/Vesktop.nix`

Two real config files pinned straight off the reference machine, plus a
matugen-driven theme — same "capture what's actually there, don't guess"
approach as [AndroidStudio.nix](#modulesappsdevelopmenteditorsandroidstudioandroidstudionix).
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
  [Matugen.nix](#modulesdesktopmatugennix) — same `@import`, same
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
  ([ZenBrowser.nix](#modulesappsutilszenbrowserzenbrowsernix)) — a real
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
  [core/Users.nix](#modulescoreusersnix) - the same plumbing any other
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
