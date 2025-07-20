return {
  os = "darwin",
  check = "[ -d '/Applications/WhatsApp.app' ]",
  install = {
    brew = "brew install whatsapp",
  },
}
