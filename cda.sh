# cda: cd into a target directory across all tmux panes in the current window
# Tip: You can place this in your ~/.bashrc or ~/.bash_aliases (or any file you source).
#      Alternatively, save it as cda.sh and source it:
#         source /path/to/cda.sh

cda() {
  local targetDir="$1"
  if [[ -z "$targetDir" ]]; then
    echo "Usage: cda /path/to/dir"
    return 1
  fi

  local absTargetDir
  absTargetDir="$(readlink -f "$targetDir")" || return 1
  cd "$absTargetDir" || return 1

  local sessionWindow
  sessionWindow="$(tmux display-message -p '#S:#I')"

  for pane in $(tmux list-panes -F '#P'); do
    tmux send-keys -t "$sessionWindow.$pane" "cd '$absTargetDir'" C-m
  done
}
