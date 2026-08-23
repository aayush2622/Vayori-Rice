{ self, inputs, ... }: {
  flake.homeModules.apps."dev-tools" = { pkgs, ... }: {
    home.packages = with pkgs; [
      vscode
      git
      gh
      lazygit
      docker-compose
    ];
    # The docker daemon itself is enabled once for everyone in
    # modules/features/dev-system.nix; add "docker" to your extraGroups in
    # your users/<you>.nix file to use it without sudo.
  };
}
