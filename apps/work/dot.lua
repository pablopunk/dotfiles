return {
  os = { "macos" },
  check = "which aws-vault && [ -d '/Applications/Warp.app' ] && [ -d '/Applications/MonitorControl.app' ] && which orb && [ -d '/Applications/Slack.app' ] && [ -d '/Applications/zoom.us.app' ] && [ -d '/Applications/CleanShot X.app' ]",
  install = {
    brew = "brew install aws-vault cloudflare-warp monitorcontrol orbstack slack zoom cleanshot",
  },
}
