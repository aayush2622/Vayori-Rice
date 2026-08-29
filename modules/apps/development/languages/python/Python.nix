{ ... }: {
  flake.devLanguages.Python = {
    vscode = {
      nixpkgsExtensions = [
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-python.debugpy"
        "ms-python.vscode-python-envs"
      ];
      marketplaceExtensions = [
        { publisher = "kevinrose"; name = "vsc-python-indent"; }
        { publisher = "njqdev"; name = "vscode-python-typehint"; }
      ];
    };
    androidStudio = {
      autoPlugins = [
        { dirName = "python-ce"; id = "PythonCore"; }
      ];
    };
    # Zed bundles Python (Pyright) support natively - nothing to install,
    # same as Rust.
  };

  # Pylance/python-ce/Zed's own bundled Pyright all do their own analysis
  # without needing a separate LSP binary on PATH - the interpreter itself
  # is the only thing actually missing without this toggle.
  flake.homeModules.apps.Python = { pkgs, ... }: {
    home.packages = [ pkgs.python3 ];
  };
}
