{ self, inputs, ... }: {
  flake.homeModules.apps.vesktop = { pkgs, ... }: {
    home.packages = with pkgs; [ vesktop ];
  };
}
