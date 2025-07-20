return {
  os = { "macos" },
  check = "[ -d '/Applications/Notion Calendar.app' ]",
  install = {
    notion = "notion-calendar", -- RIP cron
  },
}
