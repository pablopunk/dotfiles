return {
  {
    "FabijanZulj/blame.nvim", --  a fugitive.vim style git blame visualizer for Neovim
    keys = {
      { "<leader>gb", "<cmd>ToggleBlame<cr>", desc = "Toggle git blame", mode = { "n", "v" } },
    },
  },
  {
    "almo7aya/openingh.nvim",
    keys = {
      { "<leader>go", "<cmd>OpenInGHFile<cr>", desc = "Open file in github", mode = { "n", "v" } },
    },
  },
  {
    "NeogitOrg/neogit", -- magit for neovim (git client)
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Git client", mode = { "n", "v" } },
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
    event = { "CmdlineEnter", "InsertEnter", "CursorHold", "CursorMoved" },
    config = function()
      require("gitsigns").setup {
        signcolumn = false,
        numhl = true,
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
            "<leader>gu",
            ":Gitsigns reset_hunk<CR>",
            { noremap = true, silent = true, desc = "Undo git hunk" }
          )

          map(
            { "n", "v" },
            "<leader>gs",
            ":Gitsigns stage_hunk<CR>",
            { noremap = true, silent = true, desc = "Stage git hunk" }
          )

          map(
            { "n", "v" },
            "<leader>gr",
            ":Gitsigns undo_stage_hunk<CR>",
            { noremap = true, silent = true, desc = "Stage git hunk" }
          )

          map(
            { "n", "v" },
            "<leader>gh",
            ":Gitsigns toggle_linehl<CR>",
            { noremap = true, silent = true, desc = "Show diff colors" }
          )
          map(
            { "n", "v" },
            "<leader>gp",
            ":Gitsigns preview_hunk_inline<CR>",
            { noremap = true, silent = true, desc = "Show diff colors" }
          )
        end,
      }
    end,
  },
}
