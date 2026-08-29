{ pkgs, shaderCacheDir, ... }:
let
  gamescopeFhd = pkgs.writeShellScriptBin "gamescope-fhd" ''
    exec ${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -f --adaptive-sync -- "$@"
  '';

  gamescopeFsr = pkgs.writeShellScriptBin "gamescope-fsr" ''
    exec ${pkgs.gamescope}/bin/gamescope -w 1600 -h 900 -W 1920 -H 1080 -F fsr -f --adaptive-sync -- "$@"
  '';

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
in
{
  home.packages = [
    pkgs.gamescope
    gamescopeFhd
    gamescopeFsr
  ];

  home.file."Games/.cache/nv-shaders/.keep".text = "";

  home.sessionVariables = {
    __GL_SHADER_DISK_CACHE_PATH = shaderCacheDir;
  };

  programs.mangohud = {
    enable = true;
    settings = mangoHudSettings;
  };
}
