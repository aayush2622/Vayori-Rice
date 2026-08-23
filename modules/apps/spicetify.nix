{ self, inputs, ... }: {
  flake.homeModules.apps."spicetify" = { pkgs, config, ... }:
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

      theme = spicePkgs.themes.hazy;
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