{ self, inputs, ... }: {
  flake.nixosModules.GrubTheme = {
    imports = [ inputs.elegant-grub2-themes.nixosModules.default ];

    boot.loader.elegant-grub2-theme = {
      enable = true;
      theme = "wave";
      type = "window";
      side = "left";
      color = "dark";
      screen = "1080p";
    };
  };
}
