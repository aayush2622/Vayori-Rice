{ self, inputs, ... }: {
  flake.nixosModules.DiabloConfig = { pkgs, lib, config, ... }: {

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nixpkgs.config.allowUnfree = true;

    # ---- Who lives here -------------------------------------------------
    # Accounts are defined per-person in modules/users/ash.nix,
    # modules/users/random.nix, etc. - see modules/users/users.nix for the
    # options each of those files can set (name is the attribute key,
    # plus fullName/password/groups/extraPackages).

    # ---- Apps everyone on THIS MACHINE gets --------------------------------
    # Pick from whatever file names exist in modules/apps/. This is the one
    # thing a new machine's config usually needs to change - everything else
    # in this file can normally stay as-is.
    vayori.apps = [
      "terminal"
      "nautilus"
      "zen-browser"
      "vesktop"
      "android-studio"
      "spicetify"
      "dev-tools"
    ];

    # ---- Bootloader -------------------------------------------------------
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

    # ---- Networking / locale ----------------------------------------------
    networking.hostName = "nixos";
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

    # ---- Wayland / niri session --------------------------------------------
    # No xserver/desktopManager here: niri is a Wayland-native compositor.
    # `programs.niri.enable` is turned on in features/niri.nix; SDDM is
    # turned on and themed in features/sddm-qylock.nix.
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Required by Noctalia for wifi/bluetooth/power/battery widgets.
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
    # GNOME's file-manager needs its own services for search/trash/thumbnails.
    services.gvfs.enable = true;
    services.tumbler.enable = true;

    # ---- Base CLI packages only; everything "app" lives in modules/apps ----
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
      fastfetch
      grim
      slurp
      hyprpicker # works standalone on niri too, used for color picking
      playerctl
      brightnessctl
      pavucontrol
      adwaita-icon-theme
    ];
    environment.sessionVariables = {
      XCURSOR_THEME = "Adwaita";
      XCURSOR_SIZE = "24";
    };

    services.displayManager.sddm.settings = {
      Theme = {
        CursorTheme = "Adwaita";
        CursorSize = 24;
      };
    };

    system.stateVersion = "25.11";
  };
}
