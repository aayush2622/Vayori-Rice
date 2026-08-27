{ self, inputs, ... }: {
  flake.homeModules.apps.Gaming = { pkgs, lib, config, ... }:
  let
    gamesDir = "${config.home.homeDirectory}/Games";
    shaderCacheDir = "${gamesDir}/.cache/nv-shaders";

    gamescopeFhd = pkgs.writeShellScriptBin "gamescope-fhd" ''
      exec ${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -f --adaptive-sync -- "$@"
    '';

    gamescopeFsr = pkgs.writeShellScriptBin "gamescope-fsr" ''
      exec ${pkgs.gamescope}/bin/gamescope -w 1600 -h 900 -W 1920 -H 1080 -F fsr -f --adaptive-sync -- "$@"
    '';

    launchers = with pkgs; [ lutris heroic adwsteamgtk ];
    protonTooling = with pkgs; [ umu-launcher protonup-qt winetricks protontricks wine ];
    overlayTooling = [ pkgs.gamescope gamescopeFhd gamescopeFsr ];

    mangoHudSettings = {
      legacy_layout = false;
      horizontal = true;
      hud_compact = true;
      round_corners = 10;
      background_alpha = 0.45;
      font_size = 20;

      fps = true;
      frametime = true;
      cpu_stats = true;
      cpu_temp = true;
      cpu_load_change = true;
      gpu_stats = true;
      gpu_temp = true;
      gpu_load_change = true;
      ram = true;
      vram = true;

      position = "top-left";

      background_color = "1a1a2e";
      text_color = "ffffff";
      gpu_color = "4fd1c5";
      cpu_color = "63b3ed";
      vram_color = "b794f4";
      ram_color = "f6ad55";
      frametime_color = "68d391";
    };
  in {
    home.packages = launchers ++ protonTooling ++ overlayTooling;

    home.file = {
      "Games/.keep".text = "";
      "Games/.cache/nv-shaders/.keep".text = "";

      ".local/share/heroic-matugen-theme/matugen.json".text = builtins.toJSON {
        name = "Matugen";
        filename = "matugen.css";
      };

      ".config/matugen/templates/heroic-matugen.css".text = self.matugenTemplates.heroic;
      ".config/matugen/templates/steam-colors.css".text = self.matugenTemplates.steam;
      ".config/matugen/templates/wine-colors.reg".text = self.matugenTemplates.wine;
    };

    vayori.matugenTemplates = {
      heroic = ''
        [templates.heroic]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/heroic-matugen.css'
        output_path = '${config.home.homeDirectory}/.local/share/heroic-matugen-theme/matugen.css'
      '';

      steam = ''
        [templates.steam]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/steam-colors.css'
        output_path = '${config.home.homeDirectory}/.config/AdwSteamGtk/custom.css'
      '';

      wine = ''
        [templates.wine]
        input_path = '${config.home.homeDirectory}/.config/matugen/templates/wine-colors.reg'
        output_path = '/tmp/wine.reg'
        post_hook = 'test -d "${gamesDir}/.wineprefix" && WINEPREFIX="${gamesDir}/.wineprefix" nohup wine regedit /tmp/wine.reg > /dev/null 2>&1 &'
      '';
    };

    home.sessionVariables = {
      WINEPREFIX = "${gamesDir}/.wineprefix";
      __GL_SHADER_DISK_CACHE_PATH = shaderCacheDir;
    };

    xdg.configFile."lutris/runners/wine.yml" = {
      force = true;
      text = builtins.toJSON { wine = { version = "ge-proton"; }; };
    };

    programs.mangohud = {
      enable = true;
      settings = mangoHudSettings;
    };

    home.activation.gamesBookmark = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BOOKMARKS="$HOME/.config/gtk-3.0/bookmarks"
      GAMES_URI="file://${gamesDir} Games"
      $DRY_RUN_CMD mkdir -p "$(dirname "$BOOKMARKS")"
      $DRY_RUN_CMD touch "$BOOKMARKS"
      grep -qxF "$GAMES_URI" "$BOOKMARKS" 2>/dev/null || $DRY_RUN_CMD sh -c "printf '%s\n' \"$GAMES_URI\" >> \"$BOOKMARKS\""
    '';
  };
}
