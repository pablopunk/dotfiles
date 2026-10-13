#!/usr/bin/env bash
set -euo pipefail

binary=$(command -v kanata)
config_directory="${2:-$HOME/.config/kanata}"
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT

xml_escape() {
  local value="$1"
  value=${value//&/\&amp;}
  value=${value//</\&lt;}
  value=${value//>/\&gt;}
  printf '%s' "$value"
}

install_macos_service() {
  local plist="$temporary_directory/dev.kanata.plist"
  install_macos_driver_service "${1:-}"
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
    '<plist version="1.0"><dict>' \
    '<key>Label</key><string>dev.kanata</string>' \
    '<key>ProgramArguments</key><array><string>/bin/bash</string>' \
    "<string>$(xml_escape "$config_directory/start.sh")</string>" \
    "<string>$(xml_escape "$binary")</string>" \
    "<string>$(xml_escape "$config_directory")</string></array>" \
    '<key>RunAtLoad</key><true/>' \
    '<key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>' \
    '<key>ThrottleInterval</key><integer>10</integer>' \
    '<key>StandardOutPath</key><string>/var/log/kanata.log</string>' \
    '<key>StandardErrorPath</key><string>/var/log/kanata.log</string>' \
    '</dict></plist>' > "$plist"
  plutil -lint "$plist"
  [[ "${1:-}" != "--check" ]] || return 0
  sudo install -o root -g wheel -m 644 "$plist" /Library/LaunchDaemons/dev.kanata.plist
  sudo launchctl bootout system/dev.kanata 2>/dev/null || true
  sudo launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.plist
}

install_macos_driver_service() {
  local driver="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
  local plist="$temporary_directory/dev.kanata.driver.plist"
  [[ -x "$driver" ]] || {
    printf '%s\n' 'Install the standalone Karabiner VirtualHIDDevice driver before running setup.' >&2
    return 1
  }
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
    '<plist version="1.0"><dict>' \
    '<key>Label</key><string>dev.kanata.driver</string>' \
    "<key>ProgramArguments</key><array><string>$(xml_escape "$driver")</string></array>" \
    '<key>RunAtLoad</key><true/>' '<key>KeepAlive</key><true/>' \
    '<key>ThrottleInterval</key><integer>10</integer>' \
    '</dict></plist>' > "$plist"
  plutil -lint "$plist"
  [[ "${1:-}" != "--check" ]] || return 0
  sudo install -o root -g wheel -m 644 "$plist" /Library/LaunchDaemons/dev.kanata.driver.plist
  sudo launchctl bootout system/dev.kanata.driver 2>/dev/null || true
  if ! launchctl print system/org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon >/dev/null 2>&1; then
    sudo launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.driver.plist
  fi
}

install_linux_service() {
  local unit="$temporary_directory/kanata.service"
  printf '%s\n' '[Unit]' 'Description=Kanata keyboard remapper' \
    'After=systemd-udevd.service' '' '[Service]' 'Type=simple' \
    "ExecStart=/bin/bash \"$config_directory/start.sh\" \"$binary\" \"$config_directory\"" \
    'Restart=on-failure' 'RestartSec=3' '' '[Install]' \
    'WantedBy=multi-user.target' > "$unit"
  if [[ "${1:-}" == "--check" ]]; then
    systemd-analyze verify "$unit"
    return
  fi
  sudo install -o root -g root -m 644 "$unit" /etc/systemd/system/kanata.service
  sudo modprobe uinput
  printf '%s\n' uinput > "$temporary_directory/kanata.conf"
  sudo install -o root -g root -m 644 "$temporary_directory/kanata.conf" /etc/modules-load.d/kanata.conf
  sudo systemctl daemon-reload
  sudo systemctl enable --now kanata.service
  sudo systemctl restart kanata.service
}

kanata --check --cfg "$config_directory/kanata.kbd"
case "$(uname -s)" in
  Darwin) install_macos_service "${1:-}" ;;
  Linux) install_linux_service "${1:-}" ;;
esac
