#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
  Darwin)
    sudo launchctl bootout system/dev.kanata 2>/dev/null || true
    sudo launchctl bootout system/dev.kanata.driver 2>/dev/null || true
    sudo rm -f /Library/LaunchDaemons/dev.kanata.plist /Library/LaunchDaemons/dev.kanata.driver.plist
    ;;
  Linux)
    sudo systemctl disable --now kanata.service
    sudo rm -f /etc/systemd/system/kanata.service /etc/modules-load.d/kanata.conf
    sudo systemctl daemon-reload
    ;;
esac
