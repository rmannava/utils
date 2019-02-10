#!/bin/bash
# deletes all screenshots from the Pictures folder
for f in ~/Pictures/Screenshot*.png; do
    if [ -e "$f" ]
    then
        rm "$f"
        echo "Removed $f"
    fi
done
echo "Screenshots removed"
