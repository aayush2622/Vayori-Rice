{ self, inputs, ... }: {
  flake.nixosModules.fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono # kitty + bar monospace glyphs
      material-symbols # Noctalia's icon font
    ];

    fonts.fontconfig.defaultFonts = {
      sansSerif = [ "JetBrainsMono Nerd Font" "Inter" "Noto Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
