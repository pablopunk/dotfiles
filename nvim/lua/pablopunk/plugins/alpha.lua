return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require "alpha"
    local dashboard = require "alpha.themes.dashboard"

    -- Set header
    dashboard.section.header.val = {
      [[                               __                ]],
      [[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
      [[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
      [[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
      [[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
      [[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
      [[                                                 ]],
      [[                                       @pablopunk]],
    }

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button("e", " New file", ":ene <BAR> startinsert <cr>"),
      dashboard.button("g", " Git files", ":Telescope git_status <cr>"),
      dashboard.button("f", " Find files", ":Telescope find_files <cr>"),
      dashboard.button("o", " Recent", ":Telescope oldfiles <cr>"),
    }
    alpha.setup(dashboard.opts)
  end,
}
