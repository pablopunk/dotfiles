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
    "lewis6991/gitsigns.nvim",
    ft = { "gitcommit", "diff" },
    init = function()
      -- load gitsigns only when a git file is opened
      vim.api.nvim_create_autocmd({ "BufRead" }, {
        group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
        callback = function()
          vim.fn.jobstart({ "git", "-C", vim.loop.cwd(), "rev-parse" }, {
            on_exit = function(_, return_code)
              if return_code == 0 then
                vim.api.nvim_del_augroup_by_name "GitSignsLazyLoad"
                vim.schedule(function()
                  require("lazy").load { plugins = { "gitsigns.nvim" } }
                end)
              end
            end,
          })
        end,
      })
    end,
    opts = {
      signcolumn = false,
      numhl = true,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

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
