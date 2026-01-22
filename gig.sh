# gig: Add files/directories to .gitignore intelligently
gig() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: gig <path> [path ...]

Add files or directories to .gitignore at the repository root.

Features:
  - Checks if path is already covered by existing patterns
  - Converts paths to repo-relative format
  - Adds trailing slash for directories
  - Creates .gitignore if it doesn't exist

Examples:
  gig node_modules           # Add directory
  gig .env secrets.json      # Add multiple files
  gig ./build                # Handles relative paths
EOF
        return 0
    fi

    local repo_root
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
        echo "gig: not in a git repository" >&2
        return 1
    }

    if [[ $# -eq 0 ]]; then
        echo "gig: at least one path required" >&2
        echo "Usage: gig <path> [path ...]" >&2
        return 1
    fi

    local gitignore="$repo_root/.gitignore"
    local added=0
    local skipped=0

    for path in "$@"; do
        local abs_path
        abs_path="$(realpath -m "$path" 2>/dev/null)" || abs_path="$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"

        local rel_path="${abs_path#$repo_root/}"

        if [[ "$abs_path" == "$repo_root" ]]; then
            echo "gig: cannot ignore repository root" >&2
            continue
        fi

        if [[ -d "$abs_path" ]]; then
            rel_path="${rel_path%/}/"
        fi

        if git check-ignore -q "$abs_path" 2>/dev/null; then
            echo "gig: '$rel_path' already ignored"
            ((skipped++))
            continue
        fi

        if [[ -f "$gitignore" ]]; then
            local base="${rel_path%/}"
            if grep -qxF "$rel_path" "$gitignore" 2>/dev/null || \
               grep -qxF "$base" "$gitignore" 2>/dev/null || \
               grep -qxF "/$rel_path" "$gitignore" 2>/dev/null || \
               grep -qxF "/$base" "$gitignore" 2>/dev/null; then
                echo "gig: '$rel_path' already in .gitignore"
                ((skipped++))
                continue
            fi
        fi

        echo "$rel_path" >> "$gitignore"
        echo "gig: added '$rel_path'"
        ((added++))
    done

    if [[ $((added + skipped)) -gt 1 ]]; then
        echo "gig: $added added, $skipped skipped"
    fi
}
