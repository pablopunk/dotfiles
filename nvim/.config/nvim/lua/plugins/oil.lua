return {
  {
    enabled = false,
    "stevearc/oil.nvim",
    init = function()
      require("core.mappings").oil()
    end,
    cmd = "Oil",
    opts = {
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["<Left>"] = "actions.parent",
      },
    },
  },
}
