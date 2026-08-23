{ self, inputs, ... }: {
  # This is the ONLY file that needs to understand how a "user" is built.
  # Each person gets their own file (see ash.nix / random.nix) that just
  # fills in `vayori.users.<name> = { ... }` with account info (name,
  # password, groups, shell). Apps are picked ONCE PER MACHINE via
  # `vayori.apps` in hosts/<machine>/configuration.nix - every user on
  # that machine gets the same set. Add a new person by copying one of
  # the users/*.nix files - never touch this one.
  flake.nixosModules.vayoriUsers = { config, lib, pkgs, ... }:
  let
    cfg = config.vayori.users;

    # Auto-discovered from modules/apps/*.nix - add a new app by dropping
    # a file there (flake.homeModules.apps."name" = ...), nothing to sync
    # here.
    availableApps = builtins.attrNames self.homeModules.apps;

    userSubmodule = lib.types.submodule ({ name, ... }: {
      options = {
        fullName = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Display name (GECOS).";
        };

        # Generate with: mkpasswd -m sha-512
        hashedPassword = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Hashed password. Leave null to fall back to initialPassword \"changeme\" (run `passwd` after first login).";
        };

        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "networkmanager" "video" "input" ];
          description = "Add \"wheel\" here for sudo access, \"adbusers\" for Android debugging, etc.";
        };

        avatar = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Optional path to a .face avatar image (Noctalia profile card + qylock).";
        };

        shell = lib.mkOption {
          type = lib.types.package;
          default = pkgs.zsh;
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Any one-off packages just for this user, e.g. `[ pkgs.blender ]`.";
        };
      };
    });
  in {
    options.vayori.users = lib.mkOption {
      type = lib.types.attrsOf userSubmodule;
      default = { };
      description = "One entry per person using this machine.";
    };

    # ---- The actual "pick your apps for this machine" bit -----------------
    options.vayori.apps = lib.mkOption {
      type = lib.types.listOf (lib.types.enum availableApps);
      default = [ ];
      description = "Which optional app modules (from modules/apps/) EVERYONE on this machine gets. Options: ${lib.concatStringsSep ", " availableApps}";
    };

    config = lib.mkIf (cfg != { }) {
      users.mutableUsers = lib.any (u: u.hashedPassword == null) (lib.attrValues cfg);

      users.users = lib.mapAttrs (name: u: {
        isNormalUser = true;
        description = u.fullName;
        extraGroups = u.extraGroups;
        shell = u.shell;
      } // (if u.hashedPassword != null
            then { hashedPassword = u.hashedPassword; }
            else { initialPassword = "changeme"; }
          )) cfg;

      programs.zsh.enable = true;

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs self; };

      home-manager.users = lib.mapAttrs (name: u: { ... }: {
        imports = [
          self.homeModules.baseline # kitty + gtk/qt glass theming, everyone gets this
        ] ++ (map (app: self.homeModules.apps.${app}) config.vayori.apps);

        home.stateVersion = config.system.stateVersion;
        home.packages = u.extraPackages;
        home.file = lib.mkIf (u.avatar != null) {
          ".face".source = u.avatar;
        };
      }) cfg;
    };
  };
}
