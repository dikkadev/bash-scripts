#!/bin/bash

uri() {
  local copy=false

  # Parse flags
  local OPTIND=1
  while getopts "ch" opt; do
    case "$opt" in
      c) copy=true ;;
      h)
        echo "Usage: uri [-c] [-h] [path]"
        echo "  Generate a browser-ready file:// URL for a path."
        echo "  -c  Copy URL to clipboard"
        echo "  -h  Show this help"
        return 0
        ;;
      *) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))

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
    distro="${distro^}"
    url="file://wsl.localhost/${distro}${abs}"
  fi

  url="${url// /%20}"

  if $copy; then
    printf '%s' "$url" | clip.exe
    echo "$url (copied)"
  else
    echo "$url"
  fi
}
