{ self, inputs, ... }: {
  # Kitty + zsh (oh-my-zsh) + fastfetch, as one selectable app.
  flake.homeModules.apps.terminal = { pkgs, ... }: {
    programs.kitty = {
      enable = true;

      font = {
        name = "JetBrainsMono Nerd Font";
        size = 11;
      };

      settings = {
        confirm_os_window_close = 0;
        window_padding_width = 10;
        hide_window_decorations = "yes";
        cursor_trail = 1;

        tab_bar_min_tabs = 1;
        tab_bar_edge = "bottom";
        tab_bar_style = "separator";
        tab_separator = " | ";
        tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
      };

      extraConfig = ''
      include dank-tabs.conf
      include dank-theme.conf
      '';

      shellIntegration.enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;

      plugins = [
        {
          name = "zsh-autosuggestions";
          src = inputs.zsh-autosuggestions;
        }

        {
          name = "zsh-256color";
          src = inputs.zsh-256color;
        }

        {
          name = "you-should-use";
          src = inputs.zsh-you-should-use;
        }

        {
          name = "zsh-syntax-highlighting";
          src = inputs.zsh-syntax-highlighting;
        }
      ];

      oh-my-zsh = {
        enable = true;

        plugins = [
          "sudo"
          "git"
          "colorize"
        ];
      };

      initContent = ''
      # ─────────────────────────────────────────────
      # Prompt + Git branch
      # ─────────────────────────────────────────────

      autoload -Uz vcs_info

      zstyle ':vcs_info:git:*' formats ' (%b)'

      precmd() {
        vcs_info

        if [[ -n "$vcs_info_msg_0_" ]]; then
          PROMPT='%n %~''${vcs_info_msg_0_}> '
        else
          PROMPT='%n> '
        fi
      }

      # ─────────────────────────────────────────────
      # Fastfetch
      # ─────────────────────────────────────────────

      FASTFETCH_IMAGE_DIR="${./images}"

      FASTFETCH_IMAGE=$(
        find "$FASTFETCH_IMAGE_DIR" -type f \
        \( \
          -iname '*.png' \
          -o -iname '*.jpg' \
          -o -iname '*.jpeg' \
          -o -iname '*.webp' \
          -o -iname '*.icon' \
        \) \
        | shuf -n 1
      )
      if [ -n "$FASTFETCH_IMAGE" ]; then
        fastfetch \
          --logo-type kitty \
          --logo "$FASTFETCH_IMAGE" \
          --logo-width 32 \
          --logo-height 16
      else
        fastfetch
      fi
    '';
    };
    programs.fastfetch = {
      enable = true;

      settings = {
        "$schema" =
        "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

        display.separator = " 󰁔 ";

        modules = [
          # ─────────────────────────────────────────────────────────────
          # SYSTEM
          # ─────────────────────────────────────────────────────────────
          {
            type = "custom";
            format = "╭──────────────────────────────────────────╮";
          }

          {
            type = "chassis";
            key = " 󰇺 Chassis";
            format = "{1} {2} {3}";
            keyColor = "cyan";
          }

          {
            type = "os";
            key = " 󰣇 OS";
            format = "{2}";
            keyColor = "red";
          }

          {
            type = "kernel";
            key = " 󰒓 Kernel";
            format = "{2}";
            keyColor = "red";
          }

          {
            type = "packages";
            key = " 󰏗 Packages";
            keyColor = "green";
          }

          {
            type = "display";
            key = " 󰍹 Display";
            format = "{1}x{2} @ {3}Hz [{7}]";
            keyColor = "green";
          }

          {
            type = "terminal";
            key = " 󰆍 Terminal";
            keyColor = "yellow";
          }

          {
            type = "wm";
            key = " 󱗃 WM";
            format = "{2}";
            keyColor = "yellow";
          }

          {
            type = "custom";
            format = "╰──────────────────────────────────────────╯";
          }

          "break"

          # ─────────────────────────────────────────────────────────────
          # IDENTITY
          # ─────────────────────────────────────────────────────────────
          {
            type = "title";
            key = " 󰀄";
            format = "{6} {7} {8}";
            keyColor = "cyan";
          }

          {
            type = "custom";
            format = "╭──────────────────────────────────────────╮";
          }

          # ─────────────────────────────────────────────────────────────
          # HARDWARE
          # ─────────────────────────────────────────────────────────────
          {
            type = "cpu";
            key = " 󰍛 CPU";
            format = "{1} @ {7}";
            keyColor = "blue";
          }

          {
            type = "gpu";
            key = " 󰊴 GPU";
            format = "{1} {2}";
            keyColor = "blue";
          }

          {
            type = "gpu";
            key = " 󰘚 Driver";
            format = "{3}";
            keyColor = "magenta";
          }

          {
            type = "memory";
            key = " 󰍛 Memory";
            keyColor = "magenta";
          }

          # ─────────────────────────────────────────────────────────────
          # STORAGE / TIME
          # ─────────────────────────────────────────────────────────────
          {
            type = "disk";
            key = " 󱦟 OS Age";
            folders = "/";
            format = "{days} days";
            keyColor = "red";
          }

          {
            type = "uptime";
            key = " 󱫐 Uptime";
            keyColor = "yellow";
          }

          {
            type = "custom";
            format = "╰──────────────────────────────────────────╯";
          }

          {
            type = "colors";
            paddingLeft = 2;
            symbol = "circle";
          }

          "break"
        ];
      };
    };
  };
}
