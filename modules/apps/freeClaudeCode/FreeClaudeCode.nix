{ self, inputs, ... }: {
  flake.homeModules.apps.FreeClaudeCode =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      fccDir = "${config.home.homeDirectory}/.local/share/free-claude-code";
      fccConfigDir = "${config.home.homeDirectory}/.fcc";
      jetbrainsAcpFile = "${config.home.homeDirectory}/.jetbrains/acp.json";
      claudeJsonFile = "${config.home.homeDirectory}/.claude.json";

      fccSeedEnv = {
        MODEL = "nvidia_nim/nvidia/nemotron-3-super-120b-a12b";
        PROXY_AUTH_ENABLED = "false";
        ANTHROPIC_AUTH_TOKEN = "freecc";
        FCC_OPEN_BROWSER = "false";
      };

      fccSeedEnvFile = pkgs.writeText "fcc-seed.env" (
        lib.concatStringsSep "\n" (
          (lib.mapAttrsToList (n: v: "${n}=${v}") fccSeedEnv)
          ++ [
            "# Create a free key at https://build.nvidia.com/settings/api-keys"
            "# NVIDIA_NIM_API_KEY="
          ]
        )
        + "\n"
      );
      claudeAcpEnv = {
        ANTHROPIC_BASE_URL = "http://localhost:8082";
        ANTHROPIC_AUTH_TOKEN = "freecc";
        CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
        CLAUDE_CODE_AUTO_COMPACT_WINDOW = "190000";
        DISABLE_AUTOUPDATER = "1";
        DISABLE_FEEDBACK_COMMAND = "1";
        DISABLE_ERROR_REPORTING = "1";
      };

      fccBootstrapScript = pkgs.writeShellScript "free-claude-code-bootstrap" ''
        set -e
        FCC_DIR=${lib.escapeShellArg fccDir}

        if [ ! -d "$FCC_DIR/.git" ]; then
          ${pkgs.git}/bin/git clone https://github.com/Alishahryar1/free-claude-code.git "$FCC_DIR"
        else
          ${pkgs.git}/bin/git -C "$FCC_DIR" pull --ff-only
        fi

        cd "$FCC_DIR"
        ${pkgs.uv}/bin/uv sync --python '${pkgs.python314}/bin/python3.14'
      '';
    in
    {
      home.packages = [
        pkgs.uv
        pkgs.python314
      ];

      home.activation.freeClaudeCodeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        FCC_CONFIG_DIR=${lib.escapeShellArg fccConfigDir}

        run mkdir -p "$FCC_CONFIG_DIR"

        if [ ! -f "$FCC_CONFIG_DIR/.env" ]; then
          run cp ${fccSeedEnvFile} "$FCC_CONFIG_DIR/.env"
        fi

        CLAUDE_JSON=${lib.escapeShellArg claudeJsonFile}

        if [ ! -f "$CLAUDE_JSON" ]; then
          run sh -c "printf '{}' > '$CLAUDE_JSON'"
        fi

        CLAUDE_JSON_TMP="$(mktemp)"

        ${pkgs.jq}/bin/jq \
          '. + {hasCompletedOnboarding: true}' \
          "$CLAUDE_JSON" > "$CLAUDE_JSON_TMP" \
          && run cp "$CLAUDE_JSON_TMP" "$CLAUDE_JSON"

        rm -f "$CLAUDE_JSON_TMP"

        ACP_JSON=${lib.escapeShellArg jetbrainsAcpFile}

        run mkdir -p "$(dirname "$ACP_JSON")"

        if [ ! -f "$ACP_JSON" ]; then
          run sh -c "printf '{}' > '$ACP_JSON'"
        fi

        ACP_JSON_TMP="$(mktemp)"

        ${pkgs.jq}/bin/jq \
          --argjson env ${lib.escapeShellArg (builtins.toJSON claudeAcpEnv)} '
            .acp.registry."claude-acp".env =
              ((.acp.registry."claude-acp".env // {}) + $env)
          ' \
          "$ACP_JSON" > "$ACP_JSON_TMP" \
          && run cp "$ACP_JSON_TMP" "$ACP_JSON"

        rm -f "$ACP_JSON_TMP"

        run ${pkgs.systemd}/bin/systemctl --user --no-block restart free-claude-code.service || true
      '';

      systemd.user.services.free-claude-code-bootstrap = {
        Unit = {
          Description = "Clone/update Free Claude Code and sync its Python environment";
          After = [ "network-online.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${fccBootstrapScript}";
        };
      };

      systemd.user.services.free-claude-code = {
        Unit = {
          Description = "Free Claude Code local proxy server";
          After = [ "network-online.target" "free-claude-code-bootstrap.service" ];
          Wants = [ "free-claude-code-bootstrap.service" ];
        };
        Service = {
          WorkingDirectory = fccDir;
          ExecStart = "${fccDir}/.venv/bin/fcc-server";
          Restart = "on-failure";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
