#!/usr/bin/env bash
set -euo pipefail

API="http://localhost:8384/rest"
CONF="${HOME}/.dotfiles/config/syncthing/sync.conf"
CONFIG_XML="${HOME}/.local/state/syncthing/config.xml"

[[ -f "$CONF" ]] || { echo "No sync.conf found, skipping syncthing setup"; exit 0; }
source "$CONF"

[[ ${#SYNCTHING_DEVICES[@]} -gt 0 ]] || { echo "No devices configured, skipping"; exit 0; }

echo "  Waiting for syncthing API..."
for i in $(seq 1 30); do
  if [[ -f "$CONFIG_XML" ]]; then
    apikey=$(grep -oP '<apikey>\K[^<]+' "$CONFIG_XML" 2>/dev/null || true)
    if [[ -n "$apikey" ]]; then
      APIKEY="$apikey"
      if curl -sf --max-time 2 -H "X-API-Key: $APIKEY" "$API/system/status" > /dev/null 2>&1; then
        break
      fi
    fi
  fi
  sleep 1
done

[[ -n "${APIKEY:-}" ]] || { echo "  Could not get syncthing API key"; exit 1; }

declare -A DEVICE_IDS
for entry in "${SYNCTHING_DEVICES[@]}"; do
  name="${entry%%=*}"
  id="${entry##*=}"
  DEVICE_IDS["$name"]="$id"
done

THIS_ID=$(curl -sf -H "X-API-Key: $APIKEY" "$API/system/status" | jq -r '.myID')

THIS_NAME=""
for name in "${!DEVICE_IDS[@]}"; do
  if [[ "${DEVICE_IDS[$name]}" == "$THIS_ID" ]]; then
    THIS_NAME="$name"
    break
  fi
done

if [[ -z "${THIS_NAME:-}" ]]; then
  echo "  This device ID ($THIS_ID) not found in sync.conf. Add it as a device entry."
  exit 0
fi

echo "  Detected this machine: $THIS_NAME"

CURL=(curl -sf -H "X-API-Key: $APIKEY" -H "Content-Type: application/json" --max-time 10)

existing_devices=$("${CURL[@]}" "$API/config/devices" | jq -r '.[].deviceID' 2>/dev/null || echo "")

needs_approval=()
for name in "${!DEVICE_IDS[@]}"; do
  dev_id="${DEVICE_IDS[$name]}"
  [[ "$name" == "$THIS_NAME" ]] && continue
  if echo "$existing_devices" | grep -qFx "$dev_id"; then
    echo "  Device '$name' already added"
  else
    "${CURL[@]}" -X POST "$API/config/devices" \
      -d "{\"deviceID\":\"$dev_id\",\"autoAcceptFolders\":true,\"name\":\"$name\"}"
    echo "  Added device '$name' ($dev_id)"
    needs_approval+=("$name")
  fi
done

for folder_entry in "${SYNCTHING_FOLDERS[@]}"; do
  IFS='|' read -r folder_id folder_path folder_devices <<< "$folder_entry"
  folder_path="${folder_path/#\~/$HOME}"

  existing_folders=$("${CURL[@]}" "$API/config/folders" | jq -r '.[].id' 2>/dev/null || echo "")

  folder_devices_json="["
  IFS=',' read -ra dev_names <<< "$folder_devices"
  for dname in "${dev_names[@]}"; do
    dname="${dname## }"; dname="${dname%% }"
    [[ -n "${DEVICE_IDS[$dname]:-}" ]] || continue
    folder_devices_json+="{\"deviceID\":\"${DEVICE_IDS[$dname]}\"},"
  done
  folder_devices_json="${folder_devices_json%,}]"

  if echo "$existing_folders" | grep -qFx "$folder_id"; then
    echo "  Folder '$folder_id' already exists, updating path..."
    "${CURL[@]}" -X PATCH "$API/config/folders/$folder_id" \
      -d "{\"path\":\"$folder_path\",\"devices\":$folder_devices_json}"
  else
    if [[ ! -d "$folder_path" ]]; then
      mkdir -p "$folder_path"
    fi
    "${CURL[@]}" -X POST "$API/config/folders" \
      -d "{\"id\":\"$folder_id\",\"path\":\"$folder_path\",\"devices\":$folder_devices_json}"
    echo "  Created folder '$folder_id' -> $folder_path"
  fi
done

echo "  Syncthing configured"

if [[ ${#needs_approval[@]} -gt 0 ]]; then
  echo ""
  echo "  ═══════════════════════════════════════════════"
  echo "  New device$([[ ${#needs_approval[@]} -gt 1 ]] && echo "s") need$([[ ${#needs_approval[@]} -eq 1 ]] && echo "s") approval:"
  for other in "${needs_approval[@]}"; do
    echo "    → On $other: open http://localhost:8384 and accept this device"
  done
  echo "  ═══════════════════════════════════════════════"
fi
