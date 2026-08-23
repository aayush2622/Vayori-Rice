{ self, inputs, ... }: {
  flake.nixosConfigurations.Diablo = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = [
      inputs.home-manager.nixosModules.home-manager

      self.nixosModules.vayoriUsers
      self.nixosModules.DiabloHardware
      self.nixosModules.DiabloConfig

      # ---- Everyone on this machine, one file each --------------------
      self.nixosModules.userAsh
      self.nixosModules.userRandom

      self.nixosModules.niri
      self.nixosModules.dms
      self.nixosModules.fonts
      self.nixosModules.portals
      self.nixosModules.sddmTheme
      self.nixosModules.grubTheme
      self.nixosModules.devSystem
    ];
  };
}
