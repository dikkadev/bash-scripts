## 1. alias: git sync <branch>
# Fetch exactly one remote branch from origin, create/update the remote-tracking ref locally,
# but don't pull the entire world.
git config --global alias.sync \
'!sync() { \
  branch="$1"; \
  if [ -z "$branch" ]; then \
    echo "usage: git f <branch-name>" >&2; \
    exit 1; \
  fi; \
  git fetch origin "$branch":refs/remotes/origin/"$branch"; \
}; sync'

