module.exports = {
  config: {
    opacity: 0.85,
    theme: "dark",
    updateChannel: "canary",
    fontSize: 18,
    fontFamily:
      '"Cascadia Code", "FuraCode Nerd Font", Hack, "Fira code", Menlo, "DejaVu Sans Mono", Consolas, "Lucida Console", monospace',
    fontWeight: "normal",
    fontWeightBold: "bold",
    lineHeight: 1,
    letterSpacing: 0,

    cursorColor: "yellow",
    cursorAccentColor: "#000",
    cursorShape: "UNDERLINE",
    cursorBlink: true,

    foregroundColor: "white",
    backgroundColor: "rgba(0,0,0,0.75)",
    borderColor: "#212121",

    css: "",
    termCSS: "",

    showHamburgerMenu: "",
    showWindowControls: "",

    padding: "12px 14px",
    colors: {
      black: "black",
      red: "tomato",
      green: "lightgreen",
      yellow: "gold",
      blue: "royalblue",
      magenta: "fuchsia",
      cyan: "aquamarine",
      white: "white",
      lightBlack: "black",
      lightRed: "tomato",
      lightGreen: "lightgreen",
      lightYellow: "gold",
      lightBlue: "royalblue",
      lightMagenta: "fuchsia",
      lightCyan: "aquamarine",
      lightWhite: "white",
    },

    // Bash on Windows
    // - Example: `C:\\Windows\\System32\\bash.exe`
    shell: "",
    shellArgs: ["--login"],

    // for environment variables
    env: {},

    // set to `false` for no bell
    bell: "SOUND",

    // if `true` (without backticks and without quotes), selected text will automatically be copied to the clipboard
    copyOnSelect: false,

    // if `true` (without backticks and without quotes), hyper will be set as the default protocol client for SSH
    defaultSSHApp: true,

    // if `true` (without backticks and without quotes), on right click selected text will be copied or pasted if no
    // selection is present (`true` by default on Windows and disables the context menu feature)
    quickEdit: false,

    // choose either `'vertical'`, if you want the column mode when Option key is hold during selection (Default)
    // or `'force'`, if you want to force selection regardless of whether the terminal is in mouse events mode
    // (inside tmux or vim with mouse mode enabled for example).
    macOptionSelectionMode: "force",

    bellSoundURL:
      "https://freesound.org/data/previews/448/448081_9159316-lq.mp3",

    webGLRenderer: false,
  },

  plugins: ["hyperlinks", "hyper-mac", "hyper-sick"],

  // `~/.hyper_plugins/local/`
  localPlugins: [],

  keymaps: {
    // Example
    // 'window:devtools': 'cmd+alt+o',
  },
};
