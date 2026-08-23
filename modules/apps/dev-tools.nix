{ self, inputs, ... }: {
  flake.homeModules.apps."dev-tools" = { pkgs, ... }: {
    home.packages = with pkgs; [
      vscode
      # git itself is already in the base systemPackages (hosts/Diablo/
      # configuration.nix) - flakes need it system-wide regardless of apps.
      gh
      lazygit
      docker-compose
    ];
    # The docker daemon itself is enabled once for everyone in
    # modules/features/dev-system.nix; add "docker" to your extraGroups in
    # your users/<you>.nix file to use it without sudo.
  };
}
