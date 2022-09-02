#!/bin/bash

# 🚨 Raycast doesn't have access to your normal path so you should add yours here (needed for node and pbcopy)
PATH="/Users/pablopunk/Library/pnpm:/Users/pablopunk/.bun/bin:/Users/pablopunk/.cargo/bin:/Users/pablopunk/.nvm/versions/node/v14.18.3/bin:/Applications/MacVim.app/Contents/bin:/Applications/Sublime Text.app/Contents/SharedSupport/bin:/Users/pablopunk/.deno/bin:/Users/pablopunk/.bin:/Users/pablopunk/.local/bin:/home/linuxbrew/.linuxbrew/bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/lib/ruby/gems/2.6.0/bin:/usr/local/opt/ruby/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Library/Apple/usr/bin:/Users/pablopunk/.cargo/bin:/Applications/kitty.app/Contents/MacOS"

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Linear PR
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Placeholder" }

# Documentation:
# @raycast.author Henry Black
# @raycast.authorURL https://twitter.com/hajblack

result=$(node "./create-pr-description" "$1")

echo "$result" | pbcopy
