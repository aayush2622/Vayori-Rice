{ self, inputs, ... }: {
  flake.nixosModules.Portals = { pkgs, ... }: {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      configPackages = [ pkgs.niri ];
    };

    security.polkit.enable = true;
  };
}
