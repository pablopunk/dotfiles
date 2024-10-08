{ pkgs, ... }: {
  homebrew = {
    enable = true;
    casks = [
      "alt-tab"
      "arc"
      "cleanshot"
      "hiddenbar"
      "iina"
      "karabiner-elements"
      "latest"
      "missive"
      "notion-calendar"
      "raycast"
      "sf-symbols"
      "spotify"
      "telegram-desktop"
      "whatsapp"
      "zed"
    ];
    onActivation.cleanup = "zap";
  };

  # macOS settings
  system.defaults = {
    dock = {
      autohide = true;
      orientation = "bottom";
      autohide-delay = 0.0;
      persistent-apps = [ # Apps in the dock
        "/Applications/Arc.app"
        "/Applications/Cursor.app"
        "${pkgs.wezterm}/Applications/Wezterm.app"
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
