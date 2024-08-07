#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then

  # Finder
  defaults write com.apple.finder ShowPathbar -bool yes
  defaults write com.apple.finder ShowStatusBar -bool true
  # killall Finder

  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-time-modifier -float 0.3
  defaults write com.apple.dock show-process-indicators -bool true
  defaults write com.apple.dock tilesize -int 40
  defaults write com.apple.dock orientation -string right
  defaults write com.apple.dock magnification -bool true
  defaults write com.apple.dock largesize -float 52
  # killall Dock

  defaults write com.apple.AppleMultitouchTrackpad HIDScrollZoomModifierMask -int 262144
  # sudo defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool yes
  # sudo defaults write com.apple.universalaccess closeViewSplitScreenRatio -float 0.2
  # sudo defaults write com.apple.universalaccess closeViewZoomFactorBeforeTermination -bool yes

  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.AppleMultitouchTrackpad Dragging -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool true
fi
