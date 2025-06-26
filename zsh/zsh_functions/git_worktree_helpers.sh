# -----------------------------------------------------------------------------
# Git Worktree Helper Functions for Zsh
#
# This script is correct and relies on the zparseopts utility.
# The error "zparseopts: function definition file not found" is caused by
# incorrect load order in your ~/.zshrc, not by this script.
#
# Ensure `autoload -Uz compinit && compinit` is at the END of your ~/.zshrc.
# -----------------------------------------------------------------------------

# Function to create a new Git worktree
# Usage: wt <new-branch-and-folder-name> [source-branch] [options]
wt() {
  # --- 1. Argument Parsing ---
  zmodload zsh/zutil # This loads the module containing zparseopts
  zparseopts -D -E -A opts -- \
    copy-env \
    help

  # Process remaining positional arguments after options are parsed
  local new_branch_name="$1"
  local source_branch_name="${2:-main}" # Default source branch is 'main'

  # --- 2. Initial Setup & Validations ---
  if [[ -n "$opts[--help]" || -z "$new_branch_name" ]]; then
      echo "Usage: wt <new-branch-and-folder-name> [source-branch] [options]"
      echo "\nCreates a new git worktree and branch."
      echo "\nOptions:"
      echo "  --copy-env        Copy .env and .env.local from main repo to new worktree."
      echo "  --help            Show this help message."
      echo "\nExample:"
      echo "  wt my-feature develop --copy-env"
      return $(( $# > 0 ? 0 : 1 )) # Return 0 for --help, 1 for missing arg
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  if [[ -z "$repo_root" ]]; then
    echo "Error: Not a git repository (or any of the parent directories)." >&2
    return 1
  fi

  local worktree_parent_dir="$(dirname "$repo_root")/worktrees" # Sibling directory
  local worktree_path="$worktree_parent_dir/$new_branch_name"
  local do_copy_env_files=false
  local files_to_copy_from_main_repo=(".env" ".env.local") # Customize this list

  if [[ -n "$opts[--copy-env]" ]]; then
      do_copy_env_files=true
  fi

  local effective_source_branch="$source_branch_name"
  if ! git rev-parse --verify "$source_branch_name" &>/dev/null; then
    if git rev-parse --verify "origin/$source_branch_name" &>/dev/null; then
      effective_source_branch="origin/$source_branch_name"
      echo "Info: Source branch '$source_branch_name' not found locally, using 'origin/$source_branch_name'."
    else
      echo "Error: Source branch '$source_branch_name' (and 'origin/$source_branch_name') does not exist." >&2
      git branch -a
      return 1
    fi
  fi

  if [[ -e "$worktree_path" ]]; then
    echo "Error: Worktree path '$worktree_path' already exists." >&2
    return 1
  fi

  if ! mkdir -p "$worktree_parent_dir"; then
    echo "Error: Could not create parent directory for worktrees: $worktree_parent_dir" >&2
    return 1
  fi

  # --- 3. Create Worktree ---
  echo "Creating worktree '$new_branch_name' from branch '$effective_source_branch' at '$worktree_path'..."
  if git worktree add -b "$new_branch_name" "$worktree_path" "$effective_source_branch"; then
    echo "Successfully created worktree."

    # --- 4. Copy Environment Files (if requested) ---
    if [[ "$do_copy_env_files" == true ]]; then
      echo "Attempting to copy environment files to new worktree..."
      for file_to_copy in "${files_to_copy_from_main_repo[@]}"; do
        local source_file_path="$repo_root/$file_to_copy"
        local dest_file_path="$worktree_path/$file_to_copy"

        if [[ -f "$source_file_path" ]]; then
          if cp "$source_file_path" "$dest_file_path"; then
            echo "  Copied '$file_to_copy' from main repo to worktree."
          else
            echo "  Warning: Failed to copy '$file_to_copy'." >&2
          fi
        else
          echo "  Info: Source file '$source_file_path' not found in main repo, not copied."
        fi
      done
    fi

    # --- 5. Switch to Worktree ---
    echo "Switching to '$worktree_path'..."
    cd "$worktree_path" || { echo "Error: Failed to cd into '$worktree_path'." >&2; return 1; }
    echo "Now in worktree: $(pwd)"
    echo "Current branch: $(git symbolic-ref --short HEAD)"
  else
    echo "Error: Failed to create worktree '$new_branch_name' from '$effective_source_branch'." >&2
    return 1
  fi
}

# Function to clean up (remove) ALL non-main Git worktrees
wtc() {
  local force_remove_flag=""
  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  if [[ -z "$repo_root" ]]; then
    echo "Error: Not a git repository." >&2
    return 1
  fi

  if [[ "$1" == "--force" || "$1" == "-f" ]]; then
    force_remove_flag="--force"
    echo "Force mode enabled."
  fi

  echo "Pruning stale worktree entries..."
  git worktree prune
  echo

  # SAFER METHOD: Filter out the main branch to avoid accidents.
  local worktree_paths
  worktree_paths=$(git worktree list | grep -v "\[main\]" | awk '{print $1}')

  if [[ -z "$worktree_paths" ]]; then
    echo "No additional worktrees found to remove."
    return 0
  fi

  echo "The following worktrees will be removed:"
  echo "$worktree_paths"
  echo

  local confirmation
  read -r 'confirmation?Are you sure you want to remove these worktrees? (y/N): '
  if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    return 1
  fi

  print -l $worktree_paths | while IFS= read -r wt_path; do
    echo -n "Removing worktree at '$wt_path'... "
    if git worktree remove $force_remove_flag "$wt_path"; then
      echo "Done."
    else
      echo "Failed." >&2
      echo "  (Try 'wtc --force' if there are uncommitted changes or it's locked)" >&2
    fi
  done
  echo "Worktree cleanup complete."
}

# Function to commit changes, merge branch into a target, and optionally clean up.
wtm() {
  # --- 1. Parameter Parsing ---
  zmodload zsh/zutil # This loads the module containing zparseopts
  zparseopts -D -E -A opts -- \
    m: -message: \
    p -push \
    d -delete-branch \
    R -delete-remote \
    C -cleanup-worktree \
    n -no-ff \
    f -force \
    help

  if [[ -n "$opts[--help]" || $# -eq 0 ]]; then
    echo "Usage: wtm <target_branch> [options]"
    echo "\nMerges the current worktree's branch into a target branch and cleans up."
    echo "\nOptions:"
    echo "  -m, --message \"MSG\"    Commit message for pending changes."
    echo "  -p, --push             Push target_branch after merge."
    echo "  -d, --delete-branch    Delete local feature branch."
    echo "  -R, --delete-remote    Delete remote feature branch (implies -d, prompts)."
    echo "  -C, --cleanup-worktree Remove the worktree (implies -d, prompts)."
    echo "  -n, --no-ff            Use 'git merge --no-ff'."
    echo "  -f, --force            Force delete operations."
    echo "  --help                 Show this help message."
    return $(( $# > 0 ? 0 : 1 ))
  fi

  # Remaining argument is the target branch
  local target_branch="$1"

  # --- 2. Variable Setup from Parsed Options ---
  local commit_message="${opts[--message]:-${opts[-m]}}"
  local do_push=false && [[ -n "$opts[-p]$opts[--push]" ]] && do_push=true
  local do_delete_local_branch=false && [[ -n "$opts[-d]$opts[--delete-branch]" ]] && do_delete_local_branch=true
  local do_delete_remote_branch=false && [[ -n "$opts[-R]$opts[--delete-remote]" ]] && do_delete_remote_branch=true
  local do_cleanup_worktree=false && [[ -n "$opts[-C]$opts[--cleanup-worktree]" ]] && do_cleanup_worktree=true
  local use_no_ff=false && [[ -n "$opts[-n]$opts[--no-ff]" ]] && use_no_ff=true
  local force_ops=false && [[ -n "$opts[-f]$opts[--force]" ]] && force_ops=true

  # If -R or -C, imply -d
  if [[ "$do_delete_remote_branch" == true || "$do_cleanup_worktree" == true ]]; then
    do_delete_local_branch=true
  fi

  # --- 3. Initial Checks and Path Discovery ---
  local current_worktree_path
  current_worktree_path=$(git rev-parse --show-toplevel)
  if [[ $? -ne 0 || -z "$current_worktree_path" ]]; then
    echo "Error: Not in a git repository or worktree." >&2
    return 1
  fi

  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -z "$current_branch" ]]; then
    echo "Error: Could not determine current branch in '$current_worktree_path'." >&2
    return 1
  fi

  if [[ "$current_branch" == "$target_branch" ]]; then
    echo "Error: Current branch ('$current_branch') is the same as target branch ('$target_branch')." >&2
    return 1
  fi

  # Robustly find the main repository path
  local common_git_dir main_repo_path
  common_git_dir=$(git rev-parse --path-format=absolute --git-common-dir)
  if [[ $? -ne 0 || -z "$common_git_dir" ]]; then
      echo "Error: Could not determine the common git directory." >&2
      return 1
  fi
  main_repo_path=$(dirname "$common_git_dir")

  echo "Current worktree branch: $current_branch (at $current_worktree_path)"
  echo "Target branch for merge: $target_branch"
  echo "Main repository path:    $main_repo_path"
  echo "---"

  # --- 4. Commit Changes in Current Worktree (in a subshell to keep pwd) ---
  (
    cd "$current_worktree_path" || { echo "Error: Failed to cd to worktree $current_worktree_path" >&2; exit 1; }

    # Check for uncommitted changes
    if ! git diff --quiet HEAD || ! git diff --cached --quiet HEAD; then
      echo "You have uncommitted changes in '$current_branch'."
      if [[ -n "$commit_message" ]]; then
        echo "Auto-committing with message: '$commit_message'"
        git add . && git commit -m "$commit_message" || { echo "Commit failed." >&2; exit 1; }
      else
        local commit_now
        read -r 'commit_now?Commit changes now? (y/N/e to edit message): '
        if [[ "$commit_now" =~ ^[Ee]$ ]]; then
          git add . && git commit || { echo "Commit aborted by user or failed." >&2; exit 1; }
        elif [[ "$commit_now" =~ ^[Yy]$ ]]; then
          commit_message="WIP: Auto-commit before merging $current_branch"
          echo "Committing with default message: '$commit_message'"
          git add . && git commit -m "$commit_message" || { echo "Commit failed." >&2; exit 1; }
        else
          echo "Aborting. Please commit or stash your changes."
          exit 1
        fi
      fi
      echo "Changes committed to '$current_branch'."
    else
      echo "No uncommitted changes in '$current_branch'."
    fi

    local push_feature
    read -r 'push_feature?Push feature branch '"'$current_branch'"' before merging? (y/N): '
    if [[ "$push_feature" =~ ^[Yy]$ ]]; then
        echo "Pushing '$current_branch' to origin..."
        git push origin "$current_branch" || {
            echo "Warning: Failed to push '$current_branch'. Continuing with merge..." >&2
        }
    fi
  ) || return 1 # If subshell fails, exit function

  echo "---"
  # --- 5. Switch to Target Branch and Merge (in a subshell) ---
  echo "Attempting merge in main repository context ($main_repo_path)..."
  (
    cd "$main_repo_path" || { echo "Error: Failed to cd to main repository path $main_repo_path" >&2; exit 1; }

    local StashName="wtm_stash_$(date +%s)"
    local stash_applied_in_main=false

    # Stash if there are uncommitted changes in the main worktree
    if ! git diff --quiet HEAD || ! git diff --cached --quiet HEAD; then
      echo "Uncommitted changes found in worktree '$main_repo_path'. Stashing..."
      if git stash push -u -m "$StashName"; then
        stash_applied_in_main=true
      else
        echo "Error: Failed to stash changes in '$main_repo_path'. Aborting." >&2
        exit 1
      fi
    fi

    echo "Checking out '$target_branch'..."
    git checkout "$target_branch" || {
      echo "Error: Failed to checkout '$target_branch'. Does it exist?" >&2
      if [[ "$stash_applied_in_main" == true ]]; then git stash pop; fi
      exit 1
    }

    echo "Pulling latest changes for '$target_branch' (fast-forward only)..."
    if ! git pull --ff-only origin "$target_branch"; then
        echo "Warning: Could not fast-forward pull '$target_branch'." >&2
        local continue_merge
        read -r 'continue_merge?Continue with merge anyway? (y/N): '
        if [[ ! "$continue_merge" =~ ^[Yy]$ ]]; then
            if [[ "$stash_applied_in_main" == true ]]; then git stash pop; fi
            echo "Merge aborted."
            exit 1
        fi
    fi

    echo "Merging '$current_branch' into '$target_branch'..."
    local merge_opts=()
    if [[ "$use_no_ff" == true ]]; then
        merge_opts+=(--no-ff)
    fi

    if git merge "${merge_opts[@]}" "$current_branch"; then
      echo "Merge successful."
      if [[ "$do_push" == true ]]; then
        echo "Pushing '$target_branch' to origin..."
        git push origin "$target_branch" || echo "Warning: Push of '$target_branch' failed." >&2
      fi
    else
      echo "MERGE FAILED. Please resolve conflicts in '$main_repo_path'." >&2
      if [[ "$stash_applied_in_main" == true ]]; then
        echo "Remember to 'git stash pop' to restore your changes."
      fi
      exit 1
    fi

    if [[ "$stash_applied_in_main" == true ]]; then
      echo "Attempting to pop stashed changes in '$main_repo_path'..."
      git stash pop || echo "Warning: Failed to auto-pop stash. Please do it manually: git stash pop" >&2
    fi
  ) || return 1

  echo "---"
  # --- 6. Cleanup (Optional, in a subshell) ---
  (
    cd "$main_repo_path" || exit 1

    if [[ "$do_cleanup_worktree" == true ]]; then
      local confirm_wt_cleanup
      if [[ "$(realpath "$current_worktree_path")" == "$(realpath "$main_repo_path")" ]]; then
        echo "Info: '$current_branch' was in the main worktree. No separate worktree to remove."
      else
        read -r 'confirm_wt_cleanup?Remove worktree at '"'$current_worktree_path'"'? (y/N): '
        if [[ "$confirm_wt_cleanup" =~ ^[Yy]$ ]]; then
          echo "Removing worktree at '$current_worktree_path'..."
          local remove_force_flag=""
          if [[ "$force_ops" == true ]]; then remove_force_flag="--force"; fi
          git worktree remove $remove_force_flag "$current_worktree_path" || {
            echo "Warning: Failed to remove worktree '$current_worktree_path'." >&2
            echo "  Try 'git worktree remove --force ...' if it has untracked files." >&2
          }
        fi
      fi
    fi

    if [[ "$do_delete_remote_branch" == true ]]; then
      local confirm_remote_delete
      read -r 'confirm_remote_delete?Also delete remote branch origin/'"$current_branch"'? (y/N): '
      if [[ "$confirm_remote_delete" =~ ^[Yy]$ ]]; then
        echo "Deleting remote branch 'origin/$current_branch'..."
        git push origin --delete "$current_branch" || echo "Warning: Failed to delete remote branch." >&2
      fi
    fi

    if [[ "$do_delete_local_branch" == true ]]; then
      # Only delete local branch if worktree is gone or wasn't a separate worktree
      if [[ "$do_cleanup_worktree" == true || "$(realpath "$current_worktree_path")" == "$(realpath "$main_repo_path")" ]]; then
        local delete_flag="-d"
        if [[ "$force_ops" == true ]]; then delete_flag="-D"; fi
        echo "Deleting local branch '$current_branch'..."
        git branch "$delete_flag" "$current_branch" || echo "Warning: Failed to delete local branch '$current_branch'." >&2
      else
        echo "Info: Not deleting local branch '$current_branch' as its worktree was not removed."
      fi
    fi
  ) || echo "Warning: Some cleanup steps may have failed." >&2


  echo "---"
  echo "Process for '$current_branch' completed."
  echo "Target branch '$target_branch' is active in: $main_repo_path"
}
