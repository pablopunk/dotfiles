return function(dark_theme, light_theme)
  return {
       update_interval = 1000,
        set_dark_mode = function()
          vim.opt.background = "dark"
          vim.cmd("colorscheme " .. dark_theme)
        end,
        set_light_mode = function()
          if vim.fn.has "mac" == 0 then
            return -- Don't change colors on linux
          end
          vim.opt.background = "light"
          vim.cmd("colorscheme " .. light_theme)
        end,
    }
end
