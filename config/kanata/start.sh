#!/usr/bin/env bash
set -euo pipefail

binary="$1"
config_directory="$2"
runtime_config=$(mktemp "${TMPDIR:-/tmp}/kanata.XXXXXX")
trap 'rm -f "$runtime_config"' EXIT

write_non_zsa_device_allowlist() {
  case "$(uname -s)" in
    Darwin)
      printf 'macos-dev-names-include (\n'
      "$binary" --list | awk '$1 ~ /^0x/ && $2 != 12951 && $0 !~ /VirtualHIDKeyboard/ { printf "\"%s\"\n", $1; found=1 } END { if (!found) exit 1 }'
      printf ')\n'
      ;;
    Linux)
      local found=0
      printf 'linux-dev-names-include (\n'
      for device in /sys/class/input/event*/device; do
        [[ -r "$device/id/vendor" && -r "$device/name" ]] || continue
        read -r vendor < "$device/id/vendor"
        [[ "$vendor" != "3297" ]] || continue
        read -r name < "$device/name"
        name=${name//\\/\\\\}
        name=${name//\"/\\\"}
        printf '"%s"\n' "$name"
        found=1
      done
      [[ "$found" == 1 ]] || return 1
      printf ')\n'
      ;;
  esac
}

{
  printf '(defcfg process-unmapped-keys (all-except ralt)\n'
  write_non_zsa_device_allowlist
  printf ')\n(include "%s/keymap.kbd")\n' "$config_directory"
} > "$runtime_config"

if [[ "${3:-}" == "--check" ]]; then
  "$binary" --check --cfg "$runtime_config"
  exit
fi

"$binary" --no-wait --cfg "$runtime_config" &
child=$!
trap 'kill "$child" 2>/dev/null || true' TERM INT
wait "$child"
