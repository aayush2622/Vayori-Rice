{ self, inputs, ... }: {
  flake.homeModules.baseline = { pkgs, config, vayoriTheme, ... }:
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

      # DMS's matugen GTK templates always write dank-colors.css (no
      # detection gate on the write side - confirmed in
      # core/internal/matugen/matugen.go, TemplateKindGTK's appendConfig
      # call passes nil check lists, which appExists treats as
      # "unconditional"), but GTK itself only auto-loads gtk.css - nothing
      # imports the generated file without this. It also doubles as the
      # *read* side of DMS's own isDMSGTKActive() gate, which checks for
      # this exact "dank-colors.css" substring before firing live GTK
      # refresh signals on each matugen run.
      gtk3.extraCss = ''@import url("dank-colors.css");'';
      gtk4.extraCss = ''@import url("dank-colors.css");'';
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
      # No style.name override (Kvantum previously) - QT_STYLE_OVERRIDE
      # would force every Qt app onto Kvantum's own separate SVG theme
      # regardless of platformTheme, bypassing qt5ct/qt6ct - and matugen
      # only ever generates qt5ct/qt6ct's native palette format, no
      # Kvantum template exists. Leaving style unset lets qt5ct/qt6ct's
      # own palette (written below) actually apply.
    };

    home.packages = with pkgs; [
      libsForQt5.qt5ct
      qt6Packages.qt6ct
    ];

    # matugen writes the palette itself (~/.config/qt{5,6}ct/colors/matugen.conf,
    # rewritten on every wallpaper change) but never points qt5ct/qt6ct at
    # it - same "updates an existing setup, never installs one" pattern as
    # everywhere else DMS integrates. This pointer is the one-time setup
    # matugen assumes already exists (refreshQt6ct() just touches this
    # file's mtime to nudge already-running apps, it never writes it).
    home.file = {
      ".local/share/themes/adw-gtk3".source = "${pkgs.adw-gtk3}/share/themes/adw-gtk3";

      ".config/qt5ct/qt5ct.conf".text = ''
        [Appearance]
        custom_palette=true
        color_scheme_path=${config.home.homeDirectory}/.config/qt5ct/colors/matugen.conf
        icon_theme=${theme.iconTheme}
        style=Fusion
      '';

      ".config/qt6ct/qt6ct.conf".text = ''
        [Appearance]
        custom_palette=true
        color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/matugen.conf
        icon_theme=${theme.iconTheme}
        style=Fusion
      '';
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
    };
  };
}
