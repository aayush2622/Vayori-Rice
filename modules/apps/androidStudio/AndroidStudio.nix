{ self, inputs, ... }:
let
  androidStudioPluginsSpec = [
    { dirName = "Catppuccin Theme"; id = "com.github.catppuccin.jetbrains"; version = "3.6.1"; hash = "sha256-JQwlFCAUs5Du/itRwmnPMRB5iw/3adRC3zN9tnsfDqU="; }
    { dirName = "claude-code-jetbrains-plugin"; id = "com.anthropic.code.plugin"; version = "0.1.14-beta"; hash = "sha256-usZ6r0YZrOERPf7MO8aq9cAU25yWggOa6avNEGwzgJY="; }
    { dirName = "Dart"; id = "Dart"; version = "508.1.0"; hash = "sha256-jq79eTX1EZVcSptEv9VwcguTZkNuJj/WeV2JsEyqUxk="; }
    { dirName = "Flutter Enhancement Suite"; id = "de.mariushoefler.flutter_enhancement_suite"; version = "1.7.1"; hash = "sha256-ToB0GQI4gzTyVyceWwMEqnT/yACNL2z1lOHQ7RQ7gM0="; }
    { dirName = "flutter-intellij"; id = "io.flutter"; version = "95.0.0"; hash = "sha256-Io0sO1uEDvKsiVjzD6VUA7lkVVfHWvLMSN2e93SnDlc="; }
    { dirName = "flutter-intl"; id = "com.localizely.flutter-intl"; version = "1.18.8-2024.2"; hash = "sha256-gFHYR9ZYLR7rhwPw8BpZ89Sl8hFsaZPFhiGpbwBPRJE="; }
    { dirName = "github-copilot-intellij"; id = "com.github.copilot"; version = "1.16.1-251"; hash = "sha256-LM2pLbOyOc2R3E90LSlbBxiGNWkzqG5pimKxvswaPQg="; }
    { dirName = "git-worktree-manager"; id = "com.purringlabs.gitworktree.git-worktree-manager"; version = "1.1.27"; hash = "sha256-avwWW6hW8tQx18tEmtZhOcSyh3sFol/MYstSIQBN+cM="; }
    { dirName = "JetBrains-Discord-Integration"; id = "dev.azn9.plugins.discord"; version = "2.1.10.242"; hash = "sha256-rkCvxroVNVjC4Y9kwlQesmrqbQ4sR31/Z9A+avrAyYI="; }
    { dirName = "kmm-plugin"; id = "com.jetbrains.kmm"; version = "262.10315.69-IJ"; hash = "sha256-BtSjt0kViTos8AW0/+JOHjPqhJE0CwaDbsVtlMxtKTA="; }
    { dirName = "lsp4ij"; id = "com.redhat.devtools.lsp4ij"; version = "0.20.1"; hash = "sha256-0ysAQkzi1C+p/olcf6c0Kz3HzphcdHqf/PNq9TqKnBM="; }
    { dirName = "NixIDEA"; id = "nix-idea"; version = "0.4.0.22"; hash = "sha256-QLOnvM+7r4x+5eaptrP/5JlQPskluj+hoYCR/xCXKJk="; }
    { dirName = "one-dark-theme"; id = "com.markskelton.one-dark-theme"; version = "6.2.5"; hash = "sha256-RtlUjQhE4+J6kFauVNBVg14LorzYg4C39CLOkVo5mvs="; }
    { dirName = "python-ce"; id = "PythonCore"; version = "262.10315.69"; hash = "sha256-5WzXkpxsxniUkxQDS8Fu2leL7NFChCsxu4UzJiQ01xM="; }
    { dirName = "vcs-perforce"; id = "PerforceDirectPlugin"; version = "262.8665.176"; hash = "sha256-kATFksb4/BHWSST6VYueTSlVbnyrHFIex++W5Sx1bxo="; }
    { dirName = "vcs-svn"; id = "Subversion"; version = "262.10315.84"; hash = "sha256-m0eUlnHApDcXFiVIwOfdF5dtudUUppjUPkvbE4blcWs="; }
    { dirName = "WakaTime.jar"; id = "com.wakatime.intellij.plugin"; version = "16.1.2"; hash = "sha256-KnHRvFUtsH4vJDF+YhSoP7YpV52Jqoe2AiMwORDiPOQ="; isJar = true; }
  ];
in {
  flake.pluginPins.AndroidStudio = androidStudioPluginsSpec;

  flake.homeModules.apps.AndroidStudio = { pkgs, lib, config, vayoriTheme, ... }:
  let
    configDataDir = "AndroidStudio2026.1.3";
    pluginsDir = ".local/share/Google/${configDataDir}";
    optionsDir = ".config/Google/${configDataDir}/options";
    colorsDir = ".config/Google/${configDataDir}/colors";

    matugenDirRel = ".config/matugen";
    matugenDir = "${config.home.homeDirectory}/${matugenDirRel}";
    matugenSchemeName = "DankMatugen";
    matugenTemplatePath = "${matugenDir}/templates/android-studio-colors.icls";
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

    androidStudioPlugins = androidStudioPluginsSpec;

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

    matugenIclsTemplate = self.matugenTemplates.androidStudio matugenSchemeName;

    matugenFiles = {
      "${matugenDirRel}/templates/android-studio-colors.icls" = { text = matugenIclsTemplate; };
    };

    androidStudioFccEnv = {
      ANTHROPIC_BASE_URL = "http://localhost:8082";
      ANTHROPIC_AUTH_TOKEN = "freecc";
      CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
      CLAUDE_CODE_AUTO_COMPACT_WINDOW = "190000";
      DISABLE_AUTOUPDATER = "1";
      DISABLE_FEEDBACK_COMMAND = "1";
      DISABLE_ERROR_REPORTING = "1";
    };

    androidStudioWithFcc = pkgs.symlinkJoin {
      name = "android-studio-with-fcc";
      paths = [ pkgs.androidStudioPackages.stable ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/android-studio \
          ${lib.concatStringsSep " " (lib.mapAttrsToList (n: v: "--set ${n} ${lib.escapeShellArg v}") androidStudioFccEnv)}
      '';
    };
  in {
    home.packages = with pkgs; [
      androidStudioWithFcc
      jdk17
      android-tools
    ];

    home.sessionVariables = {
      ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
      ANDROID_HOME = "$HOME/Android/Sdk";
      CHROME_EXECUTABLE = "zen";
    };

    home.file = pluginFiles // optionFiles // matugenFiles;

    vayori.matugenTemplates.androidStudio = ''
      [templates.androidStudio]
      input_path = '${matugenTemplatePath}'
      output_path = '${matugenOutputPath}'
    '';
  };
}
