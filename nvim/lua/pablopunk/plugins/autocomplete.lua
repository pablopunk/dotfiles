return {
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.cmd [[
        let g:copilot_filetypes = {
          \ 'yaml': v:true,
          \ '*': v:true,
          \ }
      ]]
    end,
  },
}
