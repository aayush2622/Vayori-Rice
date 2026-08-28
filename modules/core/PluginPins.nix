{ lib, ... }: {
  options.flake.pluginPins = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Pinned plugin/extension specs per app, published so the plugin-update checker can read them without evaluating each app's home module.";
  };
}
