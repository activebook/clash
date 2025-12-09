# Lightweight script to commit and sync modified files to GitHub
# Usage: ./update.sh

set -e  # Exit on error

# Navigate to the repository directory
cd "$(dirname "$0")"

echo "🔍 Checking for modified files..."

# Fetch latest from remote
git fetch

# Check if there are any modified files (tracked files only)
if ! git diff --quiet --exit-code; then
    echo "📝 Found modified files:"
    git status --short | grep "^ M"
    
    # Stage only modified files (not new/untracked files)
    git add -u
    
    # Commit with simple message
    echo "💾 Committing changes..."
    git commit -m "Update"
fi

# Check if we are behind remote
if [ $(git rev-list HEAD..@{u} --count) -gt 0 ]; then
    echo "📥 Pulling updates from GitHub..."
    git pull --rebase
fi

# Check if we are ahead, push
if [ $(git rev-list @{u}..HEAD --count) -gt 0 ]; then
    echo "🚀 Pushing to GitHub..."
    git push
    echo "✅ Successfully synced to GitHub!"
else
    echo "✨ Everything is up to date!"
fi

