return {
  { "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons", config = true },
  "markonm/traces.vim", -- to show in real time what your :s commands will replace
  {
    "pablopunk/todo.nvim",
    dev = true, -- use local version if exists
    config = function()
      require("todo").setup()
      vim.keymap.set("n", "<leader>t", "<cmd>TodoToggle<cr>", { silent = true, desc = "Open todo.nvim" })
    end,
  },
  {
    "szw/vim-maximizer", -- maximize the current buffer (toggle)
    config = function()
      vim.keymap.set("n", "<leader>m", ":MaximizerToggle<cr>", { silent = true, desc = "Maximize current buffer" })
    end,
  },
  {
    "nvim-lualine/lualine.nvim", -- statusline
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      options = {
        -- use empty char as separators
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      },
    },
  },
  {
    "folke/noice.nvim", -- wow this feels wrong. Gets rid of the command line and replaces it with a floating window and notifications
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      views = { -- display the cmdline and popupmenu together https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#display-the-cmdline-and-popupmenu-together
        cmdline_popup = {
          position = {
            row = 5,
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = 8,
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
          },
        },
      },
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        hover = {
          enabled = true,
          silent = true, -- don't show message if not available
        },
      },
      -- you can enable a preset for easier configuration
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = false, -- add a border to hover docs and signature help
      },
    },
  },
}
