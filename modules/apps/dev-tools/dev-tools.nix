{ self, inputs, ... }: {
  flake.homeModules.apps."dev-tools" = { pkgs, ... }: {
    home.packages = with pkgs; [
      gh
      lazygit
      docker-compose
    ];
  };
}
