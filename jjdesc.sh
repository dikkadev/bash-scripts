# shared core (not meant to be called directly)
__jjd_core() {
  local do_new="$1"
  local msg

  # Read message interactively
  read -p "> " msg

  if [[ -z "$msg" ]]; then
    echo "Aborted: empty description."
    return 1
  fi

  # Only run jj new if desc succeeds
  if jj desc -m "$msg"; then
    [[ "$do_new" == "1" ]] && jj new
  fi
}

jjd() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: jjd"
    echo "  Prompts for a description and runs 'jj desc -m MESSAGE'."
    return 0
  fi

  __jjd_core 0
}

jjdn() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: jjdn"
    echo "  Prompts for a description, runs 'jj desc -m MESSAGE',"
    echo "  then runs 'jj new'."
    return 0
  fi

  __jjd_core 1
}
