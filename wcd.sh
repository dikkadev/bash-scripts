wcd() {
  # no args → go home
  if [ $# -eq 0 ]; then
    builtin cd ~
    return
  fi

  # ensure wslpath exists (when passed a Windows path)
  if ! command -v wslpath >/dev/null 2>&1; then
    echo "wcd: wslpath not found; install WSL utilities." >&2
    return 1
  fi

  # take the entire rest of the line, preserving spaces
  local raw="$*"
  local target=""

  case "$raw" in
    # already a WSL-style path
    /*|/mnt/*)
      target="$raw"
      ;;
    # Windows-style path (drive letter or UNC); convert
    *)
      target="$(wslpath -a "$raw" 2>/dev/null)" || {
        echo "wcd: invalid Windows path: $raw" >&2
        return 1
      }
      ;;
  esac

  # jump
  builtin cd "$target" || {
    echo "wcd: failed to cd into: $target" >&2
    return 1
  }
}
