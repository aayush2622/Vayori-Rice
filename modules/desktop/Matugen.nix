{ lib, ... }: {
  options.flake.matugenTemplates = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Raw matugen template content shared across app modules - see modules/desktop/Matugen.nix.";
  };

  config.flake.matugenTemplates = {
    btop = ''
      theme[main_bg]=""
      theme[main_fg]="{{colors.on_surface.default.hex}}"
      theme[title]="{{colors.primary.default.hex}}"
      theme[hi_fg]="{{colors.secondary.default.hex}}"
      theme[selected_bg]="{{colors.primary.default.hex}}"
      theme[selected_fg]="{{colors.on_primary.default.hex}}"
      theme[inactive_fg]="{{colors.on_surface_variant.default.hex}}"
      theme[proc_misc]="{{colors.tertiary.default.hex}}"
      theme[cpu_box]="{{colors.outline.default.hex}}"
      theme[mem_box]="{{colors.outline.default.hex}}"
      theme[net_box]="{{colors.outline.default.hex}}"
      theme[proc_box]="{{colors.outline.default.hex}}"
      theme[div_line]="{{colors.outline_variant.default.hex}}"
      theme[temp_start]="{{colors.secondary.default.hex}}"
      theme[temp_mid]="{{colors.primary.default.hex}}"
      theme[temp_end]="{{colors.error.default.hex}}"
      theme[cpu_start]="{{colors.secondary.default.hex}}"
      theme[cpu_mid]="{{colors.primary.default.hex}}"
      theme[cpu_end]="{{colors.error.default.hex}}"
      theme[free_start]="{{colors.secondary.default.hex}}"
      theme[free_mid]=""
      theme[free_end]="{{colors.secondary_container.default.hex}}"
      theme[cached_start]="{{colors.tertiary.default.hex}}"
      theme[cached_mid]=""
      theme[cached_end]="{{colors.tertiary_container.default.hex}}"
      theme[available_start]="{{colors.primary.default.hex}}"
      theme[available_mid]=""
      theme[available_end]="{{colors.primary_container.default.hex}}"
      theme[used_start]="{{colors.error.default.hex}}"
      theme[used_mid]=""
      theme[used_end]="{{colors.error_container.default.hex}}"
      theme[download_start]="{{colors.secondary.default.hex}}"
      theme[download_mid]="{{colors.primary.default.hex}}"
      theme[download_end]="{{colors.tertiary.default.hex}}"
      theme[upload_start]="{{colors.secondary.default.hex}}"
      theme[upload_mid]="{{colors.primary.default.hex}}"
      theme[upload_end]="{{colors.tertiary.default.hex}}"
    '';

    cava = ''
      [color]
      background = 'default'
      foreground = '{{colors.primary.default.hex}}'

      ; gradient = 0
      gradient = 1
      gradient_color_1 = '{{colors.primary_container.default.hex}}'
      gradient_color_2 = '{{colors.primary.default.hex}}'
      gradient_color_3 = '{{colors.on_primary_container.default.hex}}'

      horizontal_gradient = 0
      ; horizontal_gradient = 1
      horizontal_gradient_color_1 = '{{colors.primary_container.default.hex}}'
      horizontal_gradient_color_2 = '{{colors.primary.default.hex}}'
      horizontal_gradient_color_3 = '{{colors.on_primary_container.default.hex}}'
      horizontal_gradient_color_4 = '{{colors.primary.default.hex}}'
      horizontal_gradient_color_5 = '{{colors.primary_container.default.hex}}'
    '';

    heroic = ''
      body.matugen {
        --accent: {{colors.tertiary.default.hex}};
        --accent-overlay: {{colors.inverse_primary.default.hex}};

        --primary: {{colors.primary.default.hex}};
        --primary-hover: {{colors.primary_container.default.hex}};
        --navbar-accent: var(--primary);

        --background: {{colors.background.default.hex}};
        --body-background: {{colors.surface.default.hex}};
        --navbar-background: {{colors.surface_container.default.hex}};

        --background-darker: var(--background);
        --current-background: var(--body-background);
        --navbar-active-background: {{colors.surface_container_high.default.hex}};

        --gradient-body-background: linear-gradient(
          90deg,
          var(--background-darker) -32px,
          var(--body-background) 64px,
          var(--body-background) 100%
        );

        --input-background: var(--navbar-background);
        --modal-background: var(--body-background);
        --modal-border: var(--body-background);

        --success: {{colors.tertiary.default.hex}};
        --success-hover: {{colors.tertiary_container.default.hex}};
        --danger: {{colors.error.default.hex}};
        --danger-hover: {{colors.error_container.default.hex}};

        --text-default: {{colors.on_surface.default.hex}};
        --text-title: {{colors.on_surface.default.hex}};
        --text-secondary: {{colors.on_surface_variant.default.hex}};
        --text-tertiary: {{colors.on_tertiary.default.hex}};
        --text-hover: {{colors.primary.default.hex}};

        --action-icon: {{colors.on_surface.default.hex}};
        --action-icon-hover: {{colors.primary.default.hex}};
        --action-icon-active: {{colors.primary_container.default.hex}};
        --icons-background: {{colors.surface_variant.default.hex}};
        --icon-disabled: {{colors.on_surface_variant.default.hex}};

        --anticheat-denied: var(--danger);
        --anticheat-broken: var(--accent);
        --anticheat-running: var(--primary);
        --anticheat-supported: var(--success);
        --anticheat-planned: {{colors.secondary.default.hex}};

        --neutral-06: {{colors.on_surface_variant.default.hex}};
        --gamecard-title-color: {{colors.surface_container.default.hex}}cc;
        --secondary-button: var(--accent);
        --tertiary-button: var(--primary);
      }
    '';

    steam = ''
      /*
      * GTK 4 Colors
      * Converted from Matugen template
      */

      :root {
          --adw-accent-rgb: {{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }};
          --adw-accent-bg-rgb: {{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }};
          --adw-accent-fg-rgb: {{ colors.on_primary.default.red }} {{ colors.on_primary.default.green }} {{ colors.on_primary.default.blue }};

          --adw-window-bg-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
          --adw-window-fg-rgb: {{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }};

          --adw-headerbar-bg-rgb: {{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }};
          --adw-headerbar-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-popover-bg-rgb: {{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }};
          --adw-popover-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-view-bg-rgb: {{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }};
          --adw-view-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-card-bg-rgb: {{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }};
          --adw-card-fg-rgb: {{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }};

          --adw-sidebar-bg-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
          --adw-sidebar-fg-rgb: {{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }};
          --adw-sidebar-border-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
          --adw-sidebar-backdrop-rgb: {{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }};
      }
    '';

    wine = ''
      Windows Registry Editor Version 5.00

      [HKEY_CURRENT_USER\Software\Wine\X11 Driver]
      "Decorated"="N"

      [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes]
      "AppsUseClassicTheme"=dword:00000001

      [HKEY_CURRENT_USER\Control Panel\Colors]
      "ActiveBorder"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ActiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "AppWorkSpace"="{{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }}"
      "Background"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"

      "ButtonAlternativeFace"="{{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }}"
      "ButtonDkShadow"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonFace"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonHilight"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonLight"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonShadow"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "ButtonText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "GradientActiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "GradientInactiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "GrayText"="{{ colors.secondary_container.default.red }} {{ colors.secondary_container.default.green }} {{ colors.secondary_container.default.blue }}"

      "Hilight"="{{ colors.primary_container.default.red }} {{ colors.primary_container.default.green }} {{ colors.primary_container.default.blue }}"
      "HilightText"="{{ colors.primary.default.red }} {{ colors.primary.default.green }} {{ colors.primary.default.blue }}"

      "InactiveBorder"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "InactiveTitle"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "InactiveTitleText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "InfoText"="{{ colors.on_surface.default.red }} {{ colors.on_surface.default.green }} {{ colors.on_surface.default.blue }}"
      "InfoWindow"="{{ colors.surface.default.red }} {{ colors.surface.default.green }} {{ colors.surface.default.blue }}"

      "Menu"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "MenuBar"="{{ colors.surface_dim.default.red }} {{ colors.surface_dim.default.green }} {{ colors.surface_dim.default.blue }}"
      "MenuHilight"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "MenuText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "Scrollbar"="{{ colors.surface_container_low.default.red }} {{ colors.surface_container_low.default.green }} {{ colors.surface_container_low.default.blue }}"
      "TitleText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"

      "Window"="{{ colors.surface_container_low.default.red }} {{ colors.surface_container_low.default.green }} {{ colors.surface_container_low.default.blue }}"
      "WindowFrame"="{{ colors.background.default.red }} {{ colors.background.default.green }} {{ colors.background.default.blue }}"
      "WindowText"="{{ colors.on_background.default.red }} {{ colors.on_background.default.green }} {{ colors.on_background.default.blue }}"
    '';

    vesktop = ''
      @import url('https://mwittrien.github.io/BetterDiscordAddons/Themes/DiscordRecolor/DiscordRecolor.css');

      :root {
        --accentcolor: {{colors.primary.default.red}},{{colors.primary.default.green}},{{colors.primary.default.blue}};
        --accentcolor2: {{colors.primary_container.default.red}},{{colors.primary_container.default.green}},{{colors.primary_container.default.blue}};
        --linkcolor: {{colors.primary.default.red}},{{colors.primary.default.green}},{{colors.primary.default.blue}};
        --mentioncolor: {{colors.secondary.default.red}},{{colors.secondary.default.green}},{{colors.secondary.default.blue}};
        --textbrightest: {{colors.on_background.default.red}},{{colors.on_background.default.green}},{{colors.on_background.default.blue}};
        --textbrighter: {{colors.on_surface.default.red}},{{colors.on_surface.default.green}},{{colors.on_surface.default.blue}};
        --textbright: {{colors.on_surface_variant.default.red}},{{colors.on_surface_variant.default.green}},{{colors.on_surface_variant.default.blue}};
        --textdark: {{colors.outline.default.red}},{{colors.outline.default.green}},{{colors.outline.default.blue}};
        --textdarker: {{colors.outline_variant.default.red}},{{colors.outline_variant.default.green}},{{colors.outline_variant.default.blue}};
        --textdarkest: {{colors.surface_container_highest.default.red}},{{colors.surface_container_highest.default.green}},{{colors.surface_container_highest.default.blue}};

        --backgroundaccent: {{colors.primary_container.default.red}},{{colors.primary_container.default.green}},{{colors.primary_container.default.blue}};
        --backgroundprimary: {{colors.surface.default.red}},{{colors.surface.default.green}},{{colors.surface.default.blue}};
        --backgroundsecondary: {{colors.surface_container.default.red}},{{colors.surface_container.default.green}},{{colors.surface_container.default.blue}};
        --backgroundsecondaryalt: {{colors.surface_container.default.red}},{{colors.surface_container.default.green}},{{colors.surface_container.default.blue}};
        --backgroundtertiary: {{colors.surface_container_low.default.red}},{{colors.surface_container_low.default.green}},{{colors.surface_container_low.default.blue}};
        --backgroundfloating: {{colors.surface_container_high.default.red}},{{colors.surface_container_high.default.green}},{{colors.surface_container_high.default.blue}};
        --settingsicons: 0;
      }

      ::-webkit-scrollbar {
        width: 10px !important;
      }

      ::-webkit-scrollbar-thumb {
        /* On bigger screens, the scrollbar's border radius falls short,
        so we put an obscenely large value for the border radius */
        border-radius: 500px !important;
        background: rgba(var(--accentcolor), 0.7) !important;
        background-clip: content-box !important;
        border: 2px solid transparent !important; /* Margin for the scrollbar */
      }

      /* Any custom CSS below here */
    '';

    # Hand-authored against Zed's own published theme schema
    # (https://zed.dev/schema/themes/v0.2.0.json), not ported from an
    # existing static theme - `ThemeStyleContent` has zero required keys,
    # so this covers the visible surface (editor, panels, terminal, git
    # status, syntax highlighting) and lets Zed fall back to sane defaults
    # for the ~40 keys (mostly niche UI chrome) not set here.
    zed = ''
      {
        "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
        "name": "Matugen",
        "author": "matugen via DankMaterialShell",
        "themes": [
          {
            "name": "Matugen",
            "appearance": "dark",
            "style": {
              "background": "{{colors.background.default.hex}}",
              "border": "{{colors.outline_variant.default.hex}}",
              "border.variant": "{{colors.outline_variant.default.hex}}",
              "border.focused": "{{colors.primary.default.hex}}",
              "border.selected": "{{colors.primary.default.hex}}",
              "border.transparent": "{{colors.outline_variant.default.hex}}",
              "border.disabled": "{{colors.outline.default.hex}}",
              "elevated_surface.background": "{{colors.surface_container_high.default.hex}}",
              "surface.background": "{{colors.surface.default.hex}}",
              "panel.background": "{{colors.surface_container_low.default.hex}}",
              "panel.focused_border": "{{colors.primary.default.hex}}",
              "panel.indent_guide": "{{colors.outline_variant.default.hex}}",
              "panel.indent_guide_active": "{{colors.outline.default.hex}}",
              "panel.indent_guide_hover": "{{colors.outline.default.hex}}",
              "pane.focused_border": "{{colors.primary.default.hex}}",
              "pane_group.border": "{{colors.outline_variant.default.hex}}",
              "tab_bar.background": "{{colors.surface_container_low.default.hex}}",
              "tab.active_background": "{{colors.surface.default.hex}}",
              "tab.inactive_background": "{{colors.surface_container_low.default.hex}}",
              "toolbar.background": "{{colors.surface.default.hex}}",
              "title_bar.background": "{{colors.surface_container_low.default.hex}}",
              "title_bar.inactive_background": "{{colors.surface_container_low.default.hex}}",
              "status_bar.background": "{{colors.surface_container_low.default.hex}}",

              "text": "{{colors.on_surface.default.hex}}",
              "text.muted": "{{colors.on_surface_variant.default.hex}}",
              "text.placeholder": "{{colors.outline.default.hex}}",
              "text.disabled": "{{colors.outline.default.hex}}",
              "text.accent": "{{colors.primary.default.hex}}",

              "icon": "{{colors.on_surface.default.hex}}",
              "icon.muted": "{{colors.on_surface_variant.default.hex}}",
              "icon.disabled": "{{colors.outline.default.hex}}",
              "icon.placeholder": "{{colors.outline.default.hex}}",
              "icon.accent": "{{colors.primary.default.hex}}",

              "element.background": "{{colors.surface_container.default.hex}}",
              "element.hover": "{{colors.surface_container_high.default.hex}}",
              "element.active": "{{colors.primary_container.default.hex}}",
              "element.selected": "{{colors.primary_container.default.hex}}",
              "element.disabled": "{{colors.surface_container_low.default.hex}}",
              "ghost_element.background": "{{colors.background.default.hex}}",
              "ghost_element.hover": "{{colors.surface_container_high.default.hex}}",
              "ghost_element.active": "{{colors.primary_container.default.hex}}",
              "ghost_element.selected": "{{colors.primary_container.default.hex}}",
              "ghost_element.disabled": "{{colors.surface_container_low.default.hex}}",

              "drop_target.background": "{{colors.primary_container.default.hex}}",
              "link_text.hover": "{{colors.primary.default.hex}}",

              "editor.background": "{{colors.background.default.hex}}",
              "editor.foreground": "{{colors.on_surface.default.hex}}",
              "editor.gutter.background": "{{colors.background.default.hex}}",
              "editor.line_number": "{{colors.outline.default.hex}}",
              "editor.active_line_number": "{{colors.on_surface.default.hex}}",
              "editor.active_line.background": "{{colors.surface_container.default.hex}}",
              "editor.highlighted_line.background": "{{colors.surface_container_high.default.hex}}",
              "editor.invisible": "{{colors.outline_variant.default.hex}}",
              "editor.wrap_guide": "{{colors.outline_variant.default.hex}}",
              "editor.active_wrap_guide": "{{colors.outline.default.hex}}",
              "editor.indent_guide": "{{colors.outline_variant.default.hex}}",
              "editor.indent_guide_active": "{{colors.outline.default.hex}}",
              "editor.document_highlight.read_background": "{{colors.secondary_container.default.hex}}",
              "editor.document_highlight.write_background": "{{colors.tertiary_container.default.hex}}",
              "editor.document_highlight.bracket_background": "{{colors.secondary_container.default.hex}}",
              "editor.subheader.background": "{{colors.surface_container.default.hex}}",

              "scrollbar.track.background": "{{colors.background.default.hex}}",
              "scrollbar.track.border": "{{colors.background.default.hex}}",
              "scrollbar.thumb.background": "{{colors.outline_variant.default.hex}}",
              "scrollbar.thumb.hover_background": "{{colors.outline.default.hex}}",
              "scrollbar.thumb.border": "{{colors.outline_variant.default.hex}}",

              "search.match_background": "{{colors.tertiary_container.default.hex}}",

              "error": "{{colors.error.default.hex}}",
              "error.background": "{{colors.error_container.default.hex}}",
              "error.border": "{{colors.error.default.hex}}",
              "warning": "{{colors.tertiary.default.hex}}",
              "warning.background": "{{colors.tertiary_container.default.hex}}",
              "warning.border": "{{colors.tertiary.default.hex}}",
              "success": "{{colors.primary.default.hex}}",
              "success.background": "{{colors.primary_container.default.hex}}",
              "success.border": "{{colors.primary.default.hex}}",
              "info": "{{colors.secondary.default.hex}}",
              "info.background": "{{colors.secondary_container.default.hex}}",
              "info.border": "{{colors.secondary.default.hex}}",
              "hint": "{{colors.secondary.default.hex}}",
              "hint.background": "{{colors.secondary_container.default.hex}}",
              "hint.border": "{{colors.secondary.default.hex}}",
              "predictive": "{{colors.outline.default.hex}}",
              "predictive.background": "{{colors.surface_container.default.hex}}",
              "predictive.border": "{{colors.outline_variant.default.hex}}",

              "created": "{{colors.primary.default.hex}}",
              "created.background": "{{colors.primary_container.default.hex}}",
              "created.border": "{{colors.primary.default.hex}}",
              "modified": "{{colors.tertiary.default.hex}}",
              "modified.background": "{{colors.tertiary_container.default.hex}}",
              "modified.border": "{{colors.tertiary.default.hex}}",
              "deleted": "{{colors.error.default.hex}}",
              "deleted.background": "{{colors.error_container.default.hex}}",
              "deleted.border": "{{colors.error.default.hex}}",
              "conflict": "{{colors.error.default.hex}}",
              "conflict.background": "{{colors.error_container.default.hex}}",
              "conflict.border": "{{colors.error.default.hex}}",
              "renamed": "{{colors.secondary.default.hex}}",
              "renamed.background": "{{colors.secondary_container.default.hex}}",
              "renamed.border": "{{colors.secondary.default.hex}}",
              "ignored": "{{colors.outline.default.hex}}",
              "ignored.background": "{{colors.surface_container_low.default.hex}}",
              "ignored.border": "{{colors.outline_variant.default.hex}}",
              "hidden": "{{colors.outline.default.hex}}",
              "hidden.background": "{{colors.surface_container_low.default.hex}}",
              "hidden.border": "{{colors.outline_variant.default.hex}}",
              "unreachable": "{{colors.outline.default.hex}}",
              "unreachable.background": "{{colors.surface_container_low.default.hex}}",
              "unreachable.border": "{{colors.outline_variant.default.hex}}",

              "terminal.background": "{{colors.background.default.hex}}",
              "terminal.foreground": "{{colors.on_surface.default.hex}}",
              "terminal.bright_foreground": "{{colors.on_surface.default.hex}}",
              "terminal.dim_foreground": "{{colors.on_surface_variant.default.hex}}",
              "terminal.ansi.background": "{{colors.background.default.hex}}",
              "terminal.ansi.black": "{{colors.surface_dim.default.hex}}",
              "terminal.ansi.bright_black": "{{colors.outline.default.hex}}",
              "terminal.ansi.dim_black": "{{colors.surface_container.default.hex}}",
              "terminal.ansi.white": "{{colors.on_surface.default.hex}}",
              "terminal.ansi.bright_white": "{{colors.on_surface.default.hex}}",
              "terminal.ansi.dim_white": "{{colors.on_surface_variant.default.hex}}",
              "terminal.ansi.red": "{{colors.error.default.hex}}",
              "terminal.ansi.bright_red": "{{colors.error.default.hex}}",
              "terminal.ansi.dim_red": "{{colors.error_container.default.hex}}",
              "terminal.ansi.green": "{{colors.primary.default.hex}}",
              "terminal.ansi.bright_green": "{{colors.primary.default.hex}}",
              "terminal.ansi.dim_green": "{{colors.primary_container.default.hex}}",
              "terminal.ansi.yellow": "{{colors.tertiary.default.hex}}",
              "terminal.ansi.bright_yellow": "{{colors.tertiary.default.hex}}",
              "terminal.ansi.dim_yellow": "{{colors.tertiary_container.default.hex}}",
              "terminal.ansi.blue": "{{colors.secondary.default.hex}}",
              "terminal.ansi.bright_blue": "{{colors.secondary.default.hex}}",
              "terminal.ansi.dim_blue": "{{colors.secondary_container.default.hex}}",
              "terminal.ansi.magenta": "{{colors.tertiary.default.hex}}",
              "terminal.ansi.bright_magenta": "{{colors.tertiary.default.hex}}",
              "terminal.ansi.dim_magenta": "{{colors.tertiary_container.default.hex}}",
              "terminal.ansi.cyan": "{{colors.secondary.default.hex}}",
              "terminal.ansi.bright_cyan": "{{colors.secondary.default.hex}}",
              "terminal.ansi.dim_cyan": "{{colors.secondary_container.default.hex}}",

              "players": [
                {
                  "cursor": "{{colors.primary.default.hex}}",
                  "background": "{{colors.primary.default.hex}}",
                  "selection": "{{colors.primary_container.default.hex}}"
                }
              ],

              "syntax": {
                "comment": { "color": "{{colors.on_surface_variant.default.hex}}", "font_style": "italic" },
                "string": { "color": "{{colors.tertiary.default.hex}}" },
                "keyword": { "color": "{{colors.primary.default.hex}}" },
                "function": { "color": "{{colors.secondary.default.hex}}" },
                "type": { "color": "{{colors.tertiary.default.hex}}" },
                "constant": { "color": "{{colors.tertiary.default.hex}}" },
                "number": { "color": "{{colors.secondary.default.hex}}" },
                "property": { "color": "{{colors.on_surface.default.hex}}" },
                "variable": { "color": "{{colors.on_surface.default.hex}}" },
                "operator": { "color": "{{colors.on_surface_variant.default.hex}}" },
                "punctuation": { "color": "{{colors.on_surface_variant.default.hex}}" },
                "tag": { "color": "{{colors.primary.default.hex}}" },
                "attribute": { "color": "{{colors.secondary.default.hex}}" },
                "boolean": { "color": "{{colors.tertiary.default.hex}}" },
                "emphasis": { "font_style": "italic" },
                "emphasis.strong": { "font_weight": 700 },
                "title": { "color": "{{colors.primary.default.hex}}", "font_weight": 700 },
                "link_uri": { "color": "{{colors.secondary.default.hex}}" },
                "link_text": { "color": "{{colors.primary.default.hex}}", "font_style": "italic" }
              }
            }
          }
        ]
      }
    '';

    androidStudio = schemeName: ''
      <scheme name="${schemeName}" version="142" parent_scheme="Darcula">
        <metaInfo>
          <property name="created">Generated by matugen via DankMaterialShell</property>
          <property name="ide">idea</property>
          <property name="originalScheme">${schemeName}</property>
        </metaInfo>
        <colors>
          <option name="CARET_COLOR" value="{{colors.primary.default.hex_stripped}}" />
          <option name="CARET_ROW_COLOR" value="{{colors.surface_container.default.hex_stripped}}" />
          <option name="GUTTER_BACKGROUND" value="{{colors.surface.default.hex_stripped}}" />
          <option name="INDENT_GUIDE" value="{{colors.outline_variant.default.hex_stripped}}" />
          <option name="LINE_NUMBERS_COLOR" value="{{colors.on_surface_variant.default.hex_stripped}}" />
          <option name="RIGHT_MARGIN_COLOR" value="{{colors.outline_variant.default.hex_stripped}}" />
          <option name="SELECTION_BACKGROUND" value="{{colors.primary_container.default.hex_stripped}}" />
          <option name="SELECTION_FOREGROUND" value="{{colors.on_primary_container.default.hex_stripped}}" />
          <option name="TEARLINE_COLOR" value="{{colors.outline_variant.default.hex_stripped}}" />
        </colors>
        <attributes>
          <option name="TEXT">
            <value>
              <option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" />
              <option name="BACKGROUND" value="{{colors.background.default.hex_stripped}}" />
            </value>
          </option>
          <option name="DEFAULT_KEYWORD">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_STRING">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_NUMBER">
            <value><option name="FOREGROUND" value="{{colors.secondary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_FUNCTION_CALL">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_FUNCTION_DECLARATION">
            <value><option name="FOREGROUND" value="{{colors.primary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_CLASS_NAME">
            <value><option name="FOREGROUND" value="{{colors.secondary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_INSTANCE_FIELD">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_CONSTANT">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_IDENTIFIER">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_OPERATION_SIGN">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_BRACES">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_DOT">
            <value><option name="FOREGROUND" value="{{colors.on_surface.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_SEMICOLON">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_LINE_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_BLOCK_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_DOC_COMMENT">
            <value><option name="FOREGROUND" value="{{colors.on_surface_variant.default.hex_stripped}}" /></value>
          </option>
          <option name="DEFAULT_TEMPLATE_LANGUAGE_COLOR">
            <value><option name="FOREGROUND" value="{{colors.tertiary.default.hex_stripped}}" /></value>
          </option>
        </attributes>
      </scheme>
    '';
  };
}
