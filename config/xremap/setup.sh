#!/usr/bin/env bash
set -euo pipefail

rule='KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"'
rule_path=/etc/udev/rules.d/99-xremap.rules
module_path=/etc/modules-load.d/xremap.conf

if [[ "${1:-}" == "--permissions" ]]; then
  user="$2"
  usermod -aG input "$user"
  printf '%s\n' "$rule" > "$rule_path"
  printf '%s\n' uinput > "$module_path"
  modprobe uinput
  udevadm control --reload-rules
  udevadm trigger --subsystem-match=misc --sysname-match=uinput
  exit 0
fi

user=$(id -un)
if ! getent group input | grep -Eq "(^|[:,])${user}(,|$)" || \
   ! [[ -f "$rule_path" ]] || ! grep -Fxq "$rule" "$rule_path" || \
   ! [[ -f "$module_path" ]] || ! grep -Fxq uinput "$module_path" || \
   ! [[ -c /dev/uinput ]]; then
  pkexec bash "$0" --permissions "$user"
fi

systemctl --user daemon-reload
systemctl --user enable xremap.service

# A user manager inherited from an older login cannot gain new groups.
manager_pid=$(systemctl show "user@$(id -u).service" --property=MainPID --value)
input_gid=$(getent group input | cut -d: -f3)
if [[ "$manager_pid" =~ ^[1-9][0-9]*$ ]] && \
   awk -v gid="$input_gid" '$1 == "Groups:" { for (i = 2; i <= NF; i++) if ($i == gid) found = 1 } END { exit !found }' "/proc/$manager_pid/status"; then
  systemctl --user reset-failed xremap.service
  systemctl --user start xremap.service
else
  printf '%s\n' 'xremap enabled. Fully log out of all sessions or reboot to apply input group membership.'
fi
