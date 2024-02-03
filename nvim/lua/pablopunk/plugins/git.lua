local git_prefix = "<leader>g"

return {
  {
    "FabijanZulj/blame.nvim", --  a fugitive.vim style git blame visualizer for Neovim
    keys = {
      { git_prefix .. "b", "<cmd>ToggleBlame<cr>", desc = "Toggle git blame", mode = { "n", "v" } },
    },
  },
  {
    "almo7aya/openingh.nvim",
    keys = {
      { git_prefix .. "o", "<cmd>OpenInGHFile<cr>", desc = "Open file in github", mode = { "n", "v" } },
    },
  },
  {
    "NeogitOrg/neogit", -- magit for neovim (git client)
    keys = {
      { git_prefix .. "g", "<cmd>Neogit<cr>", desc = "Git client", mode = { "n", "v" } },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
    config = function()
      require("neogit").setup {}
    end,
  },
  {
    "lewis6991/gitsigns.nvim", -- leftside git status
    event = "VeryLazy",
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
            git_prefix .. "u",
            ":Gitsigns reset_hunk<CR>",
            { noremap = true, silent = true, desc = "Undo git hunk" }
          )
        end,
      }
    end,
  },
  {
    "akinsho/git-conflict.nvim",
    event = "VeryLazy",
    config = true,
  },
}
