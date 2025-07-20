return {
  check = "[ -d '/Applications/Mos.app' ]",
  install = {
    brew = "brew install mos",
  },
  defaults = {
    ["com.caldis.Mos"] = "./defaults/Mos.xml",
  },
}
