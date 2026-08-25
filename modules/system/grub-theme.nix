{ self, inputs, ... }: {
  flake.nixosModules.grubTheme = { pkgs, ... }: {
    boot.loader.grub.theme = "${inputs.grub-theme}/SekiroShadow";
  };
}
