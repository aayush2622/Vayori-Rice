{ self, inputs, ... }: {
  flake.homeModules.apps.Bitwarden = { pkgs, lib, ... }: {
    home.packages = [ pkgs.bitwarden-desktop pkgs.pinentry-gtk2 ];

    programs.rbw = {
      enable = true;
    };

    home.activation.rbwEmail = lib.hm.dag.entryAfter [ "writeBoundary" "seedVayoriSecrets" ] ''
      CONFIG_FILE="$HOME/.config/rbw/config.json"
      SECRETS_FILE="$HOME/.config/vayori/session/secrets.env"
      EMAIL="$(grep -m1 '^RBW_EMAIL=' "$SECRETS_FILE" 2>/dev/null | cut -d= -f2- || true)"

      run mkdir -p "$(dirname "$CONFIG_FILE")"

      if [ ! -f "$CONFIG_FILE" ]; then
        run sh -c "printf '{}' > '$CONFIG_FILE'"
      fi

      CONFIG_TMP="$(mktemp)"

      ${pkgs.jq}/bin/jq \
        --arg email "$EMAIL" \
        '.email = $email' \
        "$CONFIG_FILE" > "$CONFIG_TMP" \
        && run cp "$CONFIG_TMP" "$CONFIG_FILE"

      rm -f "$CONFIG_TMP"
    '';
  };
}
