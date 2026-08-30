{ inputs, ... }:

{
  flake.nixosModules.Dms =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      theme = config.vayori.theme;

      registryPlugins = pkgs.callPackage "${inputs.dms-plugin-registry}/nix/default.nix" { };

      assertPatched = file: needle: ''
        grep -qF ${lib.escapeShellArg needle} "${file}" || {
          echo "patch verification failed: ${lib.escapeShellArg needle} not found in ${file} (upstream source likely changed - update the patch in dms.nix)" >&2
          exit 1
        }
      '';

      assertPatchedLine = file: line: needle: ''
        sed -n '${toString line}p' "${file}" | grep -qF ${lib.escapeShellArg needle} || {
          echo "patch verification failed: line ${toString line} of ${file} doesn't say ${lib.escapeShellArg needle} (upstream source likely changed - update the patch in dms.nix)" >&2
          exit 1
        }
      '';

      mkPatchedPlugin =
        name: src: patchScript:
        pkgs.runCommand "dms-plugin-${name}-patched" { } ''
          cp -r ${src} $out
          chmod -R u+w $out
          ${patchScript}
        '';

      dankDiskUsagePatched = mkPatchedPlugin "dankDiskUsage" registryPlugins.dankDiskUsage ''
        substituteInPlace $out/DankDiskUsageWidget.qml \
          --replace-quiet "size: Theme.fontSizeLarge" "size: root.iconSize"
        sed -i '312s/Theme\.spacingS/Theme.spacingXS/' $out/DankDiskUsageWidget.qml
        substituteInPlace $out/DankDiskUsageWidget.qml \
          --replace-quiet 'return "#ff4444"' 'return Theme.error' \
          --replace-quiet 'return "#ffaa00"' 'return Theme.warning' \
          --replace-quiet 'return Theme.primary' 'return Theme.widgetIconColor'
        ${assertPatched "$out/DankDiskUsageWidget.qml" "size: root.iconSize"}
        ${assertPatchedLine "$out/DankDiskUsageWidget.qml" 312 "Theme.spacingXS"}
        ${assertPatched "$out/DankDiskUsageWidget.qml" "return Theme.error"}
        ${assertPatched "$out/DankDiskUsageWidget.qml" "return Theme.warning"}
        ${assertPatched "$out/DankDiskUsageWidget.qml" "return Theme.widgetIconColor"}
      '';

      nixMonitorPatched = mkPatchedPlugin "nixMonitor" registryPlugins.nixMonitor ''
        sed -i '110s/Theme\.primary$/Theme.widgetIconColor/' $out/NixMonitor.qml
        ${assertPatchedLine "$out/NixMonitor.qml" 110 "Theme.widgetIconColor"}
      '';

      dankAsusControlCenterPatched =
        mkPatchedPlugin "dankAsusControlCenter" registryPlugins.dankAsusControlCenter
          ''
            substituteInPlace $out/DankAsusControlCenter.qml \
              --replace-quiet "size: root.showBatteryIcon ? 18 : Theme.iconSize * 0.85" "size: root.showBatteryIcon ? 18 : root.iconSize"
            sed -i '521s/spacing: 4$/spacing: Theme.spacingXS/' $out/DankAsusControlCenter.qml
            ${assertPatched "$out/DankAsusControlCenter.qml" "size: root.showBatteryIcon ? 18 : root.iconSize"}
            ${assertPatchedLine "$out/DankAsusControlCenter.qml" 521 "Theme.spacingXS"}
          '';

      materialOSIcons = pkgs.stdenvNoCC.mkDerivation {
        pname = "materialos-icon-theme";
        version = "unstable-2026-08-27";
        src = pkgs.fetchFromGitHub {
          owner = "materialos";
          repo = "Linux-Icon-Pack";
          rev = "7ff36403cb38c0f5b7231df717a2efd373c94b6c";
          hash = "sha256-iLhaCdH1RlElMoWvmArTcX+VUubcyIX5k9vHBV9rU9Q=";
        };
        installPhase = ''
          mkdir -p $out/share/icons
          cp -r Icons/MaterialOS $out/share/icons/MaterialOS
        '';
      };

      vayoriRebuildScript = pkgs.writeShellScript "vayori-rebuild" ''
        flakeDir=""
        for d in "$HOME/vayori" "$HOME/dotfiles" "$HOME/.dotfiles" /etc/nixos; do
          [ -f "$d/flake.nix" ] && flakeDir="$d" && break
        done
        if [ -z "$flakeDir" ]; then
          echo "vayori flake not found (checked ~/vayori, ~/dotfiles, ~/.dotfiles, /etc/nixos) - edit rebuildCommand in dms.nix if it lives elsewhere"
          exit 1
        fi
        exec nixos-rebuild switch --flake "$flakeDir#${config.networking.hostName}"
      '';

      vayoriGcScript = pkgs.writeShellScript "vayori-gc" "exec nix-collect-garbage -d";
    in
    {
      security.sudo.extraRules =
        map
          (name: {
            users = [ name ];
            commands = [
              {
                command = "${vayoriRebuildScript}";
                options = [ "NOPASSWD" ];
              }
              {
                command = "${vayoriGcScript}";
                options = [ "NOPASSWD" ];
              }
            ];
          })
          (
            builtins.filter (name: builtins.elem "wheel" config.vayori.users.${name}.extraGroups) (
              builtins.attrNames config.vayori.users
            )
          );

      home-manager.users = lib.genAttrs (builtins.attrNames config.vayori.users) (
        name: { pkgs, lib, ... }: {
          imports = [
            inputs.dms.homeModules.dank-material-shell
            inputs.dms-plugin-registry.nixosModules.default
          ];
          home.packages = [ materialOSIcons ];
          home.sessionVariables.QS_ICON_THEME = "MaterialOS";
          xdg.configFile = {
            "DankMaterialShell/settings.json".force = true;
            "DankMaterialShell/plugin_settings.json".force = true;

            "DankMaterialShell/plugins/NixMonitor/config.json" = {
              force = true;
              text = builtins.toJSON {
                generationsCommand = [
                  "sh"
                  "-c"
                  "ls -d /nix/var/nix/profiles/per-user/$(whoami)/home-manager-*-link 2>/dev/null | wc -l"
                ];
                storeSizeCommand = [
                  "sh"
                  "-c"
                  "du -sh /nix/store 2>/dev/null | cut -f1"
                ];
                rebuildCommand = [
                  "sh"
                  "-c"
                  "sudo ${vayoriRebuildScript} 2>&1"
                ];
                gcCommand = [
                  "sh"
                  "-c"
                  "sudo ${vayoriGcScript} 2>&1"
                ];
                updateInterval = 300;
              };
            };
          };
          home.activation.seedDmsSession =
            let
              defaultSession = pkgs.writeText "dms-default-session.json" (
                builtins.toJSON {
                  configVersion = 4;
                  wallpaperPath = "${./../assets/wallpapers}/wallhaven-w5xdzx.jpg";
                  wallpaperCyclingFolderPath = "${./../assets/wallpapers}";
                }
              );
            in
            lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              sessionFile="$HOME/.local/state/DankMaterialShell/session.json"
              if [ ! -e "$sessionFile" ]; then
                run mkdir -p "$(dirname "$sessionFile")"
                run cp "${defaultSession}" "$sessionFile"
                run chmod u+w "$sessionFile"
              fi
            '';
          systemd.user.services.dms.Service.Environment = [ "DMS_ENABLE_GTK4_REFRESH=1" ];

          programs.dank-material-shell = {
            enable = true;

            dgop.package = inputs.dgop.packages.${pkgs.system}.default;

            systemd = {
              enable = true;
              restartIfChanged = true;
            };

            enableSystemMonitoring = true;
            enableDynamicTheming = true;
            enableAudioWavelength = true;
            plugins = {
              wallpaperCarousel = {
                enable = true;

                settings = {
                  enabled = true;
                  borderWidth = 0;
                  itemHeight = 472;
                  selectedScale = 106;
                  expandMultiplier = 118;
                  cornerRadius = 3;
                  overlayOpacity = 84;
                };
              };

              dankAsusControlCenter = {
                enable = true;
                src = lib.mkForce dankAsusControlCenterPatched;
                settings = {
                  showBatteryIcon = false;
                  useThemeColors = true;
                };
              };

              dankQuickSearch = {
                enable = true;
                settings = {
                  trigger = "!";
                  defaultEngine = "duckduckgo";
                };
              };

              dankBitwarden = {
                enable = true;
                settings = {
                  trigger = "[";
                  noTrigger = false;
                  loginAction = "copy:password";
                  cardAction = "copy:number";
                  identityAction = "copy:name";
                  sshKeyAction = "copy:public_key";
                };
              };

              spotifyMatugen.enable = true;

              pureLyrics.enable = true;

              nixMonitor = {
                enable = true;
                src = lib.mkForce nixMonitorPatched;
                settings = {
                  showGenerations = true;
                  showStoreSize = true;
                  gcThresholdGB = 50;
                  checkUpdates = true;
                  nixpkgsChannel = "nixos-unstable";
                  updateCheckInterval = 3600;
                };
              };

              dankDiskUsage = {
                enable = true;
                src = lib.mkForce dankDiskUsagePatched;
                settings = {
                  refreshInterval = 30;
                  warningThreshold = 80;
                  criticalThreshold = 95;
                  showPartitions = true;
                  showZfs = false;
                  showNixStore = false;
                  excludeMounts = [ ];
                };
              };
            };

            settings = {

              currentThemeName = "dynamic";
              currentThemeCategory = "dynamic";
              customThemeFile = "";
              registryThemeVariants = { };

              matugenScheme = "scheme-content";
              matugenContrast = 0;
              runUserMatugenTemplates = true;
              matugenTargetMonitor = "";

              popupTransparency = 1;
              dockTransparency = 1;

              widgetBackgroundColor = "sch";
              widgetBackgroundCustomColor = "#6750A4";
              widgetBackgroundCustomStrength = 0.5;

              widgetColorMode = "default";
              controlCenterTileColorMode = "primary";
              buttonColorMode = "primary";

              cornerRadius = 12;

              niriLayoutGapsOverride = -1;
              niriLayoutRadiusOverride = -1;
              niriLayoutBorderSize = -1;

              hyprlandLayoutGapsOverride = -1;
              hyprlandLayoutGapsOutOverride = -1;
              hyprlandLayoutRadiusOverride = -1;
              hyprlandLayoutBorderSize = -1;
              hyprlandResizeOnBorder = false;

              mangoLayoutGapsOverride = -1;
              mangoLayoutGapsOutOverride = -1;
              mangoLayoutRadiusOverride = -1;
              mangoLayoutBorderSize = -1;
              mangoTrackpadNaturalScrolling = true;

              firstDayOfWeek = -1;
              showWeekNumber = false;
              calendarBackend = "auto";

              clockFormat = "auto";
              showSeconds = false;
              padHours12Hour = false;

              useFahrenheit = false;
              windSpeedUnit = "kmh";
              useAutoLocation = true;
              weatherEnabled = true;
              nightModeEnabled = false;

              animationSpeed = 1;
              customAnimationDuration = 500;
              syncComponentAnimationSpeeds = true;

              popoutAnimationSpeed = 1;
              popoutCustomAnimationDuration = 150;

              modalAnimationSpeed = 1;
              modalCustomAnimationDuration = 150;

              enableRippleEffects = true;
              animationVariant = 0;
              motionEffect = 0;

              m3ElevationEnabled = true;
              m3ElevationIntensity = 12;
              m3ElevationOpacity = 30;
              m3ElevationColorMode = "default";
              m3ElevationLightDirection = "top";
              m3ElevationCustomColor = "#000000";

              modalElevationEnabled = true;
              popoutElevationEnabled = true;
              barElevationEnabled = true;

              blurEnabled = true;
              blurForegroundLayers = true;
              blurLayerOutlineOpacity = 0.12;

              blurBorderEnabled = true;
              blurBorderColor = "outline";
              blurBorderCustomColor = "#ffffff";
              blurBorderOpacity = 0.35;

              wallpaperFillMode = "Fill";
              blurredWallpaperLayer = true;
              blurWallpaperOnOverview = true;

              wallpaperBackgroundColorMode = "black";
              wallpaperBackgroundCustomColor = "#000000";

              showLauncherButton = true;
              showWorkspaceSwitcher = true;
              showFocusedWindow = true;

              showWeather = true;
              showMusic = true;
              showClipboard = true;

              showCpuUsage = true;
              showMemUsage = true;
              showCpuTemp = true;
              showGpuTemp = true;

              selectedGpuIndex = 0;
              enabledGpuPciIds = [ ];

              showSystemTray = true;
              systemTrayIconTintMode = "none";
              systemTrayIconTintSaturation = 50;
              systemTrayIconTintStrength = 135;

              showClock = true;
              showNotificationButton = true;

              showBattery = true;
              showBatteryPercent = true;
              showBatteryPercentOnlyOnBattery = false;
              showBatteryTime = false;
              showBatteryTimeOnlyOnBattery = false;

              batteryPillStyle = false;
              batteryPillPercentSign = false;

              showControlCenterButton = true;
              showCapsLockIndicator = true;

              controlCenterShowNetworkIcon = true;
              controlCenterShowBluetoothIcon = true;
              controlCenterShowAudioIcon = true;
              controlCenterShowAudioPercent = false;

              controlCenterShowVpnIcon = true;

              controlCenterShowBrightnessIcon = false;
              controlCenterShowBrightnessPercent = false;

              controlCenterShowMicIcon = false;
              controlCenterShowMicPercent = true;

              controlCenterShowBatteryIcon = false;
              controlCenterShowPrinterIcon = false;

              controlCenterShowScreenSharingIcon = true;
              controlCenterShowIdleInhibitorIcon = false;
              controlCenterShowDoNotDisturbIcon = false;

              showPrivacyButton = true;
              privacyShowMicIcon = false;
              privacyShowCameraIcon = false;
              privacyShowScreenShareIcon = false;

              controlCenterWidgets = [
                {
                  id = "volumeSlider";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "brightnessSlider";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "wifi";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "bluetooth";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "audioOutput";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "audioInput";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "nightMode";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "darkMode";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "idleInhibitor";
                  enabled = true;
                  width = 50;
                }
              ];

              showWorkspaceIndex = true;
              showWorkspaceName = false;
              showWorkspacePadding = false;

              workspaceScrolling = false;
              showWorkspaceApps = false;
              workspaceDragReorder = true;

              maxWorkspaceIcons = 3;
              workspaceAppIconSizeOffset = 0;

              groupWorkspaceApps = true;
              groupActiveWorkspaceApps = false;

              workspaceFollowFocus = false;
              showOccupiedWorkspacesOnly = false;

              reverseScrolling = false;
              dwlShowAllTags = false;

              workspaceActiveAppHighlightEnabled = false;

              workspaceColorMode = "default";
              workspaceFocusedCustomColor = "#6750A4";

              workspaceOccupiedColorMode = "none";
              workspaceOccupiedCustomColor = "#625B71";

              workspaceUnfocusedColorMode = "default";
              workspaceUnfocusedCustomColor = "#49454E";

              workspaceUrgentColorMode = "default";
              workspaceUrgentCustomColor = "#B3261E";

              workspaceFocusedBorderEnabled = false;
              workspaceFocusedBorderColor = "primary";
              workspaceFocusedBorderCustomColor = "#6750A4";
              workspaceFocusedBorderThickness = 2;

              workspaceUnfocusedMonitorSeparateAppearance = false;

              workspaceUnfocusedMonitorColorMode = "default";
              workspaceUnfocusedMonitorFocusedCustomColor = "#6750A4";

              workspaceUnfocusedMonitorOccupiedColorMode = "none";
              workspaceUnfocusedMonitorOccupiedCustomColor = "#625B71";

              workspaceUnfocusedMonitorUnfocusedColorMode = "default";
              workspaceUnfocusedMonitorUnfocusedCustomColor = "#49454E";

              workspaceUnfocusedMonitorUrgentColorMode = "default";
              workspaceUnfocusedMonitorUrgentCustomColor = "#B3261E";

              workspaceUnfocusedMonitorBorderEnabled = false;
              workspaceUnfocusedMonitorBorderColor = "primary";
              workspaceUnfocusedMonitorBorderCustomColor = "#6750A4";
              workspaceUnfocusedMonitorBorderThickness = 2;

              workspaceNameIcons = { };

              waveProgressEnabled = true;
              scrollTitleEnabled = true;
              mediaAdaptiveWidthEnabled = true;
              audioVisualizerEnabled = true;

              mediaUseAlbumArtAccent = false;

              audioScrollMode = "volume";
              audioWheelScrollAmount = 5;
              audioDeviceScrollVolumeEnabled = false;

              mediaExcludePlayers = [ ];
              mediaSize = 1;

              clockCompactMode = false;

              focusedWindowCompactMode = false;
              focusedWindowSize = 1;
              focusedWindowShowIcon = true;

              runningAppsCompactMode = true;

              barMaxVisibleApps = 0;
              barMaxVisibleRunningApps = 0;
              barShowOverflowBadge = true;

              trayAutoOverflow = true;
              trayPopupSingleLine = true;
              trayMaxVisibleItems = 0;

              appsDockHideIndicators = false;
              appsDockColorizeActive = false;
              appsDockActiveColorMode = "primary";

              appsDockEnlargeOnHover = false;
              appsDockEnlargePercentage = 125;
              appsDockIconSizePercentage = 100;

              keyboardLayoutNameCompactMode = false;
              keyboardLayoutNameShowIcon = false;

              runningAppsCurrentWorkspace = true;
              runningAppsGroupByApp = false;
              runningAppsCurrentMonitor = false;

              appIdSubstitutions = [ ];

              centeringMode = "index";

              clockDateFormat = "";
              lockDateFormat = "";

              greeterRememberLastSession = true;
              greeterRememberLastUser = true;

              greeterAutoLogin = false;
              greeterEnableFprint = false;
              greeterEnableU2f = false;

              greeterWallpaperPath = "";
              greeterLockDateFormat = "";
              greeterFontFamily = "";
              greeterWallpaperFillMode = "";

              greeterPamExternallyManaged = false;
              greeterSyncPending = false;
              greeterSyncBaseline = { };

              appLauncherViewMode = "list";
              spotlightModalViewMode = "list";

              browserPickerViewMode = "grid";
              browserUsageHistory = { };

              appPickerViewMode = "grid";

              filePickerUsageHistory = {
                code = {
                  count = 1;
                  lastUsed = 1787340048369;
                  name = "Visual Studio Code";
                };
              };

              sortAppsAlphabetically = false;
              appLauncherGridColumns = 4;

              spotlightCloseNiriOverview = true;

              rememberLastQuery = false;
              rememberLastMode = true;

              spotlightSectionViewModes = { };

              appDrawerSectionViewModes = {
                apps = "list";
              };

              niriOverviewOverlayEnabled = true;
              niriOverviewLauncherStyle = "full";

              dankLauncherV2Size = "compact";
              dankLauncherV2ShowSourceBadges = true;

              dankLauncherV2BorderEnabled = false;
              dankLauncherV2BorderThickness = 2;
              dankLauncherV2BorderColor = "primary";

              dankLauncherV2ShowFooter = true;
              dankLauncherV2UnloadOnClose = false;

              dankLauncherV2IncludeFilesInAll = false;
              dankLauncherV2IncludeFoldersInAll = false;

              launcherUseOverlayLayer = false;
              launcherStyle = "full";

              spotlightBarShowModeChips = false;
              keybindsFloatingWindow = false;

              dashTabs = [
                {
                  id = "overview";
                  enabled = true;
                }
                {
                  id = "media";
                  enabled = true;
                }
                {
                  id = "wallpaper";
                  enabled = true;
                }
                {
                  id = "weather";
                  enabled = true;
                }
                {
                  id = "settings";
                  enabled = true;
                }
              ];

              networkPreference = "auto";

              iconThemeDark = "System Default";
              iconThemeLight = "System Default";
              iconThemePerMode = false;
              lastAppliedIconTheme = "";

              cursorSettings = {
                theme = "System Default";
                size = 24;

                niri = {
                  hideWhenTyping = false;
                  hideAfterInactiveMs = 0;
                };

                hyprland = {
                  hideOnKeyPress = false;
                  hideOnTouch = false;
                  inactiveTimeout = 0;
                };

                mango = {
                  cursorHideTimeout = 0;
                };
              };

              launcherLogoMode = "apps";
              launcherLogoCustomPath = "";
              launcherLogoColorOverride = "";
              launcherLogoColorInvertOnMode = false;
              launcherLogoBrightness = 0.5;
              launcherLogoContrast = 1;
              launcherLogoSizeOffset = 0;

              fontFamily = theme.font;
              monoFontFamily = theme.font;

              fontWeight = 400;
              fontScale = 1;

              textRenderType = 0;
              textRenderQuality = 0;

              notepadUseMonospace = true;
              notepadFontFamily = "";
              notepadFontSize = 14;

              notificationSummaryFontSize = 0;
              notificationBodyFontSize = 0;

              notepadShowLineNumbers = false;
              notepadAutoSave = false;

              notepadSlideoutSide = "right";
              notepadDefaultMode = "slideout";

              notepadTransparencyOverride = -1;
              notepadLastCustomTransparency = 0.7;

              notepadUseCompositorGap = false;
              notepadEdgeGap = 0;

              soundsEnabled = true;
              useSystemSoundTheme = false;

              soundLogin = false;
              soundNewNotification = true;
              soundVolumeChanged = true;
              soundPluggedIn = true;

              muteSoundsWhenMediaPlaying = true;

              acMonitorTimeout = 0;
              acLockTimeout = 0;
              acSuspendTimeout = 0;
              acSuspendBehavior = 0;
              acProfileName = "";
              acPostLockMonitorTimeout = 0;

              batteryMonitorTimeout = 0;
              batteryLockTimeout = 0;
              batterySuspendTimeout = 0;
              batterySuspendBehavior = 0;
              batteryProfileName = "";
              batteryPostLockMonitorTimeout = 0;

              batteryChargeLimit = 100;
              batteryNotifyChargeLimit = false;

              batteryCriticalThreshold = 10;
              batteryNotifyCritical = true;

              batteryLowThreshold = 20;
              batteryNotifyLow = false;

              batteryChargeLimitNotificationType = 0;
              batteryLowNotificationType = 0;
              batteryCriticalNotificationType = 1;

              batteryAutoPowerSaver = false;

              lockBeforeSuspend = false;
              loginctlLockIntegration = true;

              fadeToLockEnabled = true;
              fadeToLockGracePeriod = 5;

              fadeToDpmsEnabled = true;
              fadeToDpmsGracePeriod = 5;

              launchPrefix = "";

              gtkThemingEnabled = true;
              qtThemingEnabled = true;

              syncModeWithPortal = true;
              terminalsAlwaysDark = true;

              muxType = "tmux";
              muxUseCustomCommand = false;
              muxCustomCommand = "";
              muxSessionFilter = "";

              runDmsMatugenTemplates = true;

              matugenTemplateGtk = true;
              matugenTemplateNiri = true;
              matugenTemplateHyprland = true;
              matugenTemplateMangowc = true;

              matugenTemplateQt5ct = true;
              matugenTemplateQt6ct = true;

              matugenTemplateFirefox = true;
              matugenTemplatePywalfox = true;
              matugenTemplateZenBrowser = true;

              matugenTemplateVesktop = true;
              matugenTemplateVencord = true;
              matugenTemplateEquibop = true;

              matugenTemplateGhostty = true;
              matugenTemplateKitty = true;
              matugenTemplateFoot = true;
              matugenTemplateAlacritty = true;

              matugenTemplateNeovim = false;

              matugenTemplateWezterm = true;
              matugenTemplateDgop = true;
              matugenTemplateKcolorscheme = true;

              matugenTemplateVscode = true;
              matugenTemplateEmacs = true;
              matugenTemplateZed = true;

              matugenTemplateNeovimSettings = {
                dark = {
                  baseTheme = "github_dark";
                  harmony = 0.5;
                };

                light = {
                  baseTheme = "github_light";
                  harmony = 0.5;
                };
              };

              matugenTemplateNeovimSetBackground = true;

              showDock = true;
              dockAutoHide = true;
              dockSmartAutoHide = false;
              dockUseOverlayLayer = false;

              dockGroupByApp = false;
              dockRestoreSpecialWorkspaceOnClick = false;
              dockOpenOnOverview = false;

              dockPosition = 3;

              dockSpacing = 12;
              dockBottomGap = 0;
              dockMargin = 10;

              dockIconSize = 40;
              dockIndicatorStyle = "circle";

              dockBorderEnabled = true;
              dockBorderColor = "secondary";
              dockBorderOpacity = 1;
              dockBorderThickness = 1;

              dockIsolateDisplays = false;

              dockLauncherEnabled = true;
              dockLauncherLogoMode = "apps";
              dockLauncherLogoCustomPath = "";
              dockLauncherLogoColorOverride = "";
              dockLauncherLogoSizeOffset = 0;
              dockLauncherLogoBrightness = 0.5;
              dockLauncherLogoContrast = 1;

              dockMaxVisibleApps = 0;
              dockMaxVisibleRunningApps = 0;
              dockShowOverflowBadge = true;

              dockShowTrash = false;
              dockTrashFileManager = "default";
              dockTrashCustomCommand = "";

              notificationOverlayEnabled = false;
              notificationPopupShadowEnabled = true;
              notificationPopupPrivacyMode = false;
              notificationForegroundLayers = true;

              modalDarkenBackground = true;

              lockScreenShowPowerActions = true;
              lockScreenShowSystemIcons = true;
              lockScreenShowTime = true;
              lockScreenShowDate = true;
              lockScreenShowProfileImage = true;
              lockScreenShowPasswordField = true;
              lockScreenShowMediaPlayer = true;

              lockScreenPowerOffMonitorsOnLock = false;
              lockAtStartup = false;

              enableFprint = false;
              maxFprintTries = 15;

              enableU2f = false;
              u2fMode = "or";

              lockPamPath = "";
              lockPamInlineFprint = false;
              lockPamInlineU2f = false;
              lockPamExternallyManaged = false;
              lockU2fPamPath = "";

              lockScreenInactiveColor = "#000000";

              lockScreenNotificationMode = 0;

              lockScreenVideoEnabled = false;
              lockScreenVideoPath = "";
              lockScreenVideoCycling = false;

              lockScreenWallpaperPath = "";
              lockScreenWallpaperFillMode = "";
              lockScreenFontFamily = "";

              hideBrightnessSlider = false;

              notificationTimeoutLow = 5000;
              notificationTimeoutNormal = 5000;
              notificationTimeoutCritical = 0;

              notificationCompactMode = false;
              notificationShowTimeoutBar = false;
              notificationDedupeEnabled = true;

              notificationPopupPosition = 0;

              notificationAnimationSpeed = 1;
              notificationCustomAnimationDuration = 400;

              notificationHistoryEnabled = true;
              notificationHistoryMaxCount = 50;
              notificationHistoryMaxAgeDays = 7;

              notificationHistorySaveLow = true;
              notificationHistorySaveNormal = true;
              notificationHistorySaveCritical = true;

              notificationRules = [ ];
              notificationFocusedMonitor = false;

              osdAlwaysShowValue = false;
              osdPosition = 5;

              osdVolumeEnabled = true;
              osdMediaVolumeEnabled = true;
              osdMediaPlaybackEnabled = false;

              osdBrightnessEnabled = true;
              osdIdleInhibitorEnabled = true;
              osdMicMuteEnabled = true;
              osdCapsLockEnabled = true;
              osdPowerProfileEnabled = true;
              osdAudioOutputEnabled = true;

              powerActionConfirm = true;
              powerActionHoldDuration = 0.5;

              powerMenuActions = [
                "reboot"
                "logout"
                "poweroff"
                "lock"
                "suspend"
                "restart"
              ];

              powerMenuDefaultAction = "logout";
              powerMenuGridLayout = false;

              customPowerActionLock = "";
              customPowerActionLogout = "";
              customPowerActionSuspend = "";
              customPowerActionHibernate = "";
              customPowerActionReboot = "";
              customPowerActionPowerOff = "";

              updaterHideWidget = false;
              updaterCheckOnStart = false;

              updaterUseCustomCommand = false;
              updaterCustomCommand = "";
              updaterTerminalAdditionalParams = "";

              updaterIntervalSeconds = 1800;

              updaterIncludeFlatpak = true;
              updaterAllowAUR = true;

              updaterIgnoredPackages = [ ];

              displayNameMode = "system";

              screenPreferences = { };
              showOnLastDisplay = { };

              niriOutputSettings = { };
              hyprlandOutputSettings = { };

              displayProfiles = { };
              activeDisplayProfile = { };

              displayProfileAutoSelect = false;
              displayShowDisconnected = false;
              displaySnapToEdge = true;

              connectedFrameBarStyleBackups = { };

              barConfigs = [
                {
                  id = "default";
                  name = "Main Bar";

                  enabled = true;
                  position = 0;

                  screenPreferences = [ "all" ];
                  showOnLastDisplay = true;

                  leftWidgets = [
                    "launcherButton"
                    "workspaceSwitcher"

                    {
                      id = "focusedWindow";
                      enabled = true;
                      focusedWindowSize = 1;
                      focusedWindowCompactMode = true;
                      focusedWindowShowIcon = true;
                    }
                  ];

                  centerWidgets = [
                    {
                      id = "music";
                      enabled = true;
                      mediaSize = 0;
                    }

                    {
                      id = "clock";
                      enabled = true;
                      clockCompactMode = false;
                    }

                    "weather"
                  ];

                  rightWidgets = [
                    {
                      id = "nixMonitor";
                      enabled = true;
                    }
                    "systemTray"
                    "clipboard"
                    "cpuUsage"
                    "memUsage"

                    {
                      id = "dankDiskUsage";
                      enabled = true;
                    }

                    "notificationButton"

                    {
                      id = "battery";
                      enabled = true;
                      showBatteryPercent = true;
                      showBatteryPercentOnlyOnBattery = false;
                      showBatteryTime = false;
                      batteryPillStyle = false;
                      batteryPillPercentSign = false;
                    }

                    {
                      id = "dankAsusControlCenter";
                      enabled = true;
                    }

                    "controlCenterButton"
                  ];

                  spacing = 4;
                  innerPadding = 3;

                  barInsetPadding = -1;
                  bottomGap = 0;

                  transparency = 0.50;
                  widgetTransparency = 1;

                  squareCorners = false;
                  noBackground = true;

                  maximizeWidgetIcons = false;
                  maximizeWidgetText = false;

                  removeWidgetPadding = false;
                  widgetPadding = 8;

                  gothCornersEnabled = false;
                  gothCornerRadiusOverride = false;
                  gothCornerRadiusValue = 12;

                  borderEnabled = false;
                  borderColor = "surfaceText";
                  borderOpacity = 1;
                  borderThickness = 1;

                  widgetOutlineEnabled = false;
                  widgetOutlineColor = "primary";
                  widgetOutlineOpacity = 1;
                  widgetOutlineThickness = 1;

                  fontScale = 1;
                  iconScale = 1;

                  autoHide = false;
                  autoHideStrict = false;
                  autoHideDelay = 250;

                  showOnWindowsOpen = false;
                  openOnOverview = false;

                  visible = true;

                  popupGapsAuto = true;
                  popupGapsManual = 4;

                  maximizeDetection = true;

                  useOverlayLayer = false;

                  scrollEnabled = true;
                  scrollXBehavior = "column";
                  scrollYBehavior = "workspace";

                  shadowIntensity = 0;
                  shadowOpacity = 60;
                  shadowColorMode = "default";
                  shadowCustomColor = "#000000";

                  clickThrough = false;

                  hoverPopouts = false;
                  hoverPopoutDelay = 150;
                }
              ];

              desktopClockEnabled = false;
              desktopClockStyle = "analog";
              desktopClockTransparency = 0.8;
              desktopClockColorMode = "primary";

              desktopClockCustomColor = {
                r = 1;
                g = 1;
                b = 1;
                a = 1;

                hsvHue = -1;
                hsvSaturation = 0;
                hsvValue = 1;

                hslHue = -1;
                hslSaturation = 0;
                hslLightness = 1;

                valid = true;
              };

              desktopClockShowDate = true;
              desktopClockShowAnalogNumbers = false;
              desktopClockShowAnalogSeconds = true;

              desktopClockX = -1;
              desktopClockY = -1;

              desktopClockWidth = 280;
              desktopClockHeight = 180;

              desktopClockDisplayPreferences = [ "all" ];

              systemMonitorEnabled = false;
              systemMonitorShowHeader = true;

              systemMonitorTransparency = 0.8;
              systemMonitorColorMode = "primary";

              systemMonitorCustomColor = {
                r = 1;
                g = 1;
                b = 1;
                a = 1;

                hsvHue = -1;
                hsvSaturation = 0;
                hsvValue = 1;

                hslHue = -1;
                hslSaturation = 0;
                hslLightness = 1;

                valid = true;
              };

              systemMonitorShowCpu = true;
              systemMonitorShowCpuGraph = true;
              systemMonitorShowCpuTemp = true;

              systemMonitorShowGpuTemp = false;
              systemMonitorGpuPciId = "";

              systemMonitorShowMemory = true;
              systemMonitorShowMemoryGraph = true;

              systemMonitorShowNetwork = true;
              systemMonitorShowNetworkGraph = true;

              systemMonitorShowDisk = true;

              systemMonitorShowTopProcesses = false;
              systemMonitorTopProcessCount = 3;
              systemMonitorTopProcessSortBy = "cpu";

              systemMonitorGraphInterval = 60;
              systemMonitorLayoutMode = "auto";

              systemMonitorX = -1;
              systemMonitorY = -1;

              systemMonitorWidth = 320;
              systemMonitorHeight = 480;

              systemMonitorDisplayPreferences = [ "all" ];

              systemMonitorVariants = [ ];

              desktopWidgetPositions = { };
              desktopWidgetGridSettings = { };

              desktopWidgetInstances = [
                {
                  id = "dw_1788083196111_hpk1tmarl";
                  widgetType = "pureLyrics";
                  name = "Pure Lyrics";
                  enabled = true;

                  config = {
                    displayPreferences = [ "all" ];
                    showOnOverlay = false;
                    showOnOverview = false;
                    clickThrough = true;
                    borderOpacity = 0;
                    backgroundOpacity = 0;
                    colorMode = "primary";
                    lineCount = "5";
                    fontSize = 35;
                    textAlign = "center";
                    showOnOverviewOnly = false;
                    syncPositionAcrossScreens = true;
                  };

                  positions = { };
                }
              ];


              desktopWidgetGroups = [ ];

              builtInPluginSettings = {
                dms_settings_search = {
                  trigger = "?";
                };

                dms_clipboard_search = {
                  trigger = "cb";
                };
              };

              clipboardClickToPaste = true;
              clipboardEnterToPaste = false;

              clipboardRememberTypeFilter = false;
              clipboardTypeFilter = "all";

              clipboardVisibleEntryActions = [
                "pin"
                "edit"
                "delete"
              ];

              launcherPluginVisibility = { };
              launcherPluginOrder = [ ];

              frameEnabled = false;
              frameThickness = 16;
              frameRounding = 23;
              frameColor = "";
              frameOpacity = 1;

              frameScreenPreferences = [ "all" ];

              frameBarSize = 40;
              frameShowOnOverview = false;

              frameBlurEnabled = true;
              frameCloseGaps = true;

              frameLauncherEmergeSide = "bottom";
              frameLauncherArcExtender = false;
              frameLauncherEdgeHover = false;

              frameMode = "connected";

              barInsetPaddingShared = -1;
              barInsetPaddingSyncAll = false;
              frameBarInsetPadding = -1;

              configVersion = 13;
            };
          };
        }
      );
    };
}
