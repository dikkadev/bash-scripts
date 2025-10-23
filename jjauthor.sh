# Reset the author of a set of revisions to the configured user.name/user.email
# Usage:
#   jj_reset_authors                # default: trunk()..@
#   jj_reset_authors 'all()'        # whole repo (careful)
#   jj_reset_authors 'heads(trunk())..@'  # whatever revset you want
jjresetauthors() {
  local revset="${1:-trunk()..@}"

  echo "Resetting author for revset: ${revset}"
  echo "Configured author is: $(jj config get user.name) <$(jj config get user.email)>"
  echo

  # Actual rewrite
  jj metaedit --update-author "${revset}"
}
