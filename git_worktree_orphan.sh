# Function to create a new Git worktree with a clean, empty orphan branch,
# placing the worktree directory inside the main project directory by default.
# Usage: git_worktree_orphan <new-branch-name> [relative-worktree-path]
# If relative-worktree-path is omitted, it defaults to ./<new-branch-name>
git_worktree_orphan() {
  local branch_name="$1"
  # --- CHANGE HERE: Default path is now inside the current directory ---
  local worktree_path="${2:-./${branch_name}}"
  local temp_branch_name="temp-orphan-creation-${branch_name}-$(date +%s)"
  local original_dir=$(pwd) # Remember where we started

  # --- Input Validation ---
  if [[ -z "$branch_name" ]]; then
    echo "Error: No branch name provided." >&2
    echo "Usage: git_worktree_orphan <new-branch-name> [relative-worktree-path]" >&2
    return 1
  fi

  # Check if inside a git repository's top-level directory
  # (We expect .git to be a directory here for this structure)
  if ! [[ -d ".git" && -f ".git/config" ]]; then
     echo "Error: Not in the top-level directory of a Git repository (expected './.git' directory)." >&2
     return 1
  fi

  # Prevent creating worktree inside .git
  if [[ "$worktree_path" == ".git" || "$worktree_path" == ".git/"* ]]; then
      echo "Error: Cannot create worktree inside the .git directory." >&2
      return 1
  fi

  echo "Creating worktree at '$worktree_path' for new orphan branch '$branch_name'..."

  # --- Step 1: Create worktree with a temporary branch ---
  # Use --detach initially to avoid checking out files we'll discard anyway
  if ! git worktree add --detach "$worktree_path"; then
    echo "Error: Failed to create worktree directory at '$worktree_path'." >&2
    # No cleanup needed here as worktree add failed early
    return 1
  fi

  # --- Step 2: Navigate into the new worktree ---
  if ! cd "$worktree_path"; then
    echo "Error: Failed to change directory to '$worktree_path'." >&2
    echo "Attempting cleanup: Removing partially created worktree..." >&2
    cd "$original_dir" # Go back first
    git worktree remove "$worktree_path" # Remove the worktree structure
    return 1
  fi

  # --- Step 3: Create the actual orphan branch ---
  echo "Creating orphan branch '$branch_name'..."
  # Now create the orphan branch *inside* the worktree
  if ! git checkout --orphan "$branch_name"; then
    echo "Error: Failed to create orphan branch '$branch_name'." >&2
    echo "Attempting cleanup: Removing worktree..." >&2
    cd "$original_dir" # Go back first
    git worktree remove "$worktree_path"
    # No temp branch was created in this flow yet
    return 1
  fi

  # --- Step 4: Clean the staging area and working directory ---
  # checkout --orphan might leave files staged from the original HEAD
  echo "Cleaning worktree..."
  if [[ -n "$(git ls-files)" ]]; then
    if ! git rm -rf .; then
        echo "Warning: Failed to clean all files from the worktree index/directory." >&2
        # Continue, but warn the user
    fi
  else
      echo "(Worktree already clean)"
  fi

  # --- Step 5: (No temporary branch to delete in this revised flow) ---

  # --- Step 6: Return to the original directory ---
  cd "$original_dir" || return 1 # Go back to where user started

  echo ""
  echo "✅ Success!"
  echo "New orphan branch '$branch_name' created."
  echo "Worktree is located at: '$worktree_path' (inside your project directory)"
  echo "The branch is currently empty (no commits, no files)."
  echo "To start working:"
  echo "  cd '$worktree_path'"
  echo "  # Add your files"
  echo "  git add ."
  echo "  git commit -m 'Initial commit for $branch_name'"

  return 0 # Indicate success
}

# Optional: Create a shorter alias for the function
alias gwto='git_worktree_orphan'
