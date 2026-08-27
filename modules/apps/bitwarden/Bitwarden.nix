{ self, inputs, ... }: {
  flake.homeModules.apps.Bitwarden = { pkgs, ... }: {
    home.packages = [ pkgs.bitwarden-desktop pkgs.pinentry-gtk2 ];

    programs.rbw = {
      enable = true;
    };
  };
}
