{ self, inputs, ... }: {
  # Small always-on system services that per-user app packages depend on.
  # Installing the *package* (android-studio, docker-compose, ...) is
  # per-user via modules/apps/, but the daemon/kernel bits below have to be
  # system-wide - they're cheap to leave on even if nobody opted in.
  flake.nixosModules.devSystem = { lib, ... }: {
    virtualisation.docker.enable = true; # needs "docker" group
    virtualisation.libvirtd.enable = lib.mkDefault false; # flip to true for the Android emulator's KVM accel
  };
}
