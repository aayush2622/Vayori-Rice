{ self, inputs, ... }: {
  flake.nixosModules.userRandom = { pkgs, ... }: {
    vayori.users.random = {
      fullName = "Random";
      # No "wheel" here -> this account can't sudo. Add it if they need admin.
      extraGroups = [ "networkmanager" "video" "input" ];

      # Generate with: mkpasswd -m sha-512
      # hashedPassword = "$6$....";

      # avatar = ./avatars/random.png;

      # Apps are no longer picked per-user - see vayori.apps in
      # hosts/<machine>/configuration.nix, everyone on the machine shares it.

      # extraPackages = with pkgs; [ ];
    };
  };
}
