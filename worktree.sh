#!/bin/bash
worktree() {
    # Handle help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<EOF
Usage: worktree <remote_url> [directory_name]

Clone a remote Git repository as a bare repo and set up a worktree of its default branch.

Arguments:
  remote_url     URL of the remote repository
  directory_name Optional: target directory name (defaults to \$(basename <remote_url> .git))
EOF
        return 0
    fi

    if [ -z "$1" ]; then
        echo "Error: Remote URL is required." >&2
        echo "Usage: worktree <remote_url> [directory_name]" >&2
        return 1
    fi

    REMOTE_URL="$1"
    DIRNAME="${2:-$(basename "$REMOTE_URL" .git)}"

    if [ -d "$DIRNAME" ]; then
        echo "Error: Directory '$DIRNAME' already exists." >&2
        return 1
    fi

    mkdir -p "$DIRNAME" || {
        echo "Error: Could not create directory '$DIRNAME'." >&2
        return 1
    }
    cd "$DIRNAME" || {
        echo "Error: Failed to change to directory '$DIRNAME'." >&2
        return 1
    }

    echo "Cloning bare repository into .git/…"
    git clone --bare "$REMOTE_URL" .git || {
        echo "Error: git clone failed; cleaning up." >&2
        cd ..
        rm -rf "$DIRNAME"
        return 1
    }

    git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

    echo "Fetching all branches…"
    git fetch || {
        echo "Error: git fetch failed." >&2
        return 1
    }

    echo "Adding worktree for 'main' branch…"
    if ! git worktree add main main 2>/dev/null; then
        echo "Branch 'main' not found; trying 'master'…" 
        if ! git worktree add main master 2>/dev/null; then
            echo "Error: Neither 'main' nor 'master' exist." >&2
            return 1
        fi
    fi

    echo "✅ Worktree ready at $DIRNAME/main"
    return 0
}

