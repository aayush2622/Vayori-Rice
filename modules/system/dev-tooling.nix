{ self, inputs, ... }: {
  flake.nixosModules.devTooling = { lib, ... }: {
    virtualisation.docker.enable = true;
    virtualisation.libvirtd.enable = lib.mkDefault false;
    users.groups.adbusers = { };
  };
}
