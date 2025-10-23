#!/bin/bash

# Function to upload a git patch to pastebin
upload_patch() {
    local commit_hash=""
    local dry_run=false
    local silent=false
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --silent)
                silent=true
                shift
                ;;
            --help|-h)
                cat << 'EOF'
upload_patch - Upload git patch to pastebin

USAGE:
    upload_patch [OPTIONS] <commit_hash>

OPTIONS:
    --dry-run    Don't upload, just output the patch to stdout
    --silent     Silent mode (no output except errors)
    --help, -h   Show this help

EXAMPLES:
    upload_patch HEAD                    # Upload latest commit
    upload_patch abc123def               # Upload specific commit
    upload_patch --dry-run HEAD~1        # Show patch without uploading
    upload_patch --silent HEAD           # Upload silently

FEATURES:
    - Anonymous upload to pastebin
    - Burn after single viewing
    - Password protected (random 5-char password)
    - Works from any directory in git repo
EOF
                return 0
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                echo "Use --help for usage information" >&2
                return 1
                ;;
            *)
                if [ -z "$commit_hash" ]; then
                    commit_hash="$1"
                else
                    echo "Error: Multiple commit hashes provided" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if commit hash is provided
    if [ -z "$commit_hash" ]; then
        echo "Error: Commit hash required" >&2
        echo "Use --help for usage information" >&2
        return 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi
    
    # Verify the commit exists
    if ! git cat-file -e "$commit_hash" 2>/dev/null; then
        echo "Error: Commit '$commit_hash' not found" >&2
        return 1
    fi
    
    # Create the patch content
    local patch_content
    patch_content=$(git show --pretty=fuller "$commit_hash" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Error: Could not create patch for commit $commit_hash" >&2
        return 1
    fi
    
    # Handle dry run mode
    if [ "$dry_run" = true ]; then
        echo "$patch_content"
        return 0
    fi
    
    # Generate random 5-character password
    local password
    password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 5)
    
    [ "$silent" = false ] && echo "Uploading patch for commit: $commit_hash" >&2
    
    # Upload to pastebin with burn after reading and password protection
    local response
    response=$(curl -s -X POST \
        -d "api_option=paste" \
        -d "api_dev_key=${PASTEBIN_API_KEY}" \
        -d "api_paste_code=${patch_content}" \
        -d "api_paste_private=2" \
        -d "api_paste_password=${password}" \
        -d "api_paste_expire_date=B" \
        -d "api_paste_name=git-patch-${commit_hash:0:8}" \
        "https://pastebin.com/api/api_post.php" 2>/dev/null)
    
    # Check if upload was successful
    if [[ "$response" == https://pastebin.com/* ]]; then
        if [ "$silent" = false ]; then
            echo "URL: $response" >&2
            echo "Password: $password" >&2
            echo "ID: $(basename "$response")" >&2
        else
            echo "$response"
            echo "$password"
        fi
    else
        echo "Error: Upload failed - $response" >&2
        return 1
    fi
}
