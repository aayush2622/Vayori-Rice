{ self, inputs, ... }: {
  flake.homeModules.apps."dev-tools" = { pkgs, ... }: {
    home.packages = with pkgs; [
      vscode
      gh
      lazygit
      docker-compose
    ];
  };
}
