#!/bin/bash
worktree-new() {
    # Handle help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<EOF
Usage: worktree-new <branch_name> [base_branch]

Create a new branch and a correponding worktree. Not for getting a remote existing branch!

Arguments:
  branch_name   Name of the new branch to create
  base_branch   Optional: base branch to create the new branch from (defaults to default branch of the remote repository? (I think so))
EOF
        return 0
    fi

    if [ -z "$1" ]; then
        echo "Error: branch_name is required." >&2
        echo "Usage: worktree-new <branch_name> [base_branch]" >&2
        return 1
    fi

    BRANCH_NAME="$1"
    DEFAULT_BRANCH=$( git remote show origin | sed -n '/HEAD branch/s/.*: //p' )
    BASE_BRANCH="${2:-$DEFAULT_BRANCH}"

    if [ -z "$BRANCH_NAME" ]; then
        echo "Error: branch_name cannot be empty." >&2
        return 1
    fi

    if [ -z "$BASE_BRANCH" ]; then
        echo "Error: base_branch cannot be empty." >&2
        return 1
    fi

    # update the base branch with a fetch and pull (soft)
    echo "Updating base branch '$BASE_BRANCH'…"
    BASE_BRANCH_DIR=$(git worktree list | sed -n "/\[$BASE_BRANCH\]/s/ .*//p")
    BASE_BRANCH_EXISTS_LOCALLY=true
    if [ -z "$BASE_BRANCH_DIR" ]; then
        echo "Error: Base branch '$BASE_BRANCH' not found in worktrees." >&2
        BASE_BRANCH_EXISTS_LOCALLY=false
    fi

    if $BASE_BRANCH_EXISTS_LOCALLY; then
        echo "Base branch '$BASE_BRANCH' found in worktrees at '$BASE_BRANCH_DIR'."
        echo "Fetching and pulling updates for base branch '$BASE_BRANCH'…"
        if ! git -C "$BASE_BRANCH_DIR" fetch origin "$BASE_BRANCH"; then
            echo "Error: Failed to fetch updates for base branch '$BASE_BRANCH'." >&2
            return 1
        fi

        if ! git -C "$BASE_BRANCH_DIR" pull origin "$BASE_BRANCH"; then
            echo "Error: Failed to pull updates for base branch '$BASE_BRANCH'." >&2
            return 1
        fi
    fi

    echo "Creating new worktree for branch '$BRANCH_NAME' based on '$BASE_BRANCH'…"
    
    CMD="git worktree add -b \"$BRANCH_NAME\" \"./$BRANCH_NAME\" \"$BASE_BRANCH\""
    if ! eval "$CMD"; then
        echo "Error: Failed to create worktree for branch '$BRANCH_NAME'." >&2
        return 1
    fi

    echo "✅ Worktree for branch '$BRANCH_NAME' created successfully at ./$BRANCH_NAME"
}
