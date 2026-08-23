{ self, inputs, ... }: {
  flake.homeModules.apps."zen-browser" = { pkgs, lib, ... }:
  let
    firefoxExtension = shortId: guid: {
      name = guid;
      value = {
        install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
        installation_mode = "normal_installed";
      };
    };

    zenPrefs = {
      # Check these out at about:config
      "extensions.autoDisableScopes" = 0;
      "extensions.pocket.enabled" = false;
    };

    zenExtensions = [
      # Find the short ID in the addon's url, then look up its guid at
      # https://addons.mozilla.org/api/v5/addons/addon/!SHORT_ID!/
      (firefoxExtension "ublock-origin" "uBlock0@raymondhill.net")
    ];

    zen-browser = pkgs.wrapFirefox
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
      {
        extraPrefs = lib.concatLines (
          lib.mapAttrsToList (
            name: value: ''lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});''
          ) zenPrefs
        );

        extraPolicies = {
          DisableTelemetry = true;
          ExtensionSettings = builtins.listToAttrs zenExtensions;

          SearchEngines = {
            Default = "ddg";
            Add = [
              {
                Name = "nixpkgs packages";
                URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
                IconURL = "https://wiki.nixos.org/favicon.ico";
                Alias = "@np";
              }
              {
                Name = "NixOS options";
                URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
                IconURL = "https://wiki.nixos.org/favicon.ico";
                Alias = "@no";
              }
              {
                Name = "NixOS Wiki";
                URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                IconURL = "https://wiki.nixos.org/favicon.ico";
                Alias = "@nw";
              }
              {
                Name = "noogle";
                URLTemplate = "https://noogle.dev/q?term={searchTerms}";
                IconURL = "https://noogle.dev/favicon.ico";
                Alias = "@ng";
              }
            ];
          };
        };
      };
  in {
    home.packages = [ zen-browser ];

    # Noctalia can also theme Zen directly (Settings -> Color Scheme ->
    # Templates -> Zen Browser) via CSS injection - see
    # https://docs.noctalia.dev/v4/theming/program-specific/zenbrowser/
  };
}
