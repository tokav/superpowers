#!/bin/bash
#
# install-opencode.sh
# Installs/updates superpowers for OpenCode
#
# Usage:
#   ./install-opencode.sh            # Install or update
#   ./install-opencode.sh --uninstall # Remove all superpowers symlinks
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_DIR="${HOME}/.config/opencode"
EXPECTED_DIR="${OPENCODE_DIR}/superpowers"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
UNINSTALL=false
if [[ "${1:-}" == "--uninstall" ]]; then
    UNINSTALL=true
fi

# Helper: check if symlink points to our project
points_to_superpowers() {
    local link="$1"
    local target
    target=$(readlink "$link" 2>/dev/null || true)
    [[ "$target" == *"superpowers/"* || "$target" == *"superpowers/skills/"* || "$target" == *"superpowers/agents/"* || "$target" == *"superpowers/commands/"* ]]
}

# Helper: remove symlinks pointing to superpowers
cleanup_superpowers_symlinks() {
    local target_dir="$1"
    local count=0

    if [[ ! -d "$target_dir" ]]; then
        return
    fi

    for link in "$target_dir"/*; do
        if [[ -L "$link" ]] && points_to_superpowers "$link"; then
            echo "  - $(basename "$link")"
            rm "$link"
            ((count++)) || true
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "  (none)"
    fi
}

# Uninstall mode
if [[ "$UNINSTALL" == true ]]; then
    echo "Uninstalling superpowers from OpenCode..."
    echo ""

    echo "Removing skill symlinks..."
    cleanup_superpowers_symlinks "${OPENCODE_DIR}/skill"

    echo ""
    echo "Removing agent symlinks..."
    cleanup_superpowers_symlinks "${OPENCODE_DIR}/agent"

    echo ""
    echo "Removing command symlinks..."
    cleanup_superpowers_symlinks "${OPENCODE_DIR}/command"

    echo ""
    echo -e "${GREEN}Uninstall complete!${NC}"
    exit 0
fi

# Validate clone location
if [[ "${SCRIPT_DIR}" != "${EXPECTED_DIR}" ]]; then
    echo -e "${YELLOW}Warning: superpowers is not in the recommended location.${NC}"
    echo ""
    echo "  Current:     ${SCRIPT_DIR}"
    echo "  Recommended: ${EXPECTED_DIR}"
    echo ""
    echo "For optimal skill discovery, clone to the standard location:"
    echo ""
    echo "  git clone https://github.com/obra/superpowers.git ${EXPECTED_DIR}"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    echo ""
fi

echo "Installing superpowers for OpenCode..."
echo "Source: ${SCRIPT_DIR}"
echo "Target: ${OPENCODE_DIR}"
echo ""

# Create directories
mkdir -p "${OPENCODE_DIR}/skill"
mkdir -p "${OPENCODE_DIR}/agent"
mkdir -p "${OPENCODE_DIR}/command"

# Helper: check for collisions
# Returns 0 if OK to proceed, exits with error if collision detected
check_collision() {
    local target_path="$1"
    local source_name="$2"
    local source_type="$3"  # skill, agent, or command

    if [[ -L "$target_path" ]]; then
        if points_to_superpowers "$target_path"; then
            # Symlink points to superpowers - OK to update
            return 0
        else
            # Symlink points elsewhere - collision!
            local current_target
            current_target=$(readlink "$target_path")
            echo ""
            echo -e "${RED}Error: Collision detected!${NC}"
            echo ""
            echo "  ${target_path}"
            echo "  Currently points to: ${current_target}"
            echo ""
            echo "Cannot install superpowers ${source_type} '${source_name}' - name already in use."
            echo ""
            echo "Options:"
            echo "  1. Remove the existing symlink manually"
            echo "  2. Rename superpowers/${source_type}s/${source_name} to avoid conflict"
            echo ""
            echo "Installation aborted."
            exit 1
        fi
    elif [[ -e "$target_path" ]]; then
        # Regular file exists - collision!
        echo ""
        echo -e "${RED}Error: Collision detected!${NC}"
        echo ""
        echo "  ${target_path}"
        echo "  Is a regular file (not a symlink)"
        echo ""
        echo "Cannot install superpowers ${source_type} '${source_name}' - file already exists."
        echo ""
        echo "Options:"
        echo "  1. Remove or rename the existing file"
        echo "  2. Rename superpowers/${source_type}s/${source_name} to avoid conflict"
        echo ""
        echo "Installation aborted."
        exit 1
    fi

    # Nothing exists - OK to create
    return 0
}

# Phase 1: Check all collisions BEFORE making any changes
echo "Checking for collisions..."

collision_found=false

# Check skills
for skill_dir in "${SCRIPT_DIR}/skills"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        target_path="${OPENCODE_DIR}/skill/${skill_name}"
        check_collision "$target_path" "$skill_name" "skill"
    fi
done

# Check agents
for agent in "${SCRIPT_DIR}/agents"/*.md; do
    if [[ -f "$agent" ]]; then
        agent_name=$(basename "$agent")
        target_path="${OPENCODE_DIR}/agent/${agent_name}"
        check_collision "$target_path" "$agent_name" "agent"
    fi
done

# Check commands
for cmd in "${SCRIPT_DIR}/commands"/*.md; do
    if [[ -f "$cmd" ]]; then
        cmd_name=$(basename "$cmd")
        target_path="${OPENCODE_DIR}/command/${cmd_name}"
        check_collision "$target_path" "$cmd_name" "command"
    fi
done

echo "  No collisions found."

# Phase 2: Clean stale symlinks (only those pointing to superpowers)
echo ""
echo "Cleaning stale symlinks..."

for dir in skill agent command; do
    target_dir="${OPENCODE_DIR}/${dir}"
    if [[ -d "$target_dir" ]]; then
        for link in "$target_dir"/*; do
            if [[ -L "$link" ]] && points_to_superpowers "$link" && [[ ! -e "$link" ]]; then
                echo "  - ${dir}/$(basename "$link") (stale)"
                rm "$link"
            fi
        done
    fi
done

# Phase 3: Create symlinks

# Link skills (entire directories)
echo ""
echo "Linking skills..."
for skill_dir in "${SCRIPT_DIR}/skills"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        ln -sfn "${skill_dir%/}" "${OPENCODE_DIR}/skill/${skill_name}"
        echo -e "  ${GREEN}✓${NC} ${skill_name}"
    fi
done

# Link agents
echo ""
echo "Linking agents..."
for agent in "${SCRIPT_DIR}/agents"/*.md; do
    if [[ -f "$agent" ]]; then
        agent_name=$(basename "$agent")
        ln -sf "$agent" "${OPENCODE_DIR}/agent/${agent_name}"
        echo -e "  ${GREEN}✓${NC} ${agent_name}"
    fi
done

# Link commands
echo ""
echo "Linking commands..."
for cmd in "${SCRIPT_DIR}/commands"/*.md; do
    if [[ -f "$cmd" ]]; then
        cmd_name=$(basename "$cmd")
        ln -sf "$cmd" "${OPENCODE_DIR}/command/${cmd_name}"
        echo -e "  ${GREEN}✓${NC} ${cmd_name}"
    fi
done

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Restart OpenCode to activate superpowers."
echo ""
echo "To update later:"
echo "  cd ${EXPECTED_DIR} && git pull && ./install-opencode.sh"
echo ""
echo "To uninstall:"
echo "  ${EXPECTED_DIR}/install-opencode.sh --uninstall"
