local wezterm = require "wezterm"
local config = wezterm.config_builder()

--- Colors {{{
local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end

local function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Tokyo Night"
  else
    return "Gruvbox light, hard (base16)"
  end
end

wezterm.on("window-config-reloaded", function(window)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

config.color_scheme = scheme_for_appearance(get_appearance())
--- }}}

--- Fonts {{{
config.font = wezterm.font_with_fallback {
  "Source Code Pro for Powerline",
  "Fira Mono for Powerline",
  "CaskaydiaCove Nerd Font Mono",
  "Nova Mono for Powerline",
  "SF Mono Powerline",
  "Dank Mono",
  "Monaspace Neon Regular",
  "Victor Mono",
  "Hack Nerd Font",
  "Hack",
  "Cascadia Code",
  "Comic Mono",
  "SF Mono",
}
config.font_size = 16.0
config.line_height = 1.2
--- }}}

--- Window {{{
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "TITLE | RESIZE" -- one of "NONE", "TITLE", "RESIZE", or "TITLE | RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20
config.window_padding = {
  left = 16,
  right = 16,
  top = 16,
  bottom = 0, -- for some reason there's already a gap at the bottom
}
--- }}}

--- Fix for nix visual bug {{{
config.front_end = "WebGpu"
--- }}}

--- Keys {{{
config.keys = {
  -- I use tmux instead of wezterm's panes, and their keybindings are messing with my config
  { key = '"', mods = "ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = '"', mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "%", mods = "ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "%", mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "'", mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "5", mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "T", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "T", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "Z", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "Z", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "t", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  -- { key = "t", mods = "SUPER", action = wezterm.action.DisableDefaultAssignment },
  { key = "z", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "LeftArrow", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "LeftArrow", mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "RightArrow", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "RightArrow", mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "UpArrow", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "UpArrow", mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "DownArrow", mods = "SHIFT|CTRL", action = wezterm.action.DisableDefaultAssignment },
  { key = "DownArrow", mods = "SHIFT|ALT|CTRL", action = wezterm.action.DisableDefaultAssignment },
}
--- }}}

return config
