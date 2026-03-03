#!/bin/bash

uri() {
  local input="${1:-.}"

  # Resolve to absolute path
  local abs
  abs="$(realpath -m -- "$input" 2>/dev/null)" || {
    echo "uri: cannot resolve path: $input" >&2
    return 1
  }

  local url

  if [[ "$abs" =~ ^/mnt/([a-zA-Z])(/.*)?$ ]]; then
    # Windows mounted path: /mnt/c/Users/... → file:///C:/Users/...
    local drive_letter="${BASH_REMATCH[1]}"
    drive_letter="${drive_letter^^}"
    local win_path="${BASH_REMATCH[2]}"
    url="file:///${drive_letter}:${win_path:-/}"
  else
    # WSL path: /home/dikka/... → file://wsl.localhost/Ubuntu/home/dikka/...
    local distro
    distro="$(sed -n 's/^ID=//p' /etc/os-release 2>/dev/null)"
    # Capitalize first letter to match wsl.localhost convention
    distro="${distro^}"
    url="file://wsl.localhost/${distro}${abs}"
  fi

  # URL-encode spaces and common special chars (but not / : .)
  url="${url// /%20}"

  echo "$url"
}
