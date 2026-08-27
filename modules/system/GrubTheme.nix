{ self, inputs, ... }: {
  flake.nixosModules.GrubTheme = { pkgs, ... }: {
    boot.loader.grub.theme = "${inputs.grub-theme}/SekiroShadow";
  };
}
