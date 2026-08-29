{ ... }: {
  flake.devLanguages.Nix = {
    vscode = {
      nixpkgsExtensions = [
        "jnoortheen.nix-ide"
        "arrterian.nix-env-selector"
      ];
      marketplaceExtensions = [
        { publisher = "ziyyun"; name = "nix-forge"; }
        { publisher = "pinage404"; name = "nix-extension-pack"; }
      ];
      settings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixfmt";
        "[nix]"."editor.defaultFormatter" = "ZiYyun.nix-forge";
      };
    };
    androidStudio = {
      autoPlugins = [
        { dirName = "NixIDEA"; id = "nix-idea"; }
      ];
    };
    zed = {
      extensions = [ "nix" ];
    };
  };

  # Host.nix already installs nil/nixfmt system-wide for root/system-level
  # editing, but that's independent of this per-user, per-language toggle -
  # nix store dedups the two so there's no real duplication either way.
  flake.homeModules.apps.Nix = { pkgs, ... }: {
    home.packages = with pkgs; [
      nil
      nixfmt
    ];
  };
}
