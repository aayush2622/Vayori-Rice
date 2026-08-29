{ ... }: {
  flake.devLanguages.Kotlin = {
    vscode = {
      nixpkgsExtensions = [
        "mathiasfrohlich.kotlin"
        "vscjava.vscode-gradle"
      ];
      marketplaceExtensions = [
        { publisher = "fwcd"; name = "kotlin"; }
        { publisher = "esafirm"; name = "kotlin-formatter"; }
        { publisher = "naco-siren"; name = "gradle-language"; }
      ];
    };
    androidStudio = {
      autoPlugins = [
        { dirName = "kmm-plugin"; id = "com.jetbrains.kmm"; }
      ];
    };
    zed = {
      extensions = [ "kotlin" "java" "groovy" ];
      settings = {
        lsp.kotlin-language-server.settings.compiler.jvm.target = "21";
        languages.Kotlin.language_servers = [ "kotlin-lsp" ];
      };
    };
  };

  flake.homeModules.apps.Kotlin = { pkgs, ... }: {
    home.packages = with pkgs; [
      kotlin
      kotlin-language-server
    ];
  };
}
