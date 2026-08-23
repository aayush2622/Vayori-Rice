{ self, inputs, ... }: {
  flake.homeModules.apps."android-studio" = { pkgs, ... }: {
    home.packages = with pkgs; [
      #android-studio
      #flutter
      jdk17
      android-tools # adb, fastboot
    ];

    home.sessionVariables = {
      ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
      ANDROID_HOME = "$HOME/Android/Sdk";
      CHROME_EXECUTABLE = "zen"; # so `flutter run -d chrome` works with Zen instead of missing Chrome
    };

    # `adb` device access needs the "adbusers" group and the system-wide
    # `programs.adb.enable`, both handled once for everyone in
    # modules/features/dev-system.nix - add "adbusers" to your extraGroups
    # in your users/<you>.nix file if you pick this app.
  };
}
