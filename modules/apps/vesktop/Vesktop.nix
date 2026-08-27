{ self, inputs, ... }: {
  flake.homeModules.apps.Vesktop = { pkgs, config, ... }:
  let
    # Vesktop's own app settings (splash screen, tray, spellcheck) - the
    # real machine's own values, transcribed straight across.
    vesktopSettings = {
      discordBranch = "stable";
      minimizeToTray = true;
      arRPC = true;
      spellCheckLanguages = [ "en-GB" "en-IN" "en" ];
      splashColor = "rgb(255, 255, 255)";
      splashBackground = "rgb(29, 37, 43)";
    };

    # Vencord's own settings, same idea, minus `plugins` (below) - every
    # Vencord plugin ships built into the app itself, so unlike Android
    # Studio's JetBrains plugins there's nothing here to fetch, only
    # settings to declare.
    vencordSettings = {
      autoUpdate = true;
      autoUpdateNotification = true;
      useQuickCss = true;
      themeLinks = [ ];
      eagerPatches = false;
      enabledThemes = [ ];
      enableReactDevtools = false;
      frameless = false;
      transparent = false;
      winCtrlQ = false;
      disableMinSize = false;
      winNativeTitleBar = false;
      notifications = {
        timeout = 5000;
        position = "bottom-right";
        useNative = "not-focused";
        logLimit = 50;
      };
      cloud = {
        authenticated = false;
        url = "https://api.vencord.dev/";
        settingsSync = false;
        settingsSyncVersion = 1784232412821;
      };
      uiElements = {
        chatBarButtons = { };
        messagePopoverButtons = { };
      };
      windowsMaterial = "none";
    };

    # Every plugin actually enabled on the real machine (with its real
    # non-default settings), plus a handful kept explicit for other
    # reasons - see the comment below the attrset. Everything else - every
    # plugin that's plain `{ enabled = false; }` with nothing else set -
    # is deliberately omitted rather than spelled out: Vencord's own
    # `Settings.ts` (`getDefaultValue`) resolves a *missing* plugin entry
    # to `plugins[key].required || plugins[key].enabledByDefault || false`,
    # i.e. `false` for any plugin that isn't itself marked required/
    # enabled-by-default in its own source - confirmed against Vencord's
    # actual source, not assumed. Cross-checked every plugin in this repo
    # with a static `required: true` or `enabledByDefault: true`
    # (DisableDeepLinks, BadgeAPI, CrashHandler, WebContextMenus,
    # WebKeybinds, WebScreenShareFixes) against the real settings - every
    # one of them is already `true` here, so omitting the ~115 plain
    # `false` entries changes nothing observable.
    vencordPlugins = {
      # The "*API" plugins are kept explicit either way, even the two
      # disabled ones (MessagePopoverAPI, ServerListAPI) - these are
      # framework plugins other plugins hook into, not plain features,
      # and whether some *other* enabled plugin's dependency graph could
      # ever promote one back to "required" isn't something worth
      # gambling on for a handful of lines.
      ChatInputButtonAPI = { enabled = true; };
      CommandsAPI = { enabled = true; };
      DynamicImageModalAPI = { enabled = true; };
      MemberListDecoratorsAPI = { enabled = true; };
      MessageAccessoriesAPI = { enabled = true; };
      MessageDecorationsAPI = { enabled = true; };
      MessageEventsAPI = { enabled = true; };
      MessagePopoverAPI = { enabled = false; };
      MessageUpdaterAPI = { enabled = true; };
      ServerListAPI = { enabled = false; };
      UserSettingsAPI = { enabled = true; };
      BadgeAPI = { enabled = true; };

      AlwaysExpandRoles = { enabled = true; };
      BetterGifPicker = { enabled = true; };
      BetterRoleContext = { enabled = true; };
      BetterRoleDot = {
        enabled = true;
        bothStyles = false;
        copyRoleColorInProfilePopout = false;
      };
      BetterSessions = {
        enabled = true;
        backgroundCheck = false;
      };
      BetterSettings = {
        enabled = true;
        disableFade = true;
        organizeMenu = true;
        eagerLoad = true;
      };
      BetterUploadButton = { enabled = true; };
      BiggerStreamPreview = { enabled = true; };
      BlurNSFW = {
        enabled = true;
        blurAmount = 10;
      };
      CallTimer = { enabled = true; };
      ClearURLs = { enabled = true; };
      CrashHandler = { enabled = true; };
      CustomIdle = {
        # Disabled, but keeps its non-default settings in case it's ever
        # re-enabled through Vesktop's own UI.
        enabled = false;
        idleTimeout = 10;
        remainInIdle = true;
      };
      DisableCallIdle = { enabled = true; };
      Experiments = {
        enabled = true;
        toolbarDevMenu = false;
      };
      FakeNitro = {
        enabled = true;
        enableStickerBypass = true;
        enableStreamQualityBypass = true;
        enableEmojiBypass = true;
        transformEmojis = true;
        transformStickers = true;
        transformCompoundSentence = false;
      };
      FakeProfileThemes = {
        enabled = true;
        nitroFirst = true;
      };
      FavoriteEmojiFirst = { enabled = true; };
      FixImagesQuality = {
        enabled = true;
        originalImagesInChat = false;
      };
      FixSpotifyEmbeds = { enabled = true; };
      FixYoutubeEmbeds = { enabled = true; };
      ForceOwnerCrown = { enabled = true; };
      FriendsSince = { enabled = true; };
      GameActivityToggle = {
        enabled = true;
        location = "PANEL";
        oldIcon = false;
      };
      ImplicitRelationships = { enabled = true; };
      MemberCount = { enabled = true; };
      MentionAvatars = {
        enabled = true;
        showAtSymbol = true;
      };
      MessageClickActions = { enabled = true; };
      MessageLogger = {
        enabled = true;
        collapseDeleted = false;
        deleteStyle = "text";
        ignoreBots = false;
        ignoreSelf = false;
        ignoreUsers = "";
        ignoreChannels = "";
        ignoreGuilds = "";
        logEdits = true;
        logDeletes = true;
        inlineEdits = true;
      };
      NewGuildSettings = {
        # Same as CustomIdle - disabled, non-default settings kept.
        enabled = false;
        guild = true;
        messages = 3;
        everyone = true;
        role = true;
        highlights = true;
        events = true;
        showAllChannels = true;
      };
      NoProfileThemes = { enabled = true; };
      OnePingPerDM = {
        enabled = true;
        channelToAffect = "both_dms";
        allowMentions = false;
        allowEveryone = false;
      };
      OpenInApp = {
        enabled = true;
        spotify = true;
        steam = true;
        epic = true;
        tidal = true;
        itunes = true;
      };
      PermissionsViewer = { enabled = true; };
      PlatformIndicators = {
        enabled = true;
        colorMobileIndicator = true;
        list = true;
        badges = true;
        messages = true;
      };
      PreviewMessage = { enabled = true; };
      RelationshipNotifier = {
        enabled = true;
        offlineRemovals = true;
        groups = true;
        servers = true;
        friends = true;
        friendRequestCancels = true;
      };
      RoleColorEverywhere = { enabled = true; };
      ServerInfo = { enabled = true; };
      ShikiCodeblocks = {
        enabled = true;
        theme = "https://cdn.jsdelivr.net/gh/shikijs/textmate-grammars-themes@bc5436518111d87ea58eb56d97b3f9bec30e6b83/packages/tm-themes/themes/one-dark-pro.json";
        tryHljs = "SECONDARY";
        useDevIcon = "GREYSCALE";
        bgOpacity = 100;
      };
      ShowConnections = {
        enabled = true;
        iconSpacing = 1;
        iconSize = 32;
      };
      ShowHiddenChannels = {
        enabled = true;
        showMode = 0;
        hideUnreads = true;
        defaultAllowedUsersAndRolesDropdownState = false;
      };
      ShowHiddenThings = {
        enabled = true;
        showTimeouts = true;
        showInvitesPaused = true;
        showModView = true;
      };
      ShowMeYourName = {
        enabled = true;
        mode = "user-nick";
        friendNicknames = "dms";
        displayNames = false;
        inReplies = false;
      };
      SpotifyControls = {
        enabled = true;
        hoverControls = false;
      };
      ViewIcons = { enabled = true; };
      VoiceDownload = { enabled = true; };
      WebKeybinds = { enabled = true; };
      WebScreenShareFixes = { enabled = true; };
      WhoReacted = { enabled = true; };
      NoTrack = {
        enabled = true;
        disableAnalytics = true;
      };
      Settings = {
        enabled = true;
        settingsLocation = "aboveNitro";
        includeVencordInfoWhenCopying = true;
      };
      DisableDeepLinks = { enabled = true; };
      SupportHelper = { enabled = true; };
      WebContextMenus = { enabled = true; };
      ConcatenatedComponentExtractor = { enabled = true; };
    };
  in
  {
    home.packages = [ pkgs.vesktop ];

    # `force = true`: Vesktop rewrites both of these itself whenever a
    # setting is toggled through its own UI, same trade-off already
    # accepted elsewhere in this repo for exactly this reason (DMS's
    # settings.json, Lutris's runners/wine.yml) - an in-app change sticks
    # until the next rebuild, then resets to what's declared here.
    home.file.".config/vesktop/settings.json" = {
      text = builtins.toJSON vesktopSettings;
      force = true;
    };
    home.file.".config/vesktop/settings/settings.json" = {
      text = builtins.toJSON (vencordSettings // { plugins = vencordPlugins; });
      force = true;
    };

    home.file.".config/matugen/templates/vesktop-colors.css".text = self.matugenTemplates.vesktop;

    # quickCss.css itself is deliberately *not* a home.file - matugen owns
    # it outright, rewritten on every wallpaper change, same as
    # Btop/Heroic/Steam/Wine/Android Studio's own matugen output files.
    # `useQuickCss = true` above is what makes Vesktop actually load it.
    vayori.matugenTemplates.vesktop = ''
      [templates.vesktop]
      input_path = '${config.home.homeDirectory}/.config/matugen/templates/vesktop-colors.css'
      output_path = '${config.home.homeDirectory}/.config/vesktop/settings/quickCss.css'
    '';
  };
}
