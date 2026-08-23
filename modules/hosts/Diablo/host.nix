{ self, inputs, ... }: {
  flake.nixosConfigurations.Diablo = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = [
      inputs.home-manager.nixosModules.home-manager

      self.nixosModules.vayoriUsers
      self.nixosModules.niri
      self.nixosModules.dms
      self.nixosModules.fonts
      self.nixosModules.portals
      self.nixosModules.sddmTheme
      self.nixosModules.grubTheme
      self.nixosModules.devSystem

      ./_hardware.nix

      ({ pkgs, lib, config, ... }: {
        vayori.users = {
          ash = {
            fullName = "Ash";
            extraGroups = [ "networkmanager" "wheel" "video" "input" "adbusers" "docker" ];
            hashedPassword = "$6$REDACTED$REDACTEDREDACTEDREDACTED";
          };

          random = {
            fullName = "Random";
            extraGroups = [ "networkmanager" "video" "input" ];
          };
        };

        vayori.apps = [
          "terminal"
          "nautilus"
          "zen-browser"
          "vesktop"
          "android-studio"
          "spicetify"
          "dev-tools"
        ];

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nixpkgs.config.allowUnfree = true;

        nix.settings.auto-optimise-store = true;
        documentation.nixos.enable = false;

        boot.loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = false;
          grub = {
            enable = true;
            efiSupport = true;
            device = "nodev";
            useOSProber = true;
          };
        };

        networking.hostName = "Diablo";
        networking.networkmanager.enable = true;

        time.timeZone = "Asia/Kolkata";
        i18n.defaultLocale = "en_IN";
        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_IN";
          LC_IDENTIFICATION = "en_IN";
          LC_MEASUREMENT = "en_IN";
          LC_MONETARY = "en_IN";
          LC_NAME = "en_IN";
          LC_NUMERIC = "en_IN";
          LC_PAPER = "en_IN";
          LC_TELEPHONE = "en_IN";
          LC_TIME = "en_IN";
        };

        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        hardware.bluetooth.enable = true;
        services.power-profiles-daemon.enable = true;
        services.upower.enable = true;

        services.printing.enable = true;

        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        services.udisks2.enable = true;
        programs.dconf.enable = true;
        services.gvfs.enable = true;
        services.tumbler.enable = true;

        environment.systemPackages = with pkgs; [
          vim
          wget
          curl
          git
          unzip
          zip
          htop
          btop
          ripgrep
          fd
          fzf
          tree
          killall
          gnumake
          nixfmt
          nil
          cliphist
          wl-clipboard
          grim
          slurp
          hyprpicker
          playerctl
          brightnessctl
          pavucontrol
          adwaita-icon-theme
          bibata-cursors
        ];
        environment.sessionVariables = {
          XCURSOR_THEME = "Bibata-Modern-Ice";
          XCURSOR_SIZE = "24";
        };

        services.displayManager.sddm.settings = {
          Theme = {
            CursorTheme = "Bibata-Modern-Ice";
            CursorSize = 24;
          };
        };

        systemd.services.display-manager.environment = {
          XCURSOR_THEME = "Bibata-Modern-Ice";
          XCURSOR_SIZE = "24";
        };

        system.stateVersion = "25.11";
      })
    ];
  };
}
