{ self, inputs, ... }: {
  flake.homeModules.apps.vscode = { pkgs, lib, vayoriTheme, ... }:
  let
    nixpkgsExtensions = with pkgs.vscode-extensions; [
      anthropic.claude-code
      arrterian.nix-env-selector
      catppuccin.catppuccin-vsc
      dart-code.dart-code
      dart-code.flutter
      eamodio.gitlens
      formulahendry.code-runner
      github.vscode-github-actions
      github.vscode-pull-request-github
      jnoortheen.nix-ide
      k--kato.intellij-idea-keybindings
      mathiasfrohlich.kotlin
      mechatroner.rainbow-csv
      ms-python.debugpy
      ms-python.python
      ms-python.vscode-pylance
      ms-python.vscode-python-envs
      ms-vscode.cmake-tools
      ms-vscode.cpptools
      ms-vscode.cpptools-extension-pack
      mskelton.one-dark-theme
      oderwat.indent-rainbow
      pkief.material-icon-theme
      twxs.cmake
      vadimcn.vscode-lldb
      vscjava.vscode-gradle
      wakatime.vscode-wakatime
      zainchen.json
    ];

    marketplaceExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      { name = "cpp-extentions-pack"; publisher = "boundarystudio"; version = "0.3.0"; hash = "sha256-UX7+sjlqfWUINtye2XYOndMvya2j0TMXEUbnJ9CDBig="; }
      { name = "vscode-jetbrains-icon-theme"; publisher = "chadalen"; version = "2.40.0"; hash = "sha256-xTnIkYtmHmytpE7uLNGIZizDpdOG4RSMBikOJK8F47k="; }
      { name = "vscode-autosave"; publisher = "codista"; version = "1.2.3"; hash = "sha256-K3R5mf9qMhE4+DUZvHMCwESVFJyVzCPDlGnd2IipGk0="; }
      { name = "c-cpp-compile-run"; publisher = "danielpinto8zz6"; version = "1.0.92"; hash = "sha256-PFw+ANPiduRhNRTuEFm1aPUOTtSUtlpqFLajCx1+GUQ="; }
      { name = "kotlin-formatter"; publisher = "esafirm"; version = "0.0.6"; hash = "sha256-H9ij1PbSy1u7nXPJ/CW1bkDP1ZnzeP6xLM6O7CNohwM="; }
      { name = "kotlin"; publisher = "fwcd"; version = "0.2.36"; hash = "sha256-tCpxFWSQZNhiHdJyxSbQ1QakS2jNqWQrA2/grLZklrM="; }
      { name = "discord-vscode"; publisher = "icrawl"; version = "5.9.2"; hash = "sha256-43ZAwaApQBqNzq25Uy/AmkQqprU7QlgJVVimfCaiu9k="; }
      { name = "vscode-edit-csv"; publisher = "janisdd"; version = "0.11.9"; hash = "sha256-hbu/r3mBtb9nDZcP8kY4fBJ5ZuKwkO/kJFk1OWDIdlk="; }
      { name = "vsc-python-indent"; publisher = "kevinrose"; version = "1.21.0"; hash = "sha256-SvJhVG8sofzV0PebZG4IIORX3AcfmErDQ00tRF9fk/4="; }
      { name = "db-viewer"; publisher = "mjstudio"; version = "1.0.3"; hash = "sha256-Jm0g1YmUX13c1v/xqthk+owWUNeCscoYn5nOIWC5XbU="; }
      { name = "prettify-json"; publisher = "mohsen1"; version = "0.0.3"; hash = "sha256-lvds+lFDzt1s6RikhrnAKJipRHU+Dk85ZO49d1sA8uo="; }
      { name = "cpp-devtools"; publisher = "ms-vscode"; version = "0.6.18"; hash = "sha256-5eq0m1jOyYzN8JCJWHWQFdkt1OzvBcO9P7cQ5dY7DoA="; }
      { name = "cpptools-themes"; publisher = "ms-vscode"; version = "2.0.0"; hash = "sha256-YWA5UsA+cgvI66uB9d9smwghmsqf3vZPFNpSCK+DJxc="; }
      { name = "gradle-language"; publisher = "naco-siren"; version = "0.2.3"; hash = "sha256-jns1Es2PMXusE7zFYpdeHGNoPrlhq1OslHRWUP3un5Y="; }
      { name = "jetbrainsmono"; publisher = "narasimapandiyan"; version = "1.0.4"; hash = "sha256-uDMKtOXDERQbOiqPgqZWUKhyPCxJnIEdN4H91hhU0+Y="; }
      { name = "vscode-python-typehint"; publisher = "njqdev"; version = "1.5.1"; hash = "sha256-CCMsCK//DCuBjFB/2kOOGjJil5zusTG+1hsp3tGTQ2U="; }
      { name = "nix-extension-pack"; publisher = "pinage404"; version = "3.0.0"; hash = "sha256-cWXd6AlyxBroZF+cXZzzWZbYPDuOqwCZIK67cEP5sNk="; }
      { name = "qt-core"; publisher = "theqtcompany"; version = "1.14.0"; hash = "sha256-tbfIhRzNYcpVknMsPuFQkYyQop4ST25tpXsXhd3PVGI="; }
      { name = "qt-qml"; publisher = "theqtcompany"; version = "1.14.0"; hash = "sha256-5Hx9Y73osV3Kd795q4i8sQWTtecRlM0YNxwMJQQ8nxE="; }
      { name = "five-server"; publisher = "yandeu"; version = "0.4.0"; hash = "sha256-oN4tZATw87M9XGmG2w0QlMPBE3Csv5jw1gZ+G1QGwqk="; }
      { name = "nix-forge"; publisher = "ziyyun"; version = "0.0.9"; hash = "sha256-isCxBbG9AeNnbDtmaPaf5egOIcKQi2w2TB1FnESk31E="; }
    ];

    vscodeSettings = {
      "security.workspace.trust.untrustedFiles" = "open";
      "files.autoSave" = "onWindowChange";

      "editor.fontFamily" = vayoriTheme.font;
      "editor.fontLigatures" = true;
      "editor.fontSize" = 15;
      "editor.fontWeight" = "normal";
      "editor.smoothScrolling" = true;
      "editor.hover.delay" = 300;
      "editor.parameterHints.enabled" = true;
      "editor.renderWhitespace" = "boundary";
      "editor.renderControlCharacters" = false;
      "editor.guides.indentation" = true;
      "editor.unicodeHighlight.nonBasicASCII" = false;

      "editor.gotoLocation.multipleDefinitions" = "goto";
      "editor.gotoLocation.multipleDeclarations" = "goto";
      "editor.foldingStrategy" = "indentation";
      "editor.showFoldingControls" = "always";

      "workbench.colorTheme" = "Dynamic Base16 DankShell";
      "workbench.iconTheme" = "vscode-jetbrains-icon-theme-2023-dark";
      "workbench.editor.showIcons" = true;
      "workbench.editor.enablePreview" = false;
      "workbench.editor.tabSizing" = "shrink";
      "workbench.editor.tabCloseButton" = "right";
      "workbench.editor.highlightModifiedTabs" = true;
      "workbench.editor.tabActionLocation" = "right";
      "workbench.secondarySideBar.defaultVisibility" = "hidden";
      "workbench.list.smoothScrolling" = true;
      "workbench.editorAssociations" = {
        "*.copilotmd" = "vscode.markdown.preview.editor";
        "{git,gitlens,chat-editing-snapshot-text-model,copilot,git-graph,git-graph-3}:/**/*.qrc" = "default";
        "*.qrc" = "qt-core.qrcEditor";
      };

      "explorer.compactFolders" = false;
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;

      "errorLens.enabled" = true;
      "errorLens.fontWeight" = "bold";
      "errorLens.messageBackgroundMode" = "message";

      "[dart]" = {
        "editor.formatOnSave" = true;
        "editor.formatOnType" = true;
        "editor.rulers" = [ 80 ];
        "editor.selectionHighlight" = false;
        "editor.tabCompletion" = "onlySnippets";
        "editor.wordBasedSuggestions" = "off";
      };
      "dart.lineLength" = 80;
      "dart.showTodos" = true;
      "dart.analysisServerFolding" = true;
      "dart.debugExternalPackageLibraries" = true;
      "dart.debugSdkLibraries" = true;

      "github.copilot.nextEditSuggestions.enabled" = true;
      "github.copilot.enable" = {
        "*" = true;
        plaintext = false;
        markdown = false;
        scminput = false;
        python = false;
        cpp = false;
        html = false;
        css = false;
        javascript = false;
        qml = false;
        c = false;
      };

      "editor.tokenColorCustomizations" = {
        textMateRules = [
          { scope = "comment"; settings.fontStyle = "italic"; }
        ];
      };

      "database-client.autoSync" = true;
      "qt-qml.qmlls.useQmlImportPathEnvVar" = true;
      "qt-core.additionalQtPaths" = [
        { name = "Qt-5.15.18-linux-g++_from_PATH"; path = "/usr/bin/qmake"; }
      ];

      "code-runner.runInTerminal" = true;

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.formatterPath" = "nixfmt";
      "[nix]"."editor.defaultFormatter" = "ZiYyun.nix-forge";

      "[cpp]" = {
        "editor.defaultFormatter" = "ms-vscode.cpptools";
        "editor.formatOnSave" = true;
      };
      "C_Cpp.clang_format_style" = "file";
      "C_Cpp.clang_format_fallbackStyle" = "Google";

      "claudeCode.preferredLocation" = "panel";

      "git.enableSmartCommit" = true;
      "git.autofetch" = true;
      "git.confirmSync" = false;
    };

    vscodeKeybindings = [
      {
        key = "ctrl+y";
        command = "-editor.action.deleteLines";
        when = "editorTextFocus && !editorReadonly";
      }
    ];

    # DMS bundles this vsix itself (matugenTemplateVscode = true, in
    # desktop/dms.nix) and rewrites its themes/*.json on every wallpaper
    # change (core/internal/matugen/matugen.go: appendVSCodeConfig writes
    # straight into the installed extension's own directory) - but DMS
    # never installs the vsix itself, only keeps an already-installed
    # copy's theme files updated (checkVSCodeExtension there is purely a
    # detection/UI check, confirmed by reading the source). It can't go
    # through programs.vscode.profiles.default.extensions either: that
    # symlinks straight into the read-only /nix/store, so matugen's writes
    # would fail. Installed as a real, writable copy via home.activation
    # instead - version has to track DMS's own vsix-build/package.json.
    #
    # Directory name MUST be lowercase "danklinux..." even though the vsix's
    # own package.json declares "publisher": "DankLinux" - appendVSCodeConfig
    # globs for extBaseDir/danklinux.dms-theme-* verbatim (matches VSCode's
    # own real `code --install-extension` convention of lowercasing the
    # publisher for the on-disk id). Confirmed by booting this in a real VM:
    # the capitalized version silently never matched, so matugen's write
    # never actually ran - the file just held the vsix's own static default
    # colors the whole time, not a live-updated theme.
    dmsVscodeThemeVersion = "0.0.3";
    dmsVscodeThemeExtId = "danklinux.dms-theme-${dmsVscodeThemeVersion}";
    dmsVscodeThemeSrc = pkgs.runCommand "dms-theme-vscode-extension" { } ''
      mkdir -p $out
      cd $out
      ${pkgs.unzip}/bin/unzip -q ${inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell}/share/quickshell/dms/matugen/dms-theme.vsix
    '';
  in {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      profiles.default = {
        userSettings = vscodeSettings;
        keybindings = vscodeKeybindings;
        extensions = nixpkgsExtensions ++ marketplaceExtensions;
      };
    };

    home.activation.installDmsVscodeTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      extDir="$HOME/.vscode/extensions/${dmsVscodeThemeExtId}"
      if [ ! -f "$extDir/package.json" ]; then
        run rm -rf "$extDir"
        run mkdir -p "$extDir"
        run cp -rL "${dmsVscodeThemeSrc}/extension/." "$extDir/"
        run chmod -R u+w "$extDir"
      fi
    '';
  };
}
