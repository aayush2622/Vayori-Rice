{ self, inputs, ... }: {
  flake.homeModules.apps."android-studio" = { pkgs, ... }: {
    home.packages = with pkgs; [
      jdk17
      android-tools
    ];

    home.sessionVariables = {
      ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
      ANDROID_HOME = "$HOME/Android/Sdk";
      CHROME_EXECUTABLE = "zen";
    };
  };
}
