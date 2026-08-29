{ self, inputs, ... }: {
  flake.homeModules.apps.Gaming = { config, ... }:
  let
    gamesDir = "${config.home.homeDirectory}/Games";
    shaderCacheDir = "${gamesDir}/.cache/nv-shaders";
  in
  {
    imports = [
      ./_launchers.nix
      ./_proton.nix
      ./_performance.nix
    ];

    # Threaded to the three fragments above via the module system's
    # `_module.args` rather than passed as plain function arguments -
    # imported modules don't get custom args any other way. `self` itself
    # needs no such threading: it's already a home-manager extraSpecialArg
    # available to every module in this tree, imports included.
    _module.args = { inherit gamesDir shaderCacheDir; };
  };
}
