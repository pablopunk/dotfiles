-- # vim:fileencoding=utf-8:ft=lua:foldmethod=indent
-- Enable Neovim's built-in loader
vim.loader.enable()

local add, now, later -- mini.deps will be setup later
local light_theme, dark_theme -- see colors() implementation

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.noremap = opts.noremap == nil and true or opts.noremap
  opts.silent = opts.silent == nil and true or opts.silent
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function setup_options()
  vim.opt.hidden = true
  vim.opt.cmdheight = 0
  vim.opt.number = true
  -- vim.opt.relativenumber = true
  vim.opt.signcolumn = "no"
  vim.opt.showmode = false
  vim.opt.laststatus = 2
  vim.opt.statusline = "%t"
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.expandtab = true
  vim.opt.autoindent = true
  vim.opt.wrap = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  vim.opt.cursorline = true
  vim.opt.termguicolors = true
  vim.opt.backspace = "indent,eol,start"
  vim.opt.splitright = true
  vim.opt.splitbelow = true
  vim.opt.iskeyword:append("-")
  vim.opt.path:append("**")
  vim.opt.wildmenu = true
  vim.opt.wildignore:append("**/node_modules/**,**/dist/**")
  vim.opt.fillchars = "eob: " -- no ~ chars at end of buffer
  -- vim.opt.winborder = "rounded" -- this is nice for a barebones neovim, but every other plugin adds a border so it would be twice as wide
end

local function tmux_session()
  -- prompt for a tmux session name and then call tx <name>
  vim.ui.input({ prompt = "Session name: " }, function(input)
    vim.cmd("!tx " .. input)
  end)
end

local function setup_mappings()
  vim.g.mapleader = " "

  map("i", "jk", "<esc>", { desc = "ESC" })

  map("n", "<c-c>", "<esc>", { desc = "ESC" })
  map("v", "<c-c>", "<esc>", { desc = "ESC" })
  map("i", "<c-c>", "<esc>", { desc = "ESC" })
  map({ "n", "v", "x", "o", "c" }, "q:", "<nop>", { desc = "Noop" })
  map({ "n", "v", "x", "o" }, "Q", "<nop>", { desc = "Noop" })

  -- Search with - (Spanish layout)
  map("n", "-", "/", { silent = false })

  -- Use () instead of []
  vim.api.nvim_command([[
    nmap ( [
    nmap ) ]
    omap ( [
    omap ) ]
    xmap ( [
    xmap ) ]
  ]])

  map("n", "<leader>h", ":nohlsearch<cr>", { desc = "Remove highlights" })

  map("n", "<leader>tx", tmux_session, { desc = "Switch tmux session" })

  -- Quit/Save file
  local function quit()
    local bufnr = vim.api.nvim_get_current_buf()
    local is_last_buffer = #vim.fn.getbufinfo({ buflisted = 1 }) == 1
    local is_existing_file = vim.fn.filereadable(vim.api.nvim_buf_get_name(bufnr)) == 1
    if not is_last_buffer then
      vim.cmd("bd!")
    elseif is_last_buffer and is_existing_file then
      vim.cmd("wq!")
    else
      vim.cmd("q!")
    end
  end
  map({ "n", "v" }, "<c-q>", quit, { desc = "Close file buffer" })
  map({ "n", "v" }, "<leader>q", quit, { desc = "Close file buffer" })
  map({ "n", "v" }, "<leader>x", ":xa!<cr>", { desc = "Save all files and quit" })
  map({ "n", "v" }, "<leader>s", ":w!<cr>", { desc = "Save file" })
  map({ "n", "v" }, "<c-s>", ":w!<cr>", { desc = "Save file" })
  map({ "n", "v" }, "<leader>S", ":noa w!<cr>", { desc = "Save without formatting" })
  map("n", "<leader>wca", ":silent! %bd<cr>", { desc = "Close all buffers" })
  map("n", "<leader>wcA", ":silent %bd|e#|bd#<cr>", { desc = "Close all buffers except the current one" })

  -- Move lines
  map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move line down" })
  map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move line up" })

  -- File path shared
  map("n", "<leader>fpp", ":file<cr>", { desc = "Print file path" })
  map("n", "<leader>fpa", ":let @+ = expand('%:p')<cr>", { desc = "Copy file path (absolute)" })
  map("n", "<leader>fpr", ":let @+ = expand('%:p:~:.')<cr>", { desc = "Copy file path (relative)" })
  map("n", "<leader>fpi", ":let @0 = expand('%:p:t')<cr>\"0p", { desc = "Insert file name" })

  -- System clipboard
  map({ "n", "v" }, "<leader>y", '"*y', { desc = "Copy to system clipboard" })

  -- Y should not be the same as yy
  map("n", "Y", "y$", { desc = "Yank til end of line" })

  -- Search & replace in current file/line
  map("v", "<leader>rw", '"9y:%s@<c-r>9@<c-r>9@g<left><left>', { desc = "Search & replace selection", silent = false })
  map("n", "<leader>rw", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>', { desc = "Search & replace word", silent = false })
  map(
    "v",
    "<leader>rl",
    '"9y:s@<c-r>9@<c-r>9@g<left><left>',
    { desc = "Search & replace in current line", silent = false }
  )
  map(
    "n",
    "<leader>rl",
    'viw"9y:s@<c-r>9@<c-r>9@g<left><left>',
    { desc = "Search & replace word in current line", silent = false }
  )

  -- Follow cursor while searching
  map("n", "n", "nzz", { desc = "Next match and center" })
  map("n", "N", "Nzz", { desc = "Previous match and center" })
  map("n", "*", "*zz", { desc = "All matches and center" })

  -- Highlight matches with +
  map("n", "+", "*N", { desc = "Highlight all matches" })

  -- Use <c-g> to change ocurrences of a word/selection one by one
  map("n", "<c-g>", "*`'cgn", { desc = "Change next ocurrence" })
  map("v", "<c-g>", "y<cmd>let @/=escape(@\", '/')<cr>\"_cgn", { desc = "Change next ocurrence (visual)" })

  -- Block indentation (easier)
  map("n", ">", ">>", { desc = "Indent right" })
  map("n", "<", "<<", { desc = "Indent left" })
  map("v", ">", ">gv", { desc = "Indent selection right" })
  map("v", "<", "<gv", { desc = "Indent selection left" })

  -- Folds
  map("n", "<leader><", function()
    if not vim.opt.foldmethod then
      vim.opt.foldmethod = "indent"
    end
    vim.cmd("normal! zM")
  end, { desc = "Fold all" })

  map("n", "<leader>>", function()
    vim.opt.foldenable = false
    vim.cmd("normal! zR")
  end, { desc = "Open all folds" })

  map("n", "]q", ":cnext<cr>", { desc = "Next quickfix file" })
  map("n", "[q", ":cprev<cr>", { desc = "Previous quickfix file" })
end

local function setup_abbreviations()
  -- don't judge, English is hard
  vim.cmd([[
    iabbr ''' ``
    iabbr widht width
    iabbr heigth height
    iabbr lenght length
    iabbr ligth light
    iabbr rigth right
  ]])
end

local function setup_plugin_manager()
  local path_package = vim.fn.stdpath("data") .. "/site/"
  local mini_path = path_package .. "pack/deps/start/mini.nvim"
  if not vim.loop.fs_stat(mini_path) then
    vim.api.nvim_command('echo "Installing `mini.nvim`" | redraw')
    local clone_cmd = {
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/echasnovski/mini.nvim",
      mini_path,
    }
    vim.fn.system(clone_cmd)
    vim.api.nvim_command("packadd mini.nvim | helptags ALL")
    vim.api.nvim_command('echo "Installed `mini.nvim`" | redraw')
  end
  require("mini.deps").setup({ path = { package = path_package } })
  add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
end

local function oxocarbon()
  add("nyoom-engineering/oxocarbon.nvim")
  dark_theme = "oxocarbon"
  light_theme = "oxocarbon"
end

local function kanagawa()
  add("rebelot/kanagawa.nvim")
  dark_theme = "kanagawa"
  light_theme = "kanagawa"
end

local function gruvbox()
  add("ellisonleao/gruvbox.nvim")
  dark_theme = "gruvbox"
  light_theme = "gruvbox"
end

local function rose_pine()
  add("rose-pine/neovim")
  dark_theme = "rose-pine"
  light_theme = "rose-pine"
end

local function catppuccin()
  add({ source = "catppuccin/nvim", name = "catppuccin" })
  dark_theme = "catppuccin-macchiato"
  light_theme = "catppuccin"
end

local function color_utils()
  local function Light()
    vim.opt.background = "light"
    vim.cmd("colorscheme " .. light_theme)
  end
  local function Dark()
    vim.opt.background = "dark"
    vim.cmd("colorscheme " .. dark_theme)
  end
  vim.api.nvim_create_user_command("Light", Light, {})
  vim.api.nvim_create_user_command("Dark", Dark, {})
  add("f-person/auto-dark-mode.nvim")
  require("auto-dark-mode").setup({
    set_dark_mode = Dark,
    set_light_mode = Light,
    update_interval = 3000,
    fallback = "dark",
  })
end

local function fix_cursorline_color()
  -- vim.api.nvim_command [[
  --   hi! CursorLine guibg=#2e3440
  --   hi! link Visual CursorLine
  -- ]]
end

local function colors()
  vim.opt.background = "dark" -- by default
  -- rose_pine()
  -- gruvbox()
  catppuccin()
  vim.cmd("colorscheme " .. dark_theme)
  add("pablopunk/transparent.vim")
  fix_cursorline_color()
  color_utils()
end

local function snacks()
  add("folke/snacks.nvim")
  require("snacks").setup({
    styles = {},
    bigfile = { enabled = true }, -- don't load lsp and treesitter on big files
  })
end

local function unclutter()
  add("pablopunk/unclutter.nvim")
  require("unclutter").setup({ clean_after = 0, tabline = true })
  map("n", "<c-f>", function()
    require("unclutter.telescope").open({ hide_current = true })
  end, { desc = "Show unclutter buffers in Telescope" })
  map("n", "<c-n>", require("unclutter.tabline").next, { desc = "Next buffer (unclutter)" })
  map("n", "<c-p>", require("unclutter.tabline").prev, { desc = "Previous buffer (unclutter)" })
end

local function plenary()
  add("nvim-lua/plenary.nvim") -- necessary for lots of plugins
end

-- Load these plugins first
local function setup_priority_plugins()
  colors()
  unclutter()
  plenary()
end

local function plugins_that_could_be_default_behavior()
  add("pablopunk/persistent-undo.vim")
  add("stefandtw/quickfix-reflector.vim")
  add("christoomey/vim-tmux-navigator")
  add("markonm/traces.vim")
  add("tpope/vim-surround")
end

local function editor_utils()
  add("dstein64/vim-startuptime")
  add("wakatime/vim-wakatime")
end

local function which_key()
  add("folke/which-key.nvim")
  vim.o.timeout = true
  vim.o.timeoutlen = 300
  require("which-key").setup({})
end

local function telescope_pull_request_files()
  local builtin = require("telescope.builtin")

  local main_ancestor = vim.fn.systemlist("git merge-base origin/main HEAD")[1]
  if main_ancestor == nil then
    print("Could not determine the common ancestor with main branch.")
    return
  end

  builtin.git_files({
    prompt_title = "Pull Request files",
    git_command = { "git", "diff", "--name-only", main_ancestor },
  })
end

local function telescope()
  add("nvim-telescope/telescope.nvim")
  require("telescope").setup({
    defaults = {
      file_ignore_patterns = { ".git", "node_modules/", "vendor/" },
      path_display = { "truncate" },
      layout_strategy = "vertical",
      layout_config = {
        vertical = {
          preview_cutoff = 0,
        },
      },
      selection_caret = "◦ ",
      prompt_prefix = " → ",
      mappings = {
        i = {
          ["<c-k>"] = require("telescope.actions").cycle_history_prev,
          ["<c-j>"] = require("telescope.actions").cycle_history_next,
          ["<esc>"] = require("telescope.actions").close,
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      grep_string = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
    },
  })
  map("n", "<leader>ff", '<cmd>lua require("telescope.builtin").find_files()<cr>', { desc = "Find files" })
  map("n", "<leader>fs", '<cmd>lua require("telescope.builtin").live_grep()<cr>', { desc = "Live grep" })
  map({ "n", "v" }, "<leader>fw", '<cmd>lua require("telescope.builtin").grep_string()<cr>', { desc = "Grep word" })
  map("n", "<leader>fgg", ":Telescope git_status<cr>", { desc = "Find modified files (git)" })
  map("n", "<leader>fgh", telescope_pull_request_files, { desc = "Pull request files" })
  map("n", "<leader>fh", '<cmd>lua require("telescope.builtin").help_tags()<cr>', { desc = "Help tags" })
  map(
    "n",
    "<leader>fW",
    '<cmd>lua require("telescope.builtin").grep_string({ hidden = true })<cr>',
    { desc = "Grep Word" }
  )
  map(
    "n",
    "<leader>fr",
    '<cmd>lua require("telescope.builtin").oldfiles({ only_cwd = true })<cr>',
    { desc = "Old files" }
  )
  map("n", "<leader><leader>", ":Telescope keymaps<cr>", { desc = "Command palette (kinda)" })
end

local function supermaven()
  add("supermaven-inc/supermaven-nvim")
  require("supermaven-nvim").setup({ log_level = "off" })
  -- Trigger completion with <tab> manually since mini.completion doesn't play well with supermaven
  map("i", "<tab>", function()
    local suggestion = require("supermaven-nvim.completion_preview")
    if suggestion.has_suggestion() then
      suggestion.on_accept_suggestion()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<tab>", true, false, true), "n", true)
    end
  end, { desc = "Accept Supermaven suggestion" })
end

local function avante()
  add({
    source = "yetone/avante.nvim",
    depends = {
      "echasnovski/mini.icons",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
  })
  require("avante_lib").load() -- fixes bug https://github.com/yetone/avante.nvim/issues/665#issuecomment-2412440939
  -- ^ fix above requires building with
  --   cd $HOME/.local/share/nvim/site/pack/deps/opt/avante.nvim && make
  require("avante").setup({
    mappings = {
      ask = "<leader>cg",
    },
    hints = { enabled = true },
    provider = "openai",
    providers = {
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-5-mini",
        temperature = 1,
      },
    },
  })
end

local function codex()
  add("johnseth97/codex.nvim")
  require("codex").setup({
    keymaps = {}, -- disable internal mapping
    border = "rounded", -- or 'double'
    width = 0.8,
    height = 0.8,
    autoinstall = true,
  })
  map("n", "<leader>cg", "<cmd>CodexToggle<cr>", { desc = "Toggle codex popup" })
end

local function opencode()
  add("NickvanDyke/opencode.nvim")
  vim.g.opencode_opts = { -- Your configuration, if any — see `lua/opencode/config.lua`
  }

  -- Required for `opts.auto_reload`
  vim.opt.autoread = true

  -- Recommended keymaps
  map("n", "<leader>ot", function()
    require("opencode").toggle()
  end, { desc = "Toggle" })
  map("n", "<leader>oA", function()
    require("opencode").ask()
  end, { desc = "Ask" })
  map("n", "<leader>oa", function()
    require("opencode").ask("@cursor: ")
  end, { desc = "Ask about this" })
  map("v", "<leader>oa", function()
    require("opencode").ask("@selection: ")
  end, { desc = "Ask about selection" })
  map("n", "<leader>o+", function()
    require("opencode").append_prompt("@buffer")
  end, { desc = "Add buffer to prompt" })
  map("v", "<leader>o+", function()
    require("opencode").append_prompt("@selection")
  end, { desc = "Add selection to prompt" })
  map("n", "<leader>on", function()
    require("opencode").command("session_new")
  end, { desc = "New session" })
  map("n", "<leader>oy", function()
    require("opencode").command("messages_copy")
  end, { desc = "Copy last response" })
  map("n", "<S-C-u>", function()
    require("opencode").command("messages_half_page_up")
  end, { desc = "Messages half page up" })
  map("n", "<S-C-d>", function()
    require("opencode").command("messages_half_page_down")
  end, { desc = "Messages half page down" })
  map({ "n", "v" }, "<leader>os", function()
    require("opencode").select()
  end, { desc = "Select prompt" })
  map("n", "<leader>oe", function()
    require("opencode").prompt("Explain @cursor and its context")
  end, { desc = "Explain this code" })
end

local function ai()
  supermaven()
  -- codex()
  -- avante()
  opencode()
end

local function git_blame()
  add("FabijanZulj/blame.nvim")
  require("blame").setup()
  map({ "n", "v" }, "<leader>gb", "<cmd>BlameToggle<cr>", { desc = "Toggle git blame" })
end

local function openingh()
  add("almo7aya/openingh.nvim")
  require("openingh").setup()
  map({ "n", "v" }, "<leader>go", "<cmd>OpenInGHFile<cr>", { desc = "Open file in github" })
  map({ "n", "v" }, "<leader>gm", "<cmd>OpenInGHFile main<cr>", { desc = "Open file in github (main branch)" })
end

local function git_pr_review()
  local function select_and_review()
    local has_gh = tonumber(vim.fn.system("hash gh ; echo $?")) == 0
    if not has_gh then
      print("gh (github-cli) is required")
      return
    end
    local prs = vim.fn.systemlist("gh pr list --state open --limit 100")
    if #prs == 0 then
      print("No open pull requests found.")
      return
    end
    vim.ui.select(prs, {
      prompt = "Select a pull request to review",
    }, function(choice)
      print(choice)
      local pr_number = choice:match("%d+")
      local pr_diff = vim.fn.system("gh pr diff --patch " .. pr_number)
      vim.cmd("tabnew")
      vim.cmd("setlocal buftype=nofile")
      vim.cmd("setlocal filetype=diff")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(pr_diff, "\n"))
    end)
  end
  map("n", "<leader>gpr", select_and_review, { desc = "Select and review pull request" })
end

local function git_conflict()
  add("akinsho/git-conflict.nvim")
  ---@diagnostic disable-next-line: missing-fields
  require("git-conflict").setup({})
end

local function neogit()
  add("NeogitOrg/neogit")
  require("neogit").setup({})
  map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Open neogit" })
end

local function git()
  git_blame()
  openingh()
  git_conflict()
  neogit()
  git_pr_review()
end

local function restore_session()
  vim.cmd("silent! SessionRestore") -- restore session form auto-session
  require("unclutter.tabline").keep_all_buffers()
end

local function auto_session()
  add("rmagatti/auto-session")
  require("auto-session").setup({
    log_level = "error",
    auto_session_suppress_dirs = { "/", "~/", "~/src", "~/Downloads", "~/Desktop" },
    auto_session_use_git_branch = true,
    bypass_session_save_file_types = { "NvimTree", "Lazy", "Starter" },
  })
  map("n", "<leader>sd", function()
    vim.cmd("silent! SessionDelete") -- delete session
    vim.cmd("silent! %bd") -- close all buffers
  end, { desc = "Delete session" })
  map("n", "<leader>sr", restore_session, { desc = "Restore session" })
end

local function mini_nvim()
  add("echasnovski/mini.nvim")
  require("mini.icons").setup({})
  ---@diagnostic disable-next-line: undefined-global
  MiniIcons.mock_nvim_web_devicons()
  require("mini.completion").setup({})
  require("mini.comment").setup({})
  require("mini.indentscope").setup({ symbol = "│" })
  vim.cmd("hi! link MiniIndentscopeSymbol Whitespace")
  require("mini.cursorword").setup({})
  require("mini.ai").setup({})
  vim.api.nvim_command("hi! link MiniCursorWord CursorLine")
  vim.api.nvim_command("hi! link MiniCursorWordCurrent CursorLine")
  require("mini.pick").setup({
    mappings = {
      to_quickfix = {
        char = "<c-q>",
        func = function()
          local items = MiniPick.get_picker_items() or {}
          MiniPick.default_choose_marked(items)
          MiniPick.stop()
        end,
      },
    },
  })
  vim.ui.select = MiniPick.ui_select
  -- map("n", "<leader>ff", MiniPick.builtin.files, { desc = "Fuzzy file finder" })
  -- map("n", "<leader>fs", MiniPick.builtin.grep_live, { desc = "Fuzzy string search" })
  require("mini.diff").setup({
    mappings = {
      apply = "gh",
      reset = "gH",
      textobject = "gh",
      goto_first = "[G",
      goto_prev = "[g",
      goto_next = "]g",
      goto_last = "]G",
    },
  })
  require("mini.splitjoin").setup({})
  require("mini.files").setup({
    mappings = {
      go_in_plus = "<cr>",
      synchronize = "<c-s>",
    },
    windows = {
      preview = true,
      width_preview = 60,
    },
  })
  map("n", "<leader>gd", function()
    require("mini.diff").toggle_overlay(vim.api.nvim_get_current_buf())
  end, { desc = "Toggle overlay diff in the whole file" })
  map("n", "<leader>gr", function()
    vim.cmd("normal gHgh")
  end, { desc = "Reset hunk" })
  map("v", "<leader>gr", function()
    vim.cmd("normal gH")
  end, { desc = "Reset visual selection" })
  map("n", "<leader>gs", function()
    vim.cmd("normal ghgh")
  end, { desc = "Stage hunk" })
  map("v", "<leader>gs", function()
    vim.cmd("normal gh")
  end, { desc = "Stage visual selection" })
  map({ "n", "v" }, "<c-t>", function()
    local MiniFiles = require("mini.files")
    if not MiniFiles.close() then
      local is_buffer_a_file = (vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "")
      if is_buffer_a_file then
        MiniFiles.open(vim.api.nvim_buf_get_name(0))
      else
        MiniFiles.open()
      end
    end
  end, { desc = "Toggle file explorer" })
end

local function treesitter_context()
  add("nvim-treesitter/nvim-treesitter-context")
  require("treesitter-context").setup({
    max_lines = 3,
  })
  map("n", "<leader>lc", "<cmd>TSContextToggle<cr>", { desc = "Toggle tresitter context" })
end

local function treesitter()
  add("nvim-treesitter/nvim-treesitter")
  ---@diagnostic disable-next-line: missing-fields
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        node_decremental = "<bs>",
        scope_incremental = false,
      },
    },
  })
  treesitter_context()
end

local function lsp()
  -- vim.lsp.inlay_hint.enable() -- enable inlay hints
  add("neovim/nvim-lspconfig")
  add("folke/neodev.nvim")
  add("williamboman/mason.nvim")
  add("williamboman/mason-lspconfig.nvim")

  local function mini_completion_on_attach(client, bufnr)
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.MiniCompletion.completefunc_lsp")
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  require("neodev").setup({})
  require("mason").setup({})
  require("mason-lspconfig").setup({
    ensure_installed = {
      "bashls",
      "jsonls",
      "html",
      "vimls",
      "lua_ls",
      "astro",
      "biome",
      "eslint",
      "vtsls",
      "gopls",
      -- "zls", --for zig
    },
  })

  map("n", "E", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
  map("n", "]d", function()
    vim.diagnostic.goto_next()
    vim.cmd("normal! zz")
  end, { desc = "Go to next diagnostic" })
  map("n", "[d", function()
    vim.diagnostic.goto_prev()
    vim.cmd("normal! zz")
  end, { desc = "Go to previous diagnostic" })
  map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Show code actions" })
  map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
  map("n", "gd", ":Telescope lsp_definitions<cr>zz", { desc = "Go to definition" })
  map("n", "gr", ":Telescope lsp_references<cr>", { desc = "Go to references" })
  map("n", "gi", ":Telescope lsp_implementations<cr>", { desc = "Go to implementations" })
  map("n", "<leader>lo", ":Telescope lsp_document_symbols<cr>", { desc = "Document symbols" })
  map("n", "<leader>lO", ":Telescope lsp_workspace_symbols<cr>", { desc = "Workspace symbols (dynamic)" })
  map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename variable" })
  map("n", "<leader>ls", ":LspStart<cr>", { desc = "Start LSP" })
  map("n", "<leader>lx", ":LspStop<cr>", { desc = "Stop LSP" })
  map("n", "<leader>lr", ":LspRestart<cr>", { desc = "Restart LSP" })
  map("n", "<leader>li", ":LspInfo<cr>", { desc = "Info LSP" })
  map("n", "<leader>lh", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
  end, { desc = "Toggle inlay hints (LSP)" })

  local lspconfig = require("lspconfig") -- TODO: deprecated, use vim.lsp.config
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local on_attach = function(client, bufnr)
    mini_completion_on_attach(client, bufnr)
  end

  local function setup_lsp(lsp_name, settings)
    lspconfig[lsp_name].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = settings,
    })
  end

  setup_lsp("vtsls")
  setup_lsp("vimls")
  setup_lsp("bashls")
  setup_lsp("jsonls")
  setup_lsp("html")
  setup_lsp("astro")
  setup_lsp("biome")
  setup_lsp("eslint")
  setup_lsp("gopls")
  setup_lsp("lua_ls", {
    Lua = {
      diagnostics = { globals = { "vim" } },
      hint = { enable = true },
      workspace = {
        checkThirdParty = false,
      },
    },
  })
  -- create a command that installs and configs a new lsp server
  vim.api.nvim_create_user_command("LspConfig", function(opts)
    local server_name = opts.args
    vim.cmd("MasonInstall " .. opts.args)
    setup_lsp(server_name)
    vim.cmd("LspStart " .. server_name)
  end, { nargs = 1 })
end

local function trouble()
  add("folke/trouble.nvim")
  require("trouble").setup({})
  map("n", "<leader>d", ":Trouble diagnostics toggle<cr>", { desc = "Toggle trouble diagnostics" })
end

local function conform()
  add("stevearc/conform.nvim")
  local function setup_conform(js_formatters)
    require("conform").setup({
      format_after_save = {
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" }, -- brew install stylua
        javascript = js_formatters,
        typescript = js_formatters,
        typescriptreact = js_formatters,
        javascriptreact = js_formatters,
        astro = js_formatters,
        go = { "gofmt" },
      },
    })
  end
  local function use_biome()
    setup_conform({ "biome" })
    vim.cmd("LspRestart")
  end
  local function use_eslint()
    setup_conform({ "eslint_d" })
    vim.cmd("LspRestart")
  end
  local function use_none()
    setup_conform({})
    vim.cmd("LspRestart")
  end
  vim.api.nvim_create_user_command("BiomeFormat", use_biome, {})
  vim.api.nvim_create_user_command("EslintFormat", use_eslint, {})
  vim.api.nvim_create_user_command("NoFormat", use_none, {})
  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  if project == "maze-mobile-app" then -- use eslint for the mobile app
    setup_conform({ "eslint_d" })
  else -- default formatter for everything else
    setup_conform({ "biome" })
  end
end

local function notify()
  add("rcarriga/nvim-notify")
  ---@diagnostic disable-next-line: missing-fields
  require("notify").setup({
    stages = "no_animation",
    render = "compact",
    timeout = 2000,
  })
  vim.notify = require("notify") -- make it available to other plugins
  map("n", "<leader>fn", ":Telescope notify<cr>", { desc = "Filter messages/errors (nvim-notify)" })
  map("n", "<leader>h", function()
    ---@diagnostic disable-next-line: missing-parameter
    require("notify").dismiss()
    vim.cmd("noh")
  end, { desc = "Dismiss notification (nvim-notify)" })
end

local function noice()
  notify()
  add({
    source = "folke/noice.nvim",
    depends = {
      "MunifTanjim/nui.nvim",
    },
  })
  require("noice").setup({
    lsp = { progress = { enabled = false } },
    notify = { enabled = true, view = "notify" },
    messages = { enabled = true, view = "notify" },
    cmdline = { view = "cmdline_popup" },
  })
end

local function markdown()
  add("OXY2DEV/markview.nvim")
  require("markview").setup({
    preview = {
      filetypes = { "markdown", "norg", "rmd", "org", "vimwiki", "Avante" },
      buf_ignore = {},
    },
    max_length = 99999,
    code_blocks = {
      style = "simple", -- Makes it easier to read when wrap is enabled in buffer
    },
  })
end

local function vscode()
  if vim.g.vscode then
    -- otherwise vscode would be opening the bottom drawer all the time
    -- with the message "3 more lines" or whatever
    vim.opt.cmdheight = 4
    return true
  end
  return false
end

local function highlight_colors()
  add("brenoprata10/nvim-highlight-colors")
  require("nvim-highlight-colors").setup({})
end

-- Lazy load plugins
local function setup_plugins()
  plugins_that_could_be_default_behavior()
  mini_nvim()
  if not vscode() then
    plugins_that_could_be_default_behavior()
    mini_nvim()
    noice()
    telescope()
    git()
    editor_utils()
    which_key()
    ai()
    auto_session()
    treesitter()
    lsp()
    trouble()
    conform()
    highlight_colors()
    markdown()
    snacks()
  end
end

setup_plugin_manager()

now(function()
  setup_options()
  setup_priority_plugins()
end)

later(function()
  setup_mappings()
  setup_abbreviations()
  setup_plugins()
end)
