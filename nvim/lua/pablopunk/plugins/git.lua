return {
  {
    "FabijanZulj/blame.nvim", --  a fugitive.vim style git blame visualizer for Neovim
    config = function()
      vim.keymap.set("n", "<leader>gb", "<cmd>ToggleBlame<cr>")
    end,
  },
  {
    "almo7aya/openingh.nvim",
    config = function()
      vim.keymap.set(
        { "n", "v" },
        "<leader>go",
        "<cmd>OpenInGHFile<cr>",
        { noremap = true, silent = true, desc = "Open file in github" }
      )
    end,
  },
  {
    "NeogitOrg/neogit", -- magit for neovim (git client)
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
    config = function()
      require("neogit").setup {}
      vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>")
    end,
  },
  {
    "lewis6991/gitsigns.nvim", -- leftside git status
    config = function()
      require("gitsigns").setup {
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", ")", function()
            if vim.wo.diff then
              return ")"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = ") or Go to next git hunk" })

          map("n", "(", function()
            if vim.wo.diff then
              return "("
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = ") or Go to previous git hunk" })

          map(
            { "n", "v" },
            "<leader>u",
            ":Gitsigns reset_hunk<CR>",
            { noremap = true, silent = true, desc = "Undo git hunk" }
          )
        end,
      }
    end,
  },
}
