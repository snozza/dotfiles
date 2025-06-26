# Stages a local file to a specified path in the dotfiles repo.
# Usage: dot-stage <local_file_path> <repo_path>
# Example: dot-stage ~/.vimrc vim/.vimrc
dot-stage() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: dot-stage <local_file_path> <repo_path>"
    return 1
  fi

  local local_file="$1"
  local repo_path="$2"

  if [ ! -f "$local_file" ]; then
    echo "Error: Local file '$local_file' not found."
    return 1
  fi

  echo "Staging '$local_file' as '$repo_path'..."

  # 1. Hash the local file's content and write it to the repo's object database.
  local new_hash
  new_hash=$(dotfiles hash-object -w "$local_file")

  # 2. Add or update the index to point to the new content hash at the desired repo path.
  # The --add flag works for both new and updated files in this context.
  dotfiles update-index --add --cacheinfo 100644 "$new_hash" "$repo_path"

  echo "Done. Use 'dotfiles status' to verify."
}

# Diffs a local file against its version in the last commit (HEAD).
# Usage: dot-diff <local_file_path> <repo_path>
# Example: dot-diff ~/.vimrc vim/.vimrc
dot-diff() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: dot-diff <local_file_path> <repo_path>"
    return 1
  fi

  local local_file="$1"
  local repo_path="$2"

  if [ ! -f "$local_file" ]; then
    echo "Error: Local file '$local_file' not found."
    return 1
  fi

  # Get the hash of the file in the last commit.
  # If the file is new, this will be empty.
  local repo_hash
  repo_hash=$(dotfiles rev-parse HEAD:"$repo_path" 2>/dev/null)

  # Get the hash of the local file (without writing to the db yet).
  local local_hash
  local_hash=$(dotfiles hash-object "$local_file")

  if [ -z "$repo_hash" ]; then
    # The file doesn't exist in the repo yet, so diff against an empty object.
    echo "File '$repo_path' is new. Showing contents to be added:"
    # The hash of an empty blob is always the same.
    local empty_blob_hash="e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"
    dotfiles diff --color=always "$empty_blob_hash" "$local_hash"
  else
    # The file exists, so diff the repo version against the local version.
    dotfiles diff --color=always "$repo_hash" "$local_hash"
  fi
}

# Stages all files from a local directory to a specified directory path in the dotfiles repo.
# Usage: dot-stage-dir <local_dir_path> <repo_dir_path>
# Example: dot-stage-dir ~/.zsh_functions zsh_functions
dot-stage-dir() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: dot-stage-dir <local_dir_path> <repo_dir_path>"
    return 1
  fi

  local local_dir="$1"
  local repo_dir="$2"

  if [ ! -d "$local_dir" ]; then
    echo "Error: Local directory '$local_dir' not found."
    return 1
  fi

  # Use `find` to get all files in the local directory.
  # The `cd` is important to get the relative paths of the files correctly.
  (
    cd "$local_dir" || return
    find . -type f | while read -r file; do
      # Remove the leading './' from the find output
      local_file_rel_path="${file#./}"

      # The full path to the local file
      local local_file_full_path="$local_dir/$local_file_rel_path"

      # The desired path for the file inside the git repo
      local repo_file_path="$repo_dir/$local_file_rel_path"

      echo "Staging '$local_file_full_path' as '$repo_file_path'"

      # Hash the file and write it to the object database
      local new_hash
      new_hash=$(dotfiles hash-object -w "$local_file_full_path")

      # Update the index for this specific file
      dotfiles update-index --add --cacheinfo 100644 "$new_hash" "$repo_file_path"
    done
  )

  echo "Done staging directory. Use 'dotfiles status' to verify."
}
