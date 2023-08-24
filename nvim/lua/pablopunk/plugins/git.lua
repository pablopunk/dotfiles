return {
  "tpope/vim-fugitive", -- git tools
  "tpope/vim-rhubarb", -- :GBrowse
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
          end, { expr = true })

          map("n", "(", function()
            if vim.wo.diff then
              return "("
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true })

          -- Actions
          -- map({ "n", "v" }, "<leader>ga", ":Gitsigns stage_hunk<CR>")
          -- map({ "n", "v" }, "<leader>gA", ":Gitsigns undo_stage_hunk<CR>")
          map({ "n", "v" }, "<leader>u", ":Gitsigns reset_hunk<CR>")
        end,
      }
    end,
  },
  {
    "kdheepak/lazygit.nvim", -- git UI
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      vim.keymap.set("n", "<leader>g", "<cmd>LazyGitCurrentFile<cr>")
    end,
  },
}
