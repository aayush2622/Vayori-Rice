{ self, inputs, ... }: {
  flake.nixosModules.SddmTheme = { pkgs, ... }:

let
  womenUmbrella = pkgs.stdenvNoCC.mkDerivation {
    name = "women-umbrella";

    src = ./Theme;

    installPhase = ''
      mkdir -p $out/share/sddm/themes/women-umbrella
      cp -r . $out/share/sddm/themes/women-umbrella
    '';
  };
in
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  services.displayManager.sddm.theme =
    "${womenUmbrella}/share/sddm/themes/women-umbrella";
};
}
