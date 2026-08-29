{ ... }: {
  flake.devLanguages.Qt = {
    vscode = {
      marketplaceExtensions = [
        { publisher = "theqtcompany"; name = "qt-core"; }
        { publisher = "theqtcompany"; name = "qt-qml"; }
      ];
      settings = {
        "qt-qml.qmlls.useQmlImportPathEnvVar" = true;
        "qt-core.additionalQtPaths" = [
          { name = "Qt-5.15.18-linux-g++_from_PATH"; path = "/usr/bin/qmake"; }
        ];
      };
    };
    zed = {
      extensions = [ "qml" ];
    };
  };

  # qt5ct/qt6ct in Baseline.nix are unconditional GTK/Qt theming, unrelated
  # to this - this is just the QML language server (qmlls) for editor use.
  flake.homeModules.apps.Qt = { pkgs, ... }: {
    home.packages = [ pkgs.kdePackages.qtdeclarative ];
  };
}
