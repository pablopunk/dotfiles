local M = {}

M.map = function(mode, key, action, desc)
  vim.keymap.set(mode, key, action, { noremap = true, silent = true, desc = desc or "" })
end
M.verbose_map = function(mode, key, action, desc)
  vim.keymap.set(mode, key, action, { noremap = true, silent = false, desc = desc or "" })
end

M.quit_file = function()
  local irrelevant_buffers = { "NvimTree", "Starter", "Neogit", "quickfix", "", "*" }
  local name_of_buffer = vim.fn.expand "%"
  local buffer_is_irrelevant = vim.tbl_contains(irrelevant_buffers, name_of_buffer)
  local number_of_buffers = #(vim.fn.getbufinfo { buflisted = 1 })
  local number_of_tabs = #(vim.fn.gettabinfo())
  local is_last_buffer = number_of_buffers == 1 and number_of_tabs == 1
  local is_last_unclutter_tab = #require("unclutter.tabline").list() == 1
  if is_last_buffer or is_last_unclutter_tab then
    vim.cmd "silent! SessionDelete"
    vim.cmd "qa"
  elseif buffer_is_irrelevant then
    vim.cmd "bd!"
  else
    vim.cmd "bd"
  end
end

M.close_all_buffers = function()
  vim.cmd "silent! %bd"
  local ok, starter = pcall(require, "mini.starter")
  if ok then
    starter.open()
  end
end

M.maximize_floating_window = function()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative == "" then
    -- not a floating window
    return
  end
  local width = vim.api.nvim_get_option "columns" - 10
  local height = vim.api.nvim_get_option "lines" - 10
  local new_width, new_height, new_row, new_col = width, height, 5, 5
  vim.api.nvim_win_set_config(win, {
    relative = "editor",
    width = new_width,
    height = new_height,
    row = new_row,
    col = new_col,
  })
end

M.remove_highlights = function()
  vim.cmd "silent! nohlsearch"
end

M.fold_all = function()
  vim.opt.foldmethod = "indent"
  vim.cmd "normal! zM"
end

M.unfold_all = function()
  vim.cmd "set nofoldenable"
  vim.cmd "normal! zR"
end

M.open_starter = function()
  local ok, starter = pcall(require, "mini.starter")
  if ok then
    starter.open()
  end
end

M.toggle_explorer = function()
  local ok, MiniFiles = pcall(require, "mini.files")
  if ok then
    if not MiniFiles.close() then
      local is_buffer_a_file = (vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "")
      if is_buffer_a_file then
        MiniFiles.open(vim.api.nvim_buf_get_name(0))
      else
        MiniFiles.open()
      end
    end
  end
end

--- Create a statusline separator
--- @param before_hl string
--- @param after_hl string
--- @param char string
--- @return string
M.create_statusline_separator = function(before_hl, after_hl, char)
  local hl_name = string.format("Statusline%s%s", before_hl, after_hl)

  if vim.api.nvim_get_hl(0, { name = hl_name }).bg == nil then
    vim.cmd(
      string.format(
        [[ hi! %s guifg=%s guibg=%s ]],
        hl_name,
        string.format("#%06x", vim.api.nvim_get_hl(0, { name = before_hl }).bg),
        string.format("#%06x", vim.api.nvim_get_hl(0, { name = after_hl }).bg)
      )
    )
  end

  return "%#" .. hl_name .. "#" .. char
end

M.get_lsp_clients_string = function()
  local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients -- get_clients will be the next fn
  local clients = {}
  for _, client in ipairs(get_clients()) do
    local short_name = client.name:sub(1, 3)
    if not vim.tbl_contains(clients, short_name) then
      table.insert(clients, client.name:sub(1, 3)) -- 3 first letters
    end
  end
  local clients_string = table.concat(clients, "/")

  if #clients_string == 0 then
    return ""
  end

  return string.format("↯ %s ", clients_string)
end

M.get_filename_compact = function()
  local filename = vim.fn.expand "%:p"
  local path_segments = vim.split(filename, "/")
  if #path_segments > 1 then
    filename = path_segments[#path_segments - 1] .. "/" .. path_segments[#path_segments]
  else
    filename = path_segments[#path_segments]
  end
  return filename
end

M.hi = function(highlight_group)
  return function(text)
    return "%#" .. highlight_group .. "#" .. text .. "%*"
  end
end

M.dark = function()
  vim.opt.background = "dark"
  -- vim.cmd "colorscheme tokyonight-night"
  vim.cmd "colorscheme catppuccin-macchiato"
end

M.light = function()
  vim.opt.background = "light"
  -- vim.cmd "colorscheme tokyonight-day"
  vim.cmd "colorscheme catppuccin-latte"
end

M.auto_theme = function()
  if vim.fn.has "mac" == 0 then
    return -- Don't change colors on linux
  end

  local theme_file_lines = vim.fn.readfile(vim.fn.expand "~/.theme")
  if theme_file_lines and #theme_file_lines == 1 then
    local theme = theme_file_lines[1]
    if theme == "Light" then
      M.light()
      return
    elseif theme == "Dark" then
      M.dark()
      return
    end
  end
end

M.treesitter_langs = {
  "json",
  "javascript",
  "typescript",
  "tsx",
  "yaml",
  "html",
  "css",
  "markdown",
  "markdown_inline",
  "graphql",
  "bash",
  "lua",
  "vim",
  "vimdoc",
  "gitignore",
}

M.install_treesitter_langs = function()
  for _, lang in ipairs(M.treesitter_langs) do
    vim.cmd("TSInstall! " .. lang)
  end
end

return M
