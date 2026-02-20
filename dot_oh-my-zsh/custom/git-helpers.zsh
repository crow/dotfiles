# Git helper functions

# Updates the current git branch with the latest changes from remote
function gnew {
  local branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
  if [[ -n "$branch" ]]; then
    git fetch origin
    git reset --hard "origin/$branch"
  else
    echo "Not currently on any branch."
  fi
}

# Shows files changed between current branch and a base branch
function filediff {
    local base_branch=${1:-"next"}
    local current_branch=$(git rev-parse --abbrev-ref HEAD)

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Not in a git repository."
        return 1
    fi

    if [[ -z "$current_branch" ]]; then
        echo "Could not detect the current branch."
        return 1
    fi

    echo "Comparing branches: '$base_branch' with current branch '$current_branch'..."
    git diff --name-only "$base_branch"..."$current_branch"
}

# Applies a specific git stash
function popstash() {
    if [[ -n $1 && $1 =~ '^[0-9]+$' ]]; then
        git stash apply "stash@{$1}"
    else
        echo "Error: Please provide a valid numeric argument."
    fi
}

# Opens all files with merge conflicts in VS Code
function resolveall() {
    local files_with_conflicts=$(git diff --name-only --diff-filter=U)
    if [[ -n $files_with_conflicts ]]; then
        echo "Opening files with merge conflicts in Visual Studio Code..."
        for file in ${(f)files_with_conflicts}; do
            code --wait "$file"
        done
    else
        echo "No merge conflicts detected."
    fi
}

# Deletes files that git reports as deleted
function gdel() {
    git status | grep "deleted" | awk '{print $4}' | rm
}

# Cherry-picks last commit from testing branch
start_testing() {
    echo "Starting testing setup..."
    git fetch origin testing:testing
    local last_testing_commit=$(git log testing -1 --pretty=format:"%H")
    echo "Cherry-picking the last commit ($last_testing_commit) from 'testing' branch..."
    git cherry-pick $last_testing_commit
    if [ $? -eq 0 ]; then
        echo "Successfully cherry-picked the commit from the 'testing' branch!"
    else
        echo "Failed to cherry-pick the commit. Please resolve conflicts if any."
    fi
}

# Reverts testing commits and restores stash
stop_testing() {
    echo "Stopping testing and cleaning up..."
    git stash save "Testing stash"
    git fetch
    local testing_commits=$(git log HEAD...origin/testing --pretty=format:"%H")
    echo "Reverting commits from the 'testing' branch..."
    for commit in $testing_commits; do
        git revert --no-commit $commit
    done
    git commit -m "Revert testing commits"
    git stash pop
    echo "Testing stopped and environment cleaned up!"
}

# Interactive release tagging wizard
function releasewizard() {
    local projectName lastVersion newVersion

    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Not inside a Git repository."
        return 1
    fi

    projectName=$(basename "$(git rev-parse --show-toplevel)")
    lastVersion=$(git describe --tags `git rev-list --tags --max-count=1`)

    echo "Project: $projectName"
    echo "Last 10 commits:"
    git log -10 --oneline

    read "?Ready to release a new version? Type 'OK' to continue: " proceed
    if [[ $proceed != 'OK' ]]; then
        echo "Release process aborted."
        return 1
    fi

    echo "Last released version: $lastVersion"
    read "?Enter the next version number: " newVersion

    echo "You're about to release version $newVersion."
    read "?Confirm by typing 'YES': " confirm
    if [[ $confirm != 'YES' ]]; then
        echo "Release process aborted."
        return 1
    fi

    git tag -a "$newVersion" -m "version $newVersion" && git push origin "$newVersion"
    echo "Version $newVersion released successfully!"
}
