return {
  brew = {
    "aws-vault",
    "cloudflare-warp",
    "monitorcontrol",
    "mos",
    "orbstack",
    "slack",
    "zoom",
    "cleanshot",
  },
  defaults = {
    {
      plist = "./defaults/Mos.xml",
      app = "com.caldis.Mos",
    },
  },
}
