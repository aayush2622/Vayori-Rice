{ ... }: {
  flake.devLanguages.Rust = {
    vscode = {
      nixpkgsExtensions = [
        "rust-lang.rust-analyzer"
      ];
    };
  };

  flake.homeModules.apps.Rust = { pkgs, ... }: {
    home.packages = with pkgs; [
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy
    ];
  };
}
