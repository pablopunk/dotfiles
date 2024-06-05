local wezterm = require "wezterm"

local config = wezterm.config_builder()

local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end

function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Macchiato"
  else
    return "Catppuccin Latte"
  end
end

wezterm.on("window-config-reloaded", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

config.color_scheme = scheme_for_appearance(get_appearance())
config.xcursor_theme = "Adwaita"

config.enable_tab_bar = false

config.font = wezterm.font_with_fallback {
  -- "Geist",
  "SF Mono Powerline",
  "Nova",
  "Dank Mono",
  "Monaspace Neon Regular",
  "Victor Mono",
  "Hack Nerd Font",
  "Hack",
  "CaskaydiaCove Nerd Font",
  "Cascadia Code",
  "Comic Mono",
  "SF Mono",
  "Fira Mono for Powerline",
}
config.font_size = 16.0
config.line_height = 1.2
config.window_close_confirmation = "NeverPrompt"

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20

return config
