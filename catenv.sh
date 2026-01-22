#!/bin/bash

catenv() {
  local search_dir="$PWD"
  local git_root=""

  # Check if we're in a git repo
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$git_root" ]]; then
    # Not in a git repo, only check current directory
    if [[ -f ".env" ]]; then
      _catenv_print ".env"
    else
      echo "No .env file found in current directory (not in a git repo)" >&2
      return 1
    fi
    return 0
  fi

  # In a git repo, search from current dir up to git root
  while [[ "$search_dir" == "$git_root"* ]]; do
    if [[ -f "$search_dir/.env" ]]; then
      echo "# Found: $search_dir/.env"
      _catenv_print "$search_dir/.env"
      return 0
    fi

    # Stop if we've reached the git root
    if [[ "$search_dir" == "$git_root" ]]; then
      break
    fi

    # Go up one directory
    search_dir=$(dirname "$search_dir")
  done

  echo "No .env file found between current directory and git root ($git_root)" >&2
  return 1
}

_catenv_print() {
  local env_file="$1"

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines
    if [[ -z "$line" ]]; then
      echo
      continue
    fi

    # Preserve comments as-is
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      echo "$line"
      continue
    fi

    # Handle export prefix
    local prefix=""
    local content="$line"
    if [[ "$line" =~ ^export[[:space:]]+ ]]; then
      prefix="export "
      content="${line#export }"
      content="${content#"${content%%[![:space:]]*}"}"  # trim leading whitespace
    fi

    # Extract key (everything before first =)
    if [[ "$content" =~ ^([^=]+)= ]]; then
      local key="${BASH_REMATCH[1]}"
      echo "${prefix}${key}=***"
    else
      # Line doesn't contain =, print as-is (might be malformed or continuation)
      echo "$line"
    fi
  done < "$env_file"
}
