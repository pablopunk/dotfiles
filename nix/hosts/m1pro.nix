{ pkgs, ... }: {
  homebrew = {
    enable = true;
    casks = [
      "alt-tab"
      "arc"
      "aws-vault"
      "cleanshot"
      "cloudflare-warp"
      "hiddenbar"
      "iina"
      "karabiner-elements"
      "latest"
      "missive"
      "monitorcontrol"
      "notion-calendar"
      "orbstack"
      "raycast"
      "scroll-reverser"
      "sf-symbols"
      "slack"
      "spotify"
      "telegram-desktop"
      "whatsapp"
      "zoom"
    ];
    onActivation.cleanup = "zap";
  };

  # macOS settings
  system.defaults = {
    dock = {
      autohide = false;
      orientation = "right";
      autohide-delay = 0.0;
      persistent-apps = [ # Apps in the dock
        "/Applications/Notion Calendar.app"
        "/Applications/Missive.app"
        "/Applications/Arc.app"
        "/Applications/Slack.app"
        "/Applications/Cursor.app"
        "${pkgs.wezterm}/Applications/Wezterm.app"
        "/Applications/zoom.us.app"
        "/Applications/Spotify.app"
        "/System/Applications/System Settings.app"
      ];
    };
    trackpad = {
      Clicking = true;
      Dragging = true;
    };
    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
    };
  };
}
