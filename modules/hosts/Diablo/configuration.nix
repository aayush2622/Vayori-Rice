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

    # ---- Wayland / niri session --------------------------------------------
    # No xserver/desktopManager here: niri is a Wayland-native compositor.
    # `programs.niri.enable` is turned on in features/niri.nix; SDDM is
    # turned on and themed in features/sddm/sddm-theme.nix.
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
      bibata-cursors # the real cursor theme (see home/baseline.nix) - needs
                      # to be system-wide too, for SDDM's pre-login greeter
      # fastfetch is NOT listed here on purpose - "terminal" (below) already
      # brings it in via programs.fastfetch for every user on this host.
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

    # SDDM's Wayland greeter runs under Weston as its own systemd service,
    # so it never sees environment.sessionVariables above (that's only
    # exported to login shells via PAM, after you're already logged in).
    # Without XCURSOR_THEME/SIZE in the service's own environment, Weston
    # has no cursor theme to load and draws no pointer at all - hence no
    # mouse on the login screen.
    systemd.services.display-manager.environment = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };

    system.stateVersion = "25.11";
  };
}
