#!/usr/bin/env bash
# Push all git submodules with a generic work-in-progress commit

set -euo pipefail

# Get current date
DATE=$(date +"%Y-%m-%d")

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Pushing all submodules...${NC}"
echo "Date: $DATE"
echo ""

# Get all submodule paths
SUBMODULES=$(git config --file .gitmodules --name-only --get-regexp path | sed 's/submodule\.\(.*\)\.path/\1/')

if [ -z "$SUBMODULES" ]; then
    echo -e "${YELLOW}No submodules found.${NC}"
    exit 0
fi

# Loop through each submodule
while IFS= read -r submodule; do
    SUBMODULE_PATH=$(git config --file .gitmodules --get "submodule.$submodule.path")
    
    echo -e "${YELLOW}Processing submodule: $submodule${NC}"
    echo "Path: $SUBMODULE_PATH"
    
    # Enter the submodule directory
    cd "$SCRIPT_DIR/$SUBMODULE_PATH"
    
    # Check if there are changes to commit
    if ! git diff-index --quiet HEAD --; then
        echo -e "${GREEN}  ✓ Found changes${NC}"
        
        # Stage all changes
        git add -A
        
        # Commit with the generic message
        COMMIT_MSG="work in progress - $DATE"
        git commit -m "$COMMIT_MSG"
        echo -e "${GREEN}  ✓ Committed: '$COMMIT_MSG'${NC}"
        
        # Push to origin
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        git push origin "$CURRENT_BRANCH"
        echo -e "${GREEN}  ✓ Pushed to origin/$CURRENT_BRANCH${NC}"
    else
        # Check for untracked files
        if [ -n "$(git ls-files --others --exclude-standard)" ]; then
            echo -e "${GREEN}  ✓ Found untracked files${NC}"
            
            # Stage all changes (including untracked)
            git add -A
            
            # Commit with the generic message
            COMMIT_MSG="work in progress - $DATE"
            git commit -m "$COMMIT_MSG"
            echo -e "${GREEN}  ✓ Committed: '$COMMIT_MSG'${NC}"
            
            # Push to origin
            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            git push origin "$CURRENT_BRANCH"
            echo -e "${GREEN}  ✓ Pushed to origin/$CURRENT_BRANCH${NC}"
        else
            echo -e "${YELLOW}  → No changes to commit${NC}"
        fi
    fi
    
    echo ""
    
    # Return to the main directory
    cd "$SCRIPT_DIR"
done <<< "$SUBMODULES"

echo -e "${GREEN}Done!${NC}"
