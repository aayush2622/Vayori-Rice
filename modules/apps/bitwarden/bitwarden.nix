{ self, inputs, ... }: {
  flake.homeModules.apps.bitwarden = { pkgs, ... }: {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
