return {
  brew = {
    "aws-vault",
    "cloudflare-warp",
    "mise",
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
