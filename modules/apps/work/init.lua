return {
  brew = {
    "aws-vault",
    "cloudflare-warp",
    "monitorcontrol",
    "mos",
    "orbstack",
    "slack",
    "zoom",
  },
  defaults = {
    {
      plist = "./defaults/Mos.plist",
      app = "com.caldis.Mos",
    },
  },
}
