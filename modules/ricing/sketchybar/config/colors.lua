return {
  black = 0xff161d1e,
  white = 0xffd6ddde,
  red = 0xffefb9d7,
  green = 0xff96cccc,
  blue = 0xff6aeaea,
  yellow = 0xffdbc265,
  orange = 0xffe6c2bc,
  magenta = 0xffaa9bed,
  grey = 0x3f3d4752,
  transparent = 0x00000000,

  bar = {
    bg = 0xf0293237,
    border = 0xff293237,
  },

  popup = {
    bg = 0xc0293237,
    border = 0xff78838f,
  },

  bg = 0x9f3d4752,
  fg = 0xfff2f8f8,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then
      return color
    end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
