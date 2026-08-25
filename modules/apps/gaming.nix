{ self, inputs, ... }: {
  flake.homeModules.apps.gaming = { pkgs, config, ... }: {
    home.packages = with pkgs; [
      lutris
      heroic
      umu-launcher
      protonup-qt
      winetricks
      protontricks
      gamescope
    ];

    home.file."Games/.keep".text = "";

    home.sessionVariables.WINEPREFIX = "${config.home.homeDirectory}/Games/.wineprefix";

    programs.mangohud = {
      enable = true;
      settings = {
        fps = true;
        frametime = true;
        cpu_temp = true;
        gpu_temp = true;
        gpu_load_change = true;
        ram = true;
        vram = true;
        position = "top-left";
      };
    };
  };
}
