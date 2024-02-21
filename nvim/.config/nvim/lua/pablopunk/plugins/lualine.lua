return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  config = function()
    require("lualine").setup {
      options = {
        component_separators = "",
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = {
          { "mode", separator = { left = "" }, right_padding = 1 },
        },
        lualine_b = { "filename" },
        lualine_c = { "branch" },
        lualine_x = {
          {
            "diagnostics",
            source = { "nvim" },
            sections = { "error" },
          },
          {
            function()
              local clients = {}
              for _, client in ipairs(vim.lsp.buf_get_clients()) do
                table.insert(clients, client.name)
              end
              return table.concat(clients, "/")
            end,
            icon = "↯",
          },
        },
        lualine_y = { "filetype" },
        lualine_z = { { "location", separator = { right = "" }, left_padding = 1 } },
      },
    }
  end,
}
