{ self, inputs, ... }:
let
  marketplaceExtensionsSpec = [
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
    { name = "cpp-devtools"; publisher = "ms-vscode"; version = "0.7.0"; hash = "sha256-zxnF1MThApdGAJ9LRqNpUMwU5GPRpawoB2p0S7qcuNM="; }
    { name = "cpptools-themes"; publisher = "ms-vscode"; version = "2.0.0"; hash = "sha256-YWA5UsA+cgvI66uB9d9smwghmsqf3vZPFNpSCK+DJxc="; }
    { name = "gradle-language"; publisher = "naco-siren"; version = "0.2.3"; hash = "sha256-jns1Es2PMXusE7zFYpdeHGNoPrlhq1OslHRWUP3un5Y="; }
    { name = "jetbrainsmono"; publisher = "narasimapandiyan"; version = "1.0.4"; hash = "sha256-uDMKtOXDERQbOiqPgqZWUKhyPCxJnIEdN4H91hhU0+Y="; }
    { name = "vscode-python-typehint"; publisher = "njqdev"; version = "1.5.1"; hash = "sha256-CCMsCK//DCuBjFB/2kOOGjJil5zusTG+1hsp3tGTQ2U="; }
    { name = "nix-extension-pack"; publisher = "pinage404"; version = "3.0.0"; hash = "sha256-cWXd6AlyxBroZF+cXZzzWZbYPDuOqwCZIK67cEP5sNk="; }
    { name = "qt-core"; publisher = "theqtcompany"; version = "1.17.0"; hash = "sha256-knBG17lcrr3NP5sxMtbgG6coiEM//caEeei2NWKfJVk="; }
    { name = "qt-qml"; publisher = "theqtcompany"; version = "1.17.0"; hash = "sha256-4P0v3r1pHgLKR7Jt3Je3kBHSwVZ2djWlxQOmAbTsM/0="; }
    { name = "five-server"; publisher = "yandeu"; version = "0.4.0"; hash = "sha256-oN4tZATw87M9XGmG2w0QlMPBE3Csv5jw1gZ+G1QGwqk="; }
    { name = "nix-forge"; publisher = "ziyyun"; version = "0.0.9"; hash = "sha256-isCxBbG9AeNnbDtmaPaf5egOIcKQi2w2TB1FnESk31E="; }
  ];
in {
  flake.pluginPins.Vscode = marketplaceExtensionsSpec;

  flake.homeModules.apps.Vscode = { pkgs, lib, vayoriTheme, vayoriApps, ... }:
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

    marketplaceExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace marketplaceExtensionsSpec;

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
          { scope = [ "entity.name.type" "entity.other.inherited-class" "keyword.other.type" "punctuation.definition.annotation" "storage.modifier.import" "storage.modifier.package" "storage.type.annotation" "storage.type.built-in" "storage.type.generic" "storage.type.java" "storage.type.groovy" "storage.type.primitive" "support.class" "support.other.namespace" "support.type" "variable.language.this" ]; settings.foreground = "#e5c07b"; }
          { scope = [ "constant.other.character-class" "entity.name.tag" "heading" "meta.object-literal.key" "punctuation.definition.list.begin.markdown" "punctuation.definition.list.end.markdown" "punctuation.definition.template-expression" "punctuation.section.embedded" "support.type.property-name" "variable.object.property" "variable.other.enummember" ]; settings.foreground = "#e06c75"; }
          { scope = [ "constant.character.escape" "keyword.operator" "markup.underline.link" "string.regexp" "string.url" ]; settings.foreground = "#56b6c2"; }
          { scope = [ "entity.name.function" "entity.other.attribute-name.id.css" "meta.function-call.generic" "string.other.link" "support.function" "variable.language.super" ]; settings.foreground = "#61afef"; }
          { scope = [ "meta.brace" "punctuation.accessor" "punctuation.definition.block" "punctuation.separator" "support.type.property-name.css" ]; settings.foreground = "#abb2bf"; }
          { scope = [ "markup.inline" "markup.quote" "source.ini" "string.other.link.description" "string" ]; settings.foreground = "#98c379"; }
          { scope = [ "comment" ]; settings.foreground = "#5c6370"; }
          { scope = [ "keyword.operator.new" "keyword" "markup.italic" "punctuation.definition.block.tag" "storage.modifier" "storage.type" ]; settings.foreground = "#c678dd"; }
          { scope = [ "constant" "entity.other.attribute-name" "keyword.operator.quantifier.regexp" "markup.bold" "support.constant" "variable.other.constant" "variable.parameter" ]; settings.foreground = "#d19a66"; }
          { scope = [ "markup.quote" "markup.italic" ]; settings.fontStyle = "italic"; }
          { scope = [ "heading" "markup.bold" ]; settings.fontStyle = "bold"; }
        ];
      };

      "editor.semanticTokenColorCustomizations" = {
        enabled = true;
        rules = {
          enumMember = "#d19a66";
          property = "#e06c75";
          "variable.defaultLibrary" = "#e5c07b";
        };
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
    } // lib.optionalAttrs (builtins.elem "FreeClaudeCode" vayoriApps) {
      "claudeCode.disableLoginPrompt" = true;
      "claudeCode.environmentVariables" =
        lib.mapAttrsToList (name: value: { inherit name value; }) self.freeClaudeCode.clientEnv;
    };

    vscodeKeybindings = [
      {
        key = "ctrl+y";
        command = "-editor.action.deleteLines";
        when = "editorTextFocus && !editorReadonly";
      }
    ];

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
