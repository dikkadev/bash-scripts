# Update default bookmark to @- and optionally push
# Usage:
#   jjut              # detect default bookmark, update to @- and push
#   jjut -b main      # use 'main' bookmark explicitly
#   jjut -n           # update without pushing
jjut() {
  local push=true
  local bookmark=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo "Usage: jjut [-b BOOKMARK] [-n|--no-push] [-h|--help]"
        echo ""
        echo "Update the default bookmark to @- (commit before current) and push."
        echo "Detects the default bookmark (main/master/trunk) automatically."
        echo ""
        echo "Options:"
        echo "  -b BOOKMARK    Use a specific bookmark instead of auto-detecting"
        echo "  -n, --no-push  Update bookmark without pushing"
        echo "  -h, --help     Show this help message"
        return 0
        ;;
      -b)
        bookmark="$2"
        shift 2
        ;;
      -n|--no-push)
        push=false
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Usage: jjut [-b BOOKMARK] [-n|--no-push] [-h|--help]" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$bookmark" ]]; then
    # Detect default bookmark by checking which of trunk/main/master exists locally
    for name in trunk main master; do
      if jj bookmark list "$name" 2>/dev/null | grep -q "^$name:"; then
        bookmark="$name"
        break
      fi
    done
    if [[ -z "$bookmark" ]]; then
      echo "Error: could not detect default bookmark (tried trunk, main, master)" >&2
      echo "Use -b to specify one explicitly" >&2
      return 1
    fi
  fi

  jj bookmark set "$bookmark" -r '@-' -B || return 1

  if [[ "$push" == true ]]; then
    jj git push -b "$bookmark"
  fi
}
