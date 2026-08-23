{ self, inputs, ... }: {
  flake.homeModules.apps.vesktop = { pkgs, ... }: {
    home.packages = with pkgs; [ vesktop ];
    # Themed automatically once "discord" is enabled under Settings ->

  };
}
