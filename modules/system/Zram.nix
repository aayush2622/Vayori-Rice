{ self, inputs, ... }: {
  flake.nixosModules.Zram = {
    zramSwap.enable = true;
  };
}
