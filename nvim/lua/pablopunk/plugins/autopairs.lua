local autopairs_setup, autopairs = pcall(require, "nvim-autopairs")
if not autopairs_setup then
  return
end

autopairs.setup {
  check_ts = true, -- enable treesitter
  ts_config = {
    lua = { "string" }, -- dont add pairs in lua string treesitter nodes
    javascript = { "template_string" }, -- dont add pairs in js template_string
    java = false, -- dont check treesitter in java
  },
}

-- make autopairs and autocompletion work together
local cmp_autopairs = require "nvim-autopairs.completion.cmp"
local cmp = require "cmp"
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
