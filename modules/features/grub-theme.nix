{ self, inputs, ... }: {
  flake.nixosModules.grubTheme = { pkgs, ... }: {
    # grubphemous-theme isn't a flake or a nix package, it's a plain repo
    # meant to be installed with its own shell script. We fetch its source
    # via the flake input and point GRUB straight at the theme directory
    # inside it, which is exactly what `boot.loader.grub.theme` expects
    # (a directory containing theme.txt).
    #
    # NOTE: double-check the exact subfolder name after your first
    # `nixos-rebuild switch` - if grub doesn't pick it up, run:
    #   ls ${inputs.grub-theme}
    # in a `nix repl` and adjust the path below to match (the repo's
    # install script normally copies a `grubphemous/` folder containing
    # theme.txt + background.png).
    boot.loader.grub.theme = "${inputs.grub-theme}/SekiroShadow";
  };
}
