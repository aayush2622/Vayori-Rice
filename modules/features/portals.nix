{ self, inputs, ... }: {
  flake.nixosModules.portals = { pkgs, ... }: {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome  # file pickers, screenshots, screencast (works well with niri)
        pkgs.xdg-desktop-portal-gtk    # GTK file chooser used by Nautilus & friends
      ];
      config.common.default = [ "gnome" "gtk" ];
    };

    security.polkit.enable = true;
  };
}
