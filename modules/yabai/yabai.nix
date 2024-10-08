{ pkgs, ... }: {
  enable = true;
  package = pkgs.yabai;
  enableScriptingAddition = true;
  config = {
    focus_follows_mouse          = "off";
    mouse_follows_focus          = "off";
    window_placement             = "second_child";
    window_opacity               = "on";
    window_opacity_duration      = "0.2";
    window_topmost               = "on";
    window_shadow                = "float";
    active_window_opacity        = "1.0";
    normal_window_opacity        = "0.9";
    split_ratio                  = "0.50";
    auto_balance                 = "on";
    mouse_modifier               = "ctrl";
    mouse_action1                = "move";
    mouse_action2                = "resize";
    layout                       = "bsp";
    top_padding                  = 8;
    bottom_padding               = 8;
    left_padding                 = 8;
    right_padding                = 8;
    window_gap                   = 8;
  };

  extraConfig = ''
    # draggin a window to the center of another window will swap both windows
    yabai -m mouse_drop_action swap

    # Disable apps
    yabai -m rule --add app="^System Settings$" manage=off
    yabai -m rule --add app="^Ajustes" manage=off
    yabai -m rule --add app="^Karabiner-Elements$" manage=off
    yabai -m rule --add app="^Finder$" manage=off
    yabai -m rule --add app="CleanShot X" manage=off
    yabai -m rule --add app="Raycast" manage=off
    yabai -m rule --add app="Yonna" manage=off
    yabai -m rule --add app="Shop" manage=off
    '';
}