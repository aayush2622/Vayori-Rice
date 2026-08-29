{ self, ... }: {
  flake.homeModules.apps.Zed = { pkgs, lib, config, vayoriTheme, vayoriApps, ... }:
  let
    enabledLanguages = lib.filterAttrs (name: _: builtins.elem name vayoriApps) self.devLanguages;
    languageZed = lib.mapAttrsToList (_: l: l.zed or { }) enabledLanguages;

    languageExtensions = lib.unique (lib.concatMap (v: v.extensions or [ ]) languageZed);
    languageSettings = lib.foldl' lib.recursiveUpdate { } (map (v: v.settings or { }) languageZed);

    extensions = [
      "catppuccin"
      "catppuccin-icons"
      "color-highlight"
      "discord-presence"
      "html"
      "one-dark-pro-enhanced"
      "toml"
      "wakatime"
    ] ++ languageExtensions;

    settings = lib.recursiveUpdate {
      git = {
        inline_blame.show_commit_summary = true;
        branch_picker.show_author_name = true;
        disable_git = false;
      };
      git_panel.dock = "left";
      autosave = "on_focus_change";
      icon_theme = "Catppuccin Mocha";
      cli_default_open_behavior = "existing_window";
      project_panel.dock = "left";
      ui_font_weight = 400.0;
      ui_font_family = vayoriTheme.font;
      buffer_font_family = vayoriTheme.font;
      ui_font_size = 16;
      buffer_font_size = 15;
      base_keymap = "JetBrains";
      theme = "Matugen";
      session.trust_all_worktrees = true;
      agent = {
        default_model = {
          provider = "copilot_chat";
          model = "gpt-5-mini";
          enable_thinking = true;
          effort = "high";
        };
        favorite_models = [ ];
        model_parameters = [ ];
      };
      agent_servers = {
        "codex-acp".type = "registry";
        "github-copilot-cli".type = "registry";
      };
    } languageSettings;
  in {
    programs.zed-editor = {
      enable = true;
      inherit extensions;
      userSettings = settings;
    };

    home.file.".config/matugen/templates/zed-theme.json".text = self.matugenTemplates.zed;

    vayori.matugenTemplates.zed = ''
      [templates.zed]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/zed-theme.json'
      output_path = '${config.home.homeDirectory}/.config/zed/themes/matugen.json'
    '';
  };
}
