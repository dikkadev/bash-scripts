# ghget: Download a file or directory from a GitHub repo as a zip
ghget() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: ghget <github-url> [output.zip]

Download a specific file or directory from a GitHub repository as a zip.

The URL should be a GitHub web URL pointing to a file or directory, e.g.:
  https://github.com/owner/repo/tree/branch/path/to/dir
  https://github.com/owner/repo/blob/branch/path/to/file.go

If no output filename is given, defaults to the last path component + .zip.

Examples:
  ghget https://github.com/dikkadev/tag/tree/main/src
  ghget https://github.com/golang/go/tree/master/src/fmt output.zip
  ghget https://github.com/owner/repo/blob/main/README.md
EOF
        return 0
    fi

    if [[ $# -eq 0 ]]; then
        echo "ghget: URL required" >&2
        echo "Usage: ghget <github-url> [output.zip]" >&2
        return 1
    fi

    local url="$1"
    local output="$2"

    # Parse the GitHub URL
    # Formats:
    #   https://github.com/owner/repo/tree/branch/path...
    #   https://github.com/owner/repo/blob/branch/path...
    #   https://github.com/owner/repo (root of default branch)
    local stripped="${url#https://github.com/}"
    if [[ "$stripped" == "$url" ]]; then
        echo "ghget: not a github.com URL" >&2
        return 1
    fi

    local owner repo ref subpath
    owner="$(echo "$stripped" | cut -d/ -f1)"
    repo="$(echo "$stripped" | cut -d/ -f2)"

    if [[ -z "$owner" || -z "$repo" ]]; then
        echo "ghget: could not parse owner/repo from URL" >&2
        return 1
    fi

    local rest="${stripped#$owner/$repo}"
    rest="${rest#/}"

    if [[ -z "$rest" ]]; then
        # Root of repo, need to figure out default branch
        ref="$(gh api "repos/$owner/$repo" --jq '.default_branch' 2>/dev/null)" || {
            echo "ghget: could not determine default branch (is gh CLI installed and authenticated?)" >&2
            return 1
        }
        subpath=""
    else
        # Strip tree/ or blob/ prefix
        rest="${rest#tree/}"
        rest="${rest#blob/}"
        # First component is the ref, rest is the path
        ref="$(echo "$rest" | cut -d/ -f1)"
        subpath="$(echo "$rest" | cut -d/ -f2-)"
        # If cut returns the same as input, there's no subpath
        if [[ "$subpath" == "$ref" ]]; then
            subpath=""
        fi
    fi

    # Determine output filename
    if [[ -z "$output" ]]; then
        if [[ -n "$subpath" ]]; then
            local basename="${subpath##*/}"
            output="${basename}.zip"
        else
            output="${repo}.zip"
        fi
    fi

    local tmpdir
    tmpdir="$(mktemp -d)" || { echo "ghget: failed to create temp dir" >&2; return 1; }
    trap "rm -rf '$tmpdir'" RETURN

    echo "ghget: downloading $owner/$repo@$ref${subpath:+/$subpath} ..."

    # Download the branch zip from GitHub
    local zip_url="https://github.com/$owner/$repo/archive/refs/heads/$ref.zip"
    if ! curl -fsSL -o "$tmpdir/repo.zip" "$zip_url" 2>/dev/null; then
        # Try as a tag
        zip_url="https://github.com/$owner/$repo/archive/refs/tags/$ref.zip"
        if ! curl -fsSL -o "$tmpdir/repo.zip" "$zip_url" 2>/dev/null; then
            # Try the generic archive endpoint via gh
            if ! gh api "repos/$owner/$repo/zipball/$ref" > "$tmpdir/repo.zip" 2>/dev/null; then
                echo "ghget: failed to download archive for ref '$ref'" >&2
                return 1
            fi
        fi
    fi

    # Extract the archive
    if ! unzip -q "$tmpdir/repo.zip" -d "$tmpdir/extracted" 2>/dev/null; then
        echo "ghget: failed to extract archive" >&2
        return 1
    fi

    # GitHub zips have a top-level dir like "repo-branch/"
    local top_dir
    top_dir="$(ls "$tmpdir/extracted")"

    local source_path="$tmpdir/extracted/$top_dir"
    if [[ -n "$subpath" ]]; then
        source_path="$source_path/$subpath"
    fi

    if [[ ! -e "$source_path" ]]; then
        echo "ghget: path '$subpath' not found in $owner/$repo@$ref" >&2
        return 1
    fi

    # Create the output zip
    if [[ -f "$source_path" ]]; then
        # Single file
        (cd "$(dirname "$source_path")" && zip -q "$OLDPWD/$output" "$(basename "$source_path")")
    else
        # Directory
        (cd "$source_path" && zip -qr "$OLDPWD/$output" .)
    fi

    if [[ $? -eq 0 ]]; then
        local size
        size="$(du -h "$output" | cut -f1)"
        echo "ghget: saved $output ($size)"
    else
        echo "ghget: failed to create zip" >&2
        return 1
    fi
}
