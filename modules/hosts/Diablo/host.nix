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
        options.vayori.theme = lib.mkOption {
          description = "System-wide look & feel - one place to set the font, cursor theme, and icon theme, used everywhere they're needed.";
          default = { };
          type = lib.types.submodule {
            options = {
              font = lib.mkOption {
                type = lib.types.str;
                default = "JetBrainsMono Nerd Font";
                description = "UI/monospace font family, used by fontconfig, GTK, kitty, and DMS.";
              };
              fontPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.nerd-fonts.jetbrains-mono;
                description = "Package providing `font`.";
              };
              fontSize = lib.mkOption {
                type = lib.types.int;
                default = 11;
              };

              cursorTheme = lib.mkOption {
                type = lib.types.str;
                default = "Bibata-Modern-Ice";
                description = "Xcursor theme name, used by GTK, SDDM, and XCURSOR_THEME.";
              };
              cursorPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.bibata-cursors;
                description = "Package providing `cursorTheme`.";
              };
              cursorSize = lib.mkOption {
                type = lib.types.int;
                default = 24;
              };

              iconTheme = lib.mkOption {
                type = lib.types.str;
                default = "Tela-circle";
                description = "GTK icon theme name.";
              };
              iconPackage = lib.mkOption {
                type = lib.types.package;
                default = pkgs.tela-circle-icon-theme;
                description = "Package providing `iconTheme`.";
              };
            };
          };
        };

        config = {
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
            "gaming"
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
          services.upower.enable = true;

          services.printing.enable = true;

          programs.gamemode.enable = true;

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
            config.vayori.theme.cursorPackage
          ];
          environment.sessionVariables = {
            XCURSOR_THEME = config.vayori.theme.cursorTheme;
            XCURSOR_SIZE = toString config.vayori.theme.cursorSize;
          };

          services.displayManager.sddm.settings.Theme = {
            CursorTheme = config.vayori.theme.cursorTheme;
            CursorSize = config.vayori.theme.cursorSize;
          };

          services.displayManager.sddm.settings.General.GreeterEnvironment =
            "XCURSOR_THEME=${config.vayori.theme.cursorTheme},XCURSOR_SIZE=${toString config.vayori.theme.cursorSize},XCURSOR_PATH=${config.vayori.theme.cursorPackage}/share/icons";

          systemd.services.display-manager.environment = {
            XCURSOR_THEME = config.vayori.theme.cursorTheme;
            XCURSOR_SIZE = toString config.vayori.theme.cursorSize;
            XCURSOR_PATH = "${config.vayori.theme.cursorPackage}/share/icons";
          };

          system.stateVersion = "25.11";
        };
      })
    ];
  };
}
