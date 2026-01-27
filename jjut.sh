# Update trunk bookmark to @- and optionally push
# Usage:
#   jjut              # update trunk to @- and push
#   jjut -n           # update trunk to @- without pushing
#   jjut --no-push    # update trunk to @- without pushing
jjut() {
  local push=true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo "Usage: jjut [-n|--no-push] [-h|--help]"
        echo ""
        echo "Update trunk bookmark to @- (commit before current) and push."
        echo ""
        echo "Options:"
        echo "  -n, --no-push  Update trunk without pushing"
        echo "  -h, --help     Show this help message"
        return 0
        ;;
      -n|--no-push)
        push=false
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Usage: jjut [-n|--no-push] [-h|--help]" >&2
        return 1
        ;;
    esac
  done

  jj bookmark set trunk -r '@-' -B || return 1

  if [[ "$push" == true ]]; then
    jj git push -b trunk
  fi
}
