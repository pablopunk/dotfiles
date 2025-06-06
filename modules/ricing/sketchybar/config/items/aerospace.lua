-- items/workspaces.lua
local app_icons = require "helpers.app_icons"
local colors = require "colors"
local settings = require "settings"

local max_workspaces = 10
local query_workspaces =
  "aerospace list-workspaces --all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"
local workspace_monitor = {}

-- -- Add padding to the left
-- sbar.add("item", {
--   icon = {
--     color = colors.with_alpha(colors.white, 0.3),
--     highlight_color = colors.white,
--     drawing = false,
--   },
--   label = {
--     color = colors.grey,
--     highlight_color = colors.white,
--     drawing = false,
--   },
--   background = {
--     color = colors.bg0,
--     border_width = 1,
--     height = 24,
--     border_color = colors.black,
--     corner_radius = 100,
--     padding_left = 12,
--     drawing = false,
--   },
--   padding_left = 6,
--   padding_right = 0,
-- })
--
local workspaces = {}

local workspace_letters = { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p" }

local function updateWindows(workspace_index)
  local workspace_name = workspace_letters[workspace_index]:upper()
  local get_windows =
    string.format("aerospace list-windows --workspace %s --format '%%{app-name}' --json", workspace_name)
  local query_visible_workspaces =
    "aerospace list-workspaces --visible --monitor all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"
  local get_focus_workspaces = "aerospace list-workspaces --focused"
  sbar.exec(get_windows, function(open_windows)
    sbar.exec(get_focus_workspaces, function(focused_workspaces)
      sbar.exec(query_visible_workspaces, function(visible_workspaces)
        local icon_line = ""
        local no_app = true
        for i, open_window in ipairs(open_windows) do
          no_app = false
          local app = open_window["app-name"]
          local lookup = app_icons[app]
          local icon = ((lookup == nil) and app_icons["Default"] or lookup)
          icon_line = icon_line .. " " .. icon
        end

        sbar.animate("tanh", 10, function()
          for i, visible_workspace in ipairs(visible_workspaces) do
            if no_app and workspace_name == tostring(visible_workspace["workspace"]):upper() then
              local monitor_id = visible_workspace["monitor-appkit-nsscreen-screens-id"]
              icon_line = app_icons["Finder"]
              workspaces[workspace_index]:set {
                icon = { drawing = true },
                label = {
                  string = icon_line,
                  drawing = true,
                  -- padding_right = 20,
                  font = "sketchybar-app-font:Regular:16.0",
                  y_offset = -1,
                },
                background = { drawing = true },
                padding_right = 1,
                padding_left = 1,
                display = monitor_id,
              }
              return
            end
          end
          if no_app and workspace_name ~= tostring(focused_workspaces):upper() then
            workspaces[workspace_index]:set {
              icon = { drawing = false },
              label = { drawing = false },
              background = { drawing = false },
              padding_right = 0,
              padding_left = 0,
            }
            return
          end
          if no_app and workspace_name == tostring(focused_workspaces):upper() then
            icon_line = ""
            workspaces[workspace_index]:set {
              icon = { drawing = true },
              label = {
                string = icon_line,
                drawing = true,
                -- padding_right = 20,
                font = "sketchybar-app-font:Regular:16.0",
                y_offset = -1,
              },
              background = { drawing = true },
              padding_right = 1,
              padding_left = 1,
            }
          end

          workspaces[workspace_index]:set {
            icon = { drawing = true },
            label = { drawing = true, string = icon_line },
            background = { drawing = true },
            padding_right = 1,
            padding_left = 1,
          }
        end)
      end)
    end)
  end)
end

local function updateWorkspaceMonitor(workspace_index)
  local workspace_name = workspace_letters[workspace_index]:upper()
  sbar.exec(query_workspaces, function(workspaces_and_monitors)
    for _, entry in ipairs(workspaces_and_monitors) do
      local space_name = tostring(entry.workspace):upper()
      local monitor_id = math.floor(entry["monitor-appkit-nsscreen-screens-id"])
      workspace_monitor[space_name] = monitor_id
    end
    workspaces[workspace_index]:set {
      display = workspace_monitor[workspace_name],
    }
  end)
end

for workspace_index = 1, max_workspaces do
  local workspace_name = workspace_letters[workspace_index]:upper()
  local workspace = sbar.add("item", {
    icon = {
      color = colors.with_alpha(colors.fg, 0.5),
      highlight_color = colors.fg,
      drawing = false,
      font = { family = settings.font.numbers },
      string = workspace_name,
      padding_left = 12,
      padding_right = 5,
    },
    label = {
      padding_right = 12,
      color = colors.with_alpha(colors.fg, 0.5),
      highlight_color = colors.fg,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
    },
    padding_right = 5,
    padding_left = 5,
    background = {
      color = colors.bg,
      height = 24,
    },
    click_script = "aerospace workspace " .. workspace_name,
  })

  workspaces[workspace_index] = workspace

  workspace:subscribe("aerospace_workspace_change", function(env)
    local focused_workspace = tostring(env.FOCUSED_WORKSPACE):upper()
    local is_focused = focused_workspace == workspace_name

    sbar.animate("tanh", 10, function()
      workspace:set {
        icon = { highlight = is_focused },
        label = { highlight = is_focused },
        background = {
          -- border_width = is_focused and 2 or 1,
        },
        blur_radius = 30,
      }
    end)
  end)

  workspace:subscribe("aerospace_focus_change", function()
    updateWindows(workspace_index)
  end)

  workspace:subscribe("display_change", function()
    updateWorkspaceMonitor(workspace_index)
    updateWindows(workspace_index)
  end)

  -- initial setup
  updateWorkspaceMonitor(workspace_index)
  updateWindows(workspace_index)
  sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
    if tostring(focused_workspace):upper() == workspace_name then
      workspaces[workspace_index]:set {
        icon = { highlight = true },
        label = { highlight = true },
        -- background = { border_width = 2 },
      }
    end
  end)
end
