{ self, inputs, ... }: {
  flake.nixosModules.portals = { pkgs, ... }: {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = [ "gnome" "gtk" ];
    };

    security.polkit.enable = true;
  };
}
