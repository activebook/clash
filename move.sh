#!/bin/bash

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
echo "Summary:"
echo "  Moved: $moved"
echo "  Replaced: $replaced"
echo "  Skipped: $skipped"
