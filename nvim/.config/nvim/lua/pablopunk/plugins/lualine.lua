return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
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
