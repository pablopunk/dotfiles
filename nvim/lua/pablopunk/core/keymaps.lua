vim.g.mapleader = " " -- space

local keymap = vim.keymap

-- ^c is ESC
keymap.set("n", "<c-c>", "<esc>")
keymap.set("v", "<c-c>", "<esc>")
keymap.set("i", "<c-c>", "<esc>")
keymap.set("i", "<c-c>", "<esc>")

-- c-hjlk to move through windows
-- keymap.set("n", "<c-h>", "<c-w>h")
-- keymap.set("n", "<c-j>", "<c-w>j")
-- keymap.set("n", "<c-k>", "<c-w>k")
-- keymap.set("n", "<c-l>", "<c-w>l")

-- remove highlights
keymap.set("n", "<leader>h", ":nohl<cr>")
keymap.set("n", "<leader>h", ":nohl<cr>")

-- quit/save file
keymap.set("n", "<c-q>", ":bd<cr>")
keymap.set("n", "<c-s>", ":w!<cr>")

-- system clipboard
keymap.set("n", "<leader>cp", '"*y')
keymap.set("v", "<leader>cp", '"*y')

-- Y should not be the same as yy
keymap.set("n", "Y", "y$")

-- buffer navigation
keymap.set("n", "gp", ":bprev<cr>")
keymap.set("n", "gn", ":bnext<cr>")

-- search & replace in current file/line
keymap.set("v", "<c-n>", '"9y:%s@<c-r>9@<c-r>9@g<left><left>')
keymap.set("n", "<c-n>", 'viw"9y:%s@<c-r>9@<c-r>9@g<left><left>')
keymap.set("v", "<leader>n", '"9y:s@<c-r>9@<c-r>9@g<left><left>')
keymap.set("n", "<leader>n", 'viw"9y:s@<c-r>9@<c-r>9@g<left><left>')

-- follow (center) search cursor
keymap.set("n", "n", "nzz")
keymap.set("n", "N", "Nzz")
keymap.set("n", "*", "*zz")

-- + will highlight all matches
keymap.set("n", "+", "*N")

-- easier block indentation
keymap.set("n", ">", ">>")
keymap.set("n", "<", "<<")
keymap.set("v", ">", ">gv")
keymap.set("v", "<", "<gv")

-- folding
keymap.set("n", "<leader><", "zM") -- fold all
keymap.set("n", "<leader>>", "zR") -- open all
-- keymap.set("n", "H", "za") -- toggle fold under cursor (depends on fold_method)
keymap.set("n", "H", "zc") -- close fold under cursor
keymap.set("n", "L", "zo") -- open fold under cursor

-- project-based todo list OMG MAKE THIS A PLUGIN
local function get_todo_folder()
  local function get_closest_git_folder(path)
    if path == nil or path == "/" then
      return "~/"
    end
    local git_path = path .. "/.git"
    local f = io.open(git_path, "r")
    if f ~= nil then
      io.close(f)
      return path .. "/.git"
    end
    return get_closest_git_folder(vim.fn.fnamemodify(path, ":h"))
  end
  return get_closest_git_folder(vim.fn.expand "%:p:h")
end
keymap.set("n", "<leader>t", ":e " .. get_todo_folder() .. "/TODO.md<cr>") -- closes repo/.git/TODO.md or ~/TODO.md
