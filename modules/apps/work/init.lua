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
      plist = "./defaults/Mos.plist",
      app = "com.caldis.Mos",
    },
    {
      plist = "./defaults/CleanShotX.plist",
      app = "pl.maketheweb.cleanshotx",
    },
  },
}
