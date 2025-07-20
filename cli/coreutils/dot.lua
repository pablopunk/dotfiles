return {
  os = { "macos" },
  check = "which gdate",
  install = {
    brew = "brew install coreutils",
  },
}
