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
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
    config = function()
      require("neogit").setup {}
    end,
  },
  {
    "lewis6991/gitsigns.nvim", -- leftside git status
    event = "User FilePost",
    opts = {
      signcolumn = false,
      numhl = true,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- stylua: ignore start
        map("n", "]g", gs.next_hunk, "Next Hunk")
        map("n", "[g", gs.prev_hunk, "Prev Hunk")
        map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>gh", ":Gitsigns toggle_linehl<CR>", "Show diff colors")
        map("n", "<leader>ghS", gs.stage_hunk, "Stage Hunk")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>gd", gs.diffthis, "Show git diff for this file")
        map({ "o", "x" }, "ig", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
      end,
    },
  },
}
