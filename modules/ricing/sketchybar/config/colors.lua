return {
  black = 0xff181819,
  white = 0xffe2e2e3,
  red = 0xfffcbddc,
  green = 0xff9ed0d0,
  blue = 0xff70f0f0,
  yellow = 0xffe7c664,
  orange = 0xfff3c6c0,
  magenta = 0xffb39df3,
  grey = 0x3f414550,
  transparent = 0x00000000,

  bar = {
    bg = 0xf02c2e34,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xc02c2e34,
    border = 0xff7f8490,
  },

  bg = 0x9f414550,
  fg = 0xffffffff,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then
      return color
    end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
