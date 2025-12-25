#!/bin/bash

# Combined script: move files from Downloads and update/commit to GitHub
# Usage: ./move_and_update.sh

set -e  # Exit on error

echo "=== Moving files from Downloads ==="

src="$HOME/Downloads"
files="fast.txt ss.txt hysteria2.txt vmess.txt vless.txt trojan.txt anytls.txt tuic.txt ssr.txt"

echo "Moving specified files from $src to the current directory (overwriting if exists)..."

moved=0
replaced=0
skipped=0

for file in $files; do
    src_file="$src/$file"
    dest_file="./$file"

    if [ -f "$src_file" ]; then
        if [ -f "$dest_file" ]; then
            echo "Replacing: $file"
            ((replaced++))
        else
            echo "Moving: $file"
            ((moved++))
        fi
        mv "$src_file" "$dest_file"
    else
        echo "Skipped: $file (not found in $src)"
        ((skipped++))
    fi
done

echo ""
echo "Move Summary:"
echo "  Moved: $moved"
echo "  Replaced: $replaced"
echo "  Skipped: $skipped"

echo ""
echo "=== Updating Git repository ==="

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

echo ""
echo "=== Combined operation completed ==="