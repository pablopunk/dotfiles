-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    -- Use round window corners.
    rounding = 6,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- Animate switching between workspaces (Omarchy disables this by default).
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#misc
hl.config({
  misc = {
    -- When a window is zoomed/fullscreen, what happens if you focus another window:
    --   0 = keep focus on the zoomed window
    --   1 = move the zoom to the newly focused window (Omarchy default)
    --   2 = un-zoom the current window and focus the other one normally
    on_focus_under_fullscreen = 2,
  },
})

-- Allow directional focus (HYPER+h/j/k/l) to reach other windows while one is
-- zoomed/fullscreen. Without this Hyprland blocks focus from leaving a
-- fullscreen window, so the other windows in the split become unreachable.
hl.config({
  binds = {
    movefocus_cycles_fullscreen = true,
  },
})

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- >>> omaland managed block >>>
-- Written by Omaland. Safe to hand-edit: Omaland re-reads this block
-- every time it opens, and only ever rewrites what's between the fences.
hl.config({
  decoration = {
    active_opacity = 0.97,
    border_part_of_window = true,
    dim_inactive = false,
    fullscreen_opacity = 1,
    inactive_opacity = 0.93,
    rounding = 6,
    rounding_power = 10,

    blur = {
      noise = 0.083,
      passes = 3,
      size = 10,
    },

    glow = {
      enabled = false,
    },

    shadow = {
      enabled = false,
    },
  },

  general = {
    border_size = 2,
    gaps_in = 4,
    gaps_out = 8,
    layout = "scrolling",

    snap = {
      enabled = true,
    },
  },
})
-- <<< omaland managed block <<<
