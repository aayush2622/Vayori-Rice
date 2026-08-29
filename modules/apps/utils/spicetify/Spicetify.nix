{ self, inputs, ... }: {
  flake.homeModules.apps.Spicetify = { pkgs, config, vayoriTheme, ... }:
  let
    spicePkgs =
      inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  in {
    imports = [
      inputs.spicetify-nix.homeManagerModules.default
    ];

    programs.spicetify = {
      enable = true;

      spicetifyPackage = pkgs.spicetify-cli;

      theme = spicePkgs.themes.hazy // {
        extraPkgs = [ vayoriTheme.fontPackage ];
        additionalCss = ''
          :root {
            --font-family: "${vayoriTheme.font}", sans-serif !important;
          }
        '';
      };
      colorScheme = "Base";

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        hidePodcasts
        shuffle
        fullAppDisplay
      ];

      enabledCustomApps = with spicePkgs.apps; [
        lyricsPlus
      ];
    };

  };
}