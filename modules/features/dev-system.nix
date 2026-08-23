{ self, inputs, ... }: {
  flake.nixosModules.devSystem = { lib, ... }: {
    virtualisation.docker.enable = true;
    virtualisation.libvirtd.enable = lib.mkDefault false;
    users.groups.adbusers = { };
  };
}
