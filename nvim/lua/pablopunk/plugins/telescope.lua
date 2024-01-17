return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim", -- It sets vim.ui.select to telescope
    },
    config = function()
      local telescope = require "telescope"
      local builtin = require "telescope.builtin"
      local actions = require "telescope.actions"

      telescope.setup {
        defaults = {
          path_display = { "truncate" }, -- if it doesn't fit, show the end (.../foo/bar.js)
          layout_strategy = "vertical",
          mappings = {
            i = {
              ["<c-k>"] = actions.cycle_history_prev,
              ["<c-j>"] = actions.cycle_history_next,
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      }

      local keymap = vim.keymap
      local function opts(desc)
        return { noremap = true, silent = true, desc = desc }
      end

      local find_prefix = "<leader>f"

      -- Files
      keymap.set("n", find_prefix .. "f", ":Telescope find_files<cr>", opts "Find files")
      keymap.set(
        "v",
        find_prefix .. "f",
        [["9y:lua require('telescope.builtin').find_files{search_file=vim.fn.getreg('9')}<cr>]],
        opts "Find file from visual selection"
      )
      keymap.set("n", find_prefix .. "g", ":Telescope git_status<cr>", opts "Find modified files in git")
      keymap.set("n", find_prefix .. "r", ":Telescope oldfiles<cr>", opts "Find recent files")
      keymap.set("n", find_prefix .. "q", ":Telescope quickfix<cr>", opts "Send quickfix list to telescope")
      keymap.set("n", "<leader>b", ":Telescope buffers<cr>", opts "Open buffers")

      -- Search
      keymap.set("n", find_prefix .. "s", ":Telescope live_grep<cr>", opts "Find string")
      keymap.set("n", find_prefix .. "w", ":Telescope grep_string<cr>", opts "Find word under cursor")
      keymap.set("n", find_prefix .. "W", function()
        builtin.grep_string { search = vim.fn.expand "<cWORD>" }
      end, opts "Find Word under cursor")
      keymap.set(
        "v",
        find_prefix .. "w",
        [["9y:lua require('telescope.builtin').grep_string{search=vim.fn.getreg('9')}<cr>]],
        opts "Find selected string"
      )

      -- Diagnostics
      keymap.set("n", find_prefix .. "d", builtin.diagnostics, opts "Find diagnostics")

      -- Yank registers
      keymap.set({ "n", "v" }, "<leader>p", builtin.registers, opts "List yank registers")

      -- Opening keymaps looks like a command palette (can search for descriptions)
      keymap.set({ "n", "v" }, "<leader><leader>", ":Telescope keymaps<cr>", opts "Command palette (kinda)")
      keymap.set({ "t" }, "<leader><leader>", "<C-\\><C-n>:Telescope keymaps<cr>", opts "Command palette (kinda)")

      -- Marks
      keymap.set("n", "<leader>mm", ":Telescope marks<cr>", opts "Show marks")

      telescope.load_extension "fzf"
      telescope.load_extension "ui-select"
    end,
  },
}
