{ self, inputs, ... }: {
  flake.homeModules.apps.nautilus = { pkgs, ... }: {
    home.packages = with pkgs; [
      nautilus

      # Nautilus extensions
      nautilus-open-any-terminal
      sushi
      file-roller

      # Search
      tinysparql
      localsearch

      # Thumbnailers
      ffmpegthumbnailer
      poppler
      librsvg
      webp-pixbuf-loader
    ];
    dconf.settings = {
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";

        recursive-search = "local-only";
        search-filter-time-type = "last_modified";

        show-image-thumbnails = "always";
        show-directory-item-counts = "local-only";
        # Thumbnail bigger files instead of falling back to a generic icon.
        thumbnail-limit = 200;

        show-delete-permanently = true;
        show-create-link = true;

        click-policy = "double";

        # Back/forward mouse buttons navigate history.
        mouse-use-extra-buttons = true;
        # Auto-enter a hovered folder mid drag-and-drop instead of
        # requiring a manual click.
        open-folder-on-dnd-hover = true;

        migrated-gtk-settings = true;
      };

      "org/gnome/nautilus/icon-view" = {
        # Options: small, standard, large
        default-zoom-level = "standard";
      };

      "org/gnome/nautilus/list-view" = {
        default-zoom-level = "small";
        # Show file type alongside name/size/date in list view.
        default-visible-columns = [ "name" "size" "type" "date_modified" ];
      };

      "org/gnome/nautilus/window-state" = {
        # Open Files maximized instead of the cramped 890x550 default.
        maximized = true;
      };

      # Drives/USB sticks/SD cards: mount automatically, pop open a Files
      # window when they do, and never auto-run scripts from them.
      "org/gnome/desktop/media-handling" = {
        automount = true;
        automount-open = true;
        autorun-never = true;
      };

      # nautilus-open-any-terminal (installed below) defaults to
      # gnome-terminal, which isn't installed here - point it at kitty,
      # our actual terminal (see modules/apps/terminal.nix).
      "com/github/stunkymonkey/nautilus-open-any-terminal" = {
        terminal = "kitty";
        new-tab = true;
      };

      "org/gtk/settings/file-chooser" = {
        sort-directories-first = true;
        show-hidden = true;
        location-mode = "path-bar";
        clock-format = "12h";
        date-format = "regular";
        sort-column = "name";
        sort-order = "ascending";
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        sort-directories-first = true;
        show-hidden = true;
        location-mode = "path-bar";
        clock-format = "12h";
        date-format = "regular";
        sort-column = "name";
        sort-order = "ascending";
        view-type = "list";
      };
    };
    # gvfs + tumbler (thumbnails/mounting) are enabled system-wide in
    # hosts/Diablo/configuration.nix since they're daemons, not per-user.
  };
}
