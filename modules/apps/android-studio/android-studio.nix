{ self, inputs, ... }: {
  flake.homeModules.apps."android-studio" = { pkgs, lib, config, vayoriTheme, ... }:
  let
    configDataDir = "AndroidStudio2026.1.3";
    pluginsDir = ".local/share/Google/${configDataDir}";
    optionsDir = ".config/Google/${configDataDir}/options";
    colorsDir = ".config/Google/${configDataDir}/colors";

    # matugen extension point (core/internal/matugen/matugen.go, buildMergedConfig):
    # every *.toml dropped in dmsMatugenConfigsDir is appended verbatim into the
    # generated matugen invocation, unconditionally - no app-detection, no
    # CONFIG_DIR/DATA_DIR macro substitution (that only applies to DMS's own
    # bundled configs/base.toml), so paths here have to be fully resolved already.
    dmsMatugenDirRel = ".config/quickshell/dms/matugen/dms";
    dmsMatugenDir = "${config.home.homeDirectory}/${dmsMatugenDirRel}";
    matugenSchemeName = "DankMatugen";
    matugenTemplatePath = "${dmsMatugenDir}/templates/android-studio-colors.icls";
    matugenOutputPath = "${config.home.homeDirectory}/${colorsDir}/${matugenSchemeName}.icls";

    fetchJbPlugin = { id, version, hash, isJar ? false }:
      let
        src = pkgs.fetchurl {
          url = "https://plugins.jetbrains.com/plugin/download?pluginId=${id}&version=${version}";
          inherit hash;
        };
      in
      if isJar then src
      else pkgs.runCommand "jetbrains-plugin-${id}" { } ''
        mkdir -p $out
        cd $out
        ${pkgs.unzip}/bin/unzip -q ${src}
      '';

    androidStudioPlugins = [
      { dirName = "Catppuccin Theme"; id = "com.github.catppuccin.jetbrains"; version = "3.6.1"; hash = "sha256-JQwlFCAUs5Du/itRwmnPMRB5iw/3adRC3zN9tnsfDqU="; }
      { dirName = "claude-code-jetbrains-plugin"; id = "com.anthropic.code.plugin"; version = "0.1.14-beta"; hash = "sha256-usZ6r0YZrOERPf7MO8aq9cAU25yWggOa6avNEGwzgJY="; }
      { dirName = "Dart"; id = "Dart"; version = "508.1.0"; hash = "sha256-jq79eTX1EZVcSptEv9VwcguTZkNuJj/WeV2JsEyqUxk="; }
      { dirName = "Flutter Enhancement Suite"; id = "de.mariushoefler.flutter_enhancement_suite"; version = "1.7.0"; hash = "sha256-8s0K0TH/YCVaJJym0Ogfn5+VUkxtJmzOdVHQCUlZ1h4="; }
      { dirName = "flutter-intellij"; id = "io.flutter"; version = "95.0.0"; hash = "sha256-Io0sO1uEDvKsiVjzD6VUA7lkVVfHWvLMSN2e93SnDlc="; }
      { dirName = "flutter-intl"; id = "com.localizely.flutter-intl"; version = "1.18.8-2024.2"; hash = "sha256-gFHYR9ZYLR7rhwPw8BpZ89Sl8hFsaZPFhiGpbwBPRJE="; }
      { dirName = "github-copilot-intellij"; id = "com.github.copilot"; version = "1.15.0-261-linux-x64"; hash = "sha256-ZVMDUHuoJawY4LKBFHSXvLzoVMJ6bhhUS6sm4R8HiQc="; }
      { dirName = "git-worktree-manager"; id = "com.purringlabs.gitworktree.git-worktree-manager"; version = "1.1.27"; hash = "sha256-avwWW6hW8tQx18tEmtZhOcSyh3sFol/MYstSIQBN+cM="; }
      { dirName = "JetBrains-Discord-Integration"; id = "dev.azn9.plugins.discord"; version = "2.1.10.242"; hash = "sha256-rkCvxroVNVjC4Y9kwlQesmrqbQ4sR31/Z9A+avrAyYI="; }
      { dirName = "kmm-plugin"; id = "com.jetbrains.kmm"; version = "261.25134.120-AS"; hash = "sha256-ck+pqoBs14geYCJ2QqQERZqMVY/2aXQOGFSzxFl9bSM="; }
      { dirName = "lsp4ij"; id = "com.redhat.devtools.lsp4ij"; version = "0.20.1"; hash = "sha256-0ysAQkzi1C+p/olcf6c0Kz3HzphcdHqf/PNq9TqKnBM="; }
      { dirName = "NixIDEA"; id = "nix-idea"; version = "0.4.0.22"; hash = "sha256-QLOnvM+7r4x+5eaptrP/5JlQPskluj+hoYCR/xCXKJk="; }
      { dirName = "one-dark-theme"; id = "com.markskelton.one-dark-theme"; version = "6.2.5"; hash = "sha256-RtlUjQhE4+J6kFauVNBVg14LorzYg4C39CLOkVo5mvs="; }
      { dirName = "python-ce"; id = "PythonCore"; version = "261.25134.95"; hash = "sha256-VJXvhRyUvnT3fbRfFQ3eQqGdx0NPdP8G784ggiVtDbQ="; }
      { dirName = "vcs-perforce"; id = "PerforceDirectPlugin"; version = "261.25134.10"; hash = "sha256-gWp0uyWIz5Ei4JwrBf+1v0NxpA7fF2egwJxSkJsItes="; }
      { dirName = "vcs-svn"; id = "Subversion"; version = "261.23567.176"; hash = "sha256-8ZSwC4JipxgeQ5Qepda5znwIphWHDpOSAjkpIjtlEDA="; }
      { dirName = "WakaTime.jar"; id = "com.wakatime.intellij.plugin"; version = "16.1.2"; hash = "sha256-KnHRvFUtsH4vJDF+YhSoP7YpV52Jqoe2AiMwORDiPOQ="; isJar = true; }
    ];

    pluginFiles = lib.listToAttrs (map
      (p:
        let
          plugin = fetchJbPlugin { inherit (p) id version hash; isJar = p.isJar or false; };
          source = if (p.isJar or false) then plugin else "${plugin}/${p.dirName}";
        in
        lib.nameValuePair "${pluginsDir}/${p.dirName}" { inherit source; })
      androidStudioPlugins);

    androidStudioOptions = {
      "editor-font.xml" = ''
        <application>
          <component name="DefaultFont">
            <option name="VERSION" value="1" />
            <option name="FONT_SIZE" value="14" />
            <option name="FONT_SIZE_2D" value="14.0" />
            <option name="FONT_FAMILY" value="${vayoriTheme.font}" />
            <option name="FONT_BOLD_SUB_FAMILY" value="Regular" />
            <option name="LINE_SPACING" value="1.0" />
          </component>
        </application>
      '';

      "laf.xml" = ''
        <application>
          <component name="LafManager">
            <laf themeId="71b26d33-3d44-42f4-8166-31b17c762b32" />
          </component>
        </application>
      '';

      "colors.scheme.xml" = ''
        <application>
          <component name="EditorColorsManagerImpl">
            <global_color_scheme name="${matugenSchemeName}" />
          </component>
        </application>
      '';

      "one_dark_config.xml" = ''
        <application>
          <component name="OneDarkConfig">
            <option name="version" value="5.14.2" />
          </component>
        </application>
      '';

      "vim_settings.xml" = ''
        <application>
          <component name="VimSettings">
            <state version="7" enabled="true" />
          </component>
        </application>
      '';
    };

    optionFiles = lib.mapAttrs'
      (name: text: lib.nameValuePair "${optionsDir}/${name}" { inherit text; })
      androidStudioOptions;

    # Editor color scheme matugen renders on every wallpaper change (matugen
    # writes matugenOutputPath itself at runtime - it's deliberately not
    # declared as a home.file so home-manager never fights it for ownership).
    # DMS has no built-in JetBrains/Android Studio matugen integration, so
    # this is a from-scratch template dropped into matugen's *own* discovery
    # path for user config fragments.
    matugenIclsTemplate = ''
      <scheme name="${matugenSchemeName}" version="142" parent_scheme="Darcula">
        <metaInfo>
          <property name="created">Generated by matugen via DankMaterialShell</property>
          <property name="ide">idea</property>
          <property name="originalScheme">${matugenSchemeName}</property>
        </metaInfo>
        <colors>
          <option name="CARET_COLOR" value="{{colors.primary.default.hex_stripped}}" />
          <option name="CARET_ROW_COLOR" value="{{colors.surface_container.default.hex_stripped}}" />
          <option name="GUTTER_BACKGROUND" value="{{colors.surface.default.hex_stripped}}" />
          <option name="INDENT_GUIDE" value="{{colors.outline_variant.default.hex_stripped}}" />
          <option name="LINE_NUMBERS_COLOR" value="{{colors.on_surface_variant.default.hex_stripped}}" />
          <option name="RIGHT_MARGIN_COLOR" value="{{colors.outline_variant.default.hex_stripped}}" />
          <option name="SELECTION_BACKGROUND" value="{{colors.primary_container.default.hex_stripped}}" />
          <option name="SELECTION_FOREGROUND" value="{{colors.on_primary_container.default.hex_stripped}}" />
          <option name="TEARLINE_COLOR" value="{{colors.outline_variant.default.hex_stripped}}" />
        </colors>
        <attributes>
          <option name="TEXT">
            <value>
              <option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" />
              <option name="BACKGROUND" value="{{colors.background.default.hex_stripped}}" />
            </value>
          </option>
          <option name="DEFAULT_KEYWORD">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_STRING">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_NUMBER">
            <value><option name="FOREGROUND" value="{{colors.secondary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_FUNCTION_CALL">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_FUNCTION_DECLARATION">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_CLASS_NAME">
            <value><option name="FOREGROUND" value="{{colors.secondary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_INSTANCE_FIELD">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_CONSTANT">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_IDENTIFIER">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_OPERATION_SIGN">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_BRACES">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_DOT">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_SEMICOLON">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_LINE_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_BLOCK_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_DOC_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_TEMPLATE_LANGUAGE_COLOR">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
        </attributes>
      </scheme>
    '';

    matugenConfigFragment = ''
      [templates.dmsandroidstudio]
      input_path = '${matugenTemplatePath}'
      output_path = '${matugenOutputPath}'
    '';

    matugenFiles = {
      "${dmsMatugenDirRel}/templates/android-studio-colors.icls" = { text = matugenIclsTemplate; };
      "${dmsMatugenDirRel}/configs/android-studio.toml" = { text = matugenConfigFragment; };
    };
  in {
    home.packages = with pkgs; [
      androidStudioPackages.stable
      jdk17
      android-tools
    ];

    home.sessionVariables = {
      ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
      ANDROID_HOME = "$HOME/Android/Sdk";
      CHROME_EXECUTABLE = "zen";
    };

    home.file = pluginFiles // optionFiles // matugenFiles;
  };
}
