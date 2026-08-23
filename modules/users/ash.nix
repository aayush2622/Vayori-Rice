{ self, inputs, ... }: {
  flake.nixosModules.userAsh = { pkgs, ... }: {
    vayori.users.ash = {
      fullName = "Ash";
      extraGroups = [ "networkmanager" "wheel" "video" "input" "adbusers" "docker" ];

      # Generate with: mkpasswd -m sha-512
      hashedPassword = "$6$REDACTED$REDACTEDREDACTEDREDACTED";
      
      # avatar = ./avatars/ash.png;

      # extraPackages = with pkgs; [ ];
    };
  };
}
