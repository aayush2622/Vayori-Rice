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

    # `adb` device access works out of the box (systemd 258+ handles the
    # uaccess udev rules automatically). The "adbusers" group is declared
    # in modules/features/dev-system.nix purely for compatibility with
    # extraGroups entries that still reference it - add it in your
    # users/<you>.nix file if you pick this app, but it's not required.
  };
}
