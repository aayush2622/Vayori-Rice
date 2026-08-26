{ self, inputs, ... }: {
  flake.homeModules.baseline = { pkgs, vayoriTheme, ... }:
  let theme = vayoriTheme; in
  {
    gtk = {
      enable = true;

      theme = {
        name = "adw-gtk3";
        package = pkgs.adw-gtk3;
      };

      gtk4.theme = null;

      iconTheme = {
        name = theme.iconTheme;
        package = theme.iconPackage;
      };

      cursorTheme = {
        name = theme.cursorTheme;
        package = theme.cursorPackage;
        size = theme.cursorSize;
      };

      font = {
        name = theme.font;
        size = theme.fontSize;
      };
    };
    home.pointerCursor = {
      enable = true;
      gtk.enable = true;

      package = theme.cursorPackage;
      name = theme.cursorTheme;
      size = theme.cursorSize;
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

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
    };

    home.file.".local/share/themes/adw-gtk3".source = "${pkgs.adw-gtk3}/share/themes/adw-gtk3";
  };
}
