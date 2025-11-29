#!/bin/bash

# Lightweight script to commit and sync modified files to GitHub
# Usage: ./update.sh

set -e  # Exit on error

# Navigate to the repository directory
cd "$(dirname "$0")"

echo "🔍 Checking for modified files..."

# Check if there are any modified files (tracked files only)
if ! git diff --quiet --exit-code; then
    echo "📝 Found modified files:"
    git status --short | grep "^ M"
    
    # Stage only modified files (not new/untracked files)
    git add -u
    
    # Commit with simple message
    echo "💾 Committing changes..."
    git commit -m "Update"
    
    # Push to remote
    echo "🚀 Pushing to GitHub..."
    git push
    
    echo "✅ Successfully updated and synced to GitHub!"
else
    echo "✨ No modified files to commit. Everything is up to date!"
fi
