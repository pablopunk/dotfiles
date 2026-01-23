# vim:fileencoding=utf-8:ft=zsh
# Java/Android development paths (conditional - only loaded if needed)

# Android SDK paths
if [[ -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
  path+=(
    $ANDROID_HOME/emulator
    $ANDROID_HOME/tools
    $ANDROID_HOME/tools/bin
    $ANDROID_HOME/platform-tools
  )
fi

# OpenJDK
if [[ -d /opt/homebrew/opt/openjdk ]]; then
  path=(/opt/homebrew/opt/openjdk/bin $path)
fi
