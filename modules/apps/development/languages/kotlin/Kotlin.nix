{ ... }: {
  flake.devLanguages.Kotlin = {
    vscode = {
      nixpkgsExtensions = [
        "mathiasfrohlich.kotlin"
        "vscjava.vscode-gradle"
      ];
      # fwcd.kotlin isn't in nixpkgs' own curated vscode-extensions set
      # (only mathiasfrohlich's is) - it's on the marketplace though.
      marketplaceExtensions = [
        { publisher = "fwcd"; name = "kotlin"; }
        { publisher = "esafirm"; name = "kotlin-formatter"; }
        { publisher = "naco-siren"; name = "gradle-language"; }
      ];
    };
    androidStudio = {
      # Android Studio's own Kotlin support is built in - this is just
      # Kotlin Multiplatform Mobile, the one bit that isn't.
      autoPlugins = [
        { dirName = "kmm-plugin"; id = "com.jetbrains.kmm"; }
      ];
    };
    zed = {
      # java + groovy ride along with kotlin here since real Kotlin/Android
      # projects mix in Java interop files and Groovy Gradle build scripts.
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
