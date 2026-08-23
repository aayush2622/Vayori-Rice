{ self, inputs, ... }: {
  # Imported for every user in modules/users/users.nix - GTK/Qt theming is
  # the one piece of the rice nobody opts out of.
  flake.homeModules.baseline = { pkgs, ... }: {
    gtk = {
      enable = true;

      iconTheme = {
        name = "Tela-circle";
        package = pkgs.tela-circle-icon-theme;
      };

      cursorTheme = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 24;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "qtct"; 
      style.name = "kvantum";
    };

    home.packages = with pkgs; [
      qt6Packages.qt6ct
      kdePackages.qtstyleplugin-kvantum
      libsForQt5.qtstyleplugin-kvantum
    ];
  };
}
