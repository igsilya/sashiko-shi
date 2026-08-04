#!/bin/bash
#
# sashiko-shi uninstaller
#
# Removes sashiko-shi agents, commands, and skills from a target
# repository's .opencode/ directory. Cleans up the reference from
# opencode.json but leaves subagent_depth (should be harmless).
#
# Usage: ./uninstall.sh <target-repo>

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target-repo>"
    exit 1
fi

TARGET="$(cd "$1" && pwd)"

echo "sashiko-shi uninstaller"
echo "======================="
echo ""
echo "Target: $TARGET"
echo ""

# Remove agents
removed=0
for agent in "$TARGET"/.opencode/agents/sashiko-shi*.md; do
    [ -f "$agent" ] || continue
    rm -f "$agent"
    removed=$((removed + 1))
done
echo "Removed $removed agents"

# Remove commands
removed=0
for cmd in "$TARGET"/.opencode/commands/sashiko-shi*.md; do
    [ -f "$cmd" ] || continue
    rm -f "$cmd"
    removed=$((removed + 1))
done
echo "Removed $removed commands"

# Remove skills
removed=0
for skill_name in kernel ovs ovn generic; do
    skill_dir="$TARGET/.opencode/skills/$skill_name"
    if [ -d "$skill_dir" ]; then
        rm -rf "$skill_dir"
        removed=$((removed + 1))
    fi
done
echo "Removed $removed skills"

# Clean up opencode.json reference
config_file="$TARGET/opencode.json"
if [ -f "$config_file" ] && command -v python3 &>/dev/null; then
    python3 - "$config_file" <<'PYEOF'
import json, sys

cfg_path = sys.argv[1]
with open(cfg_path) as f:
    cfg = json.load(f)

refs = cfg.get("references", {})
if "sashiko-shi" in refs:
    del refs["sashiko-shi"]
    if not refs:
        del cfg["references"]
    with open(cfg_path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("Removed sashiko-shi reference from opencode.json")
else:
    print("No sashiko-shi reference in opencode.json")
PYEOF
fi

# Remove output directory
if [ -d "$TARGET/.sashiko-shi" ]; then
    rm -rf "$TARGET/.sashiko-shi"
    echo "Removed .sashiko-shi/ output directory"
fi

echo ""
echo "Uninstallation complete."
echo ""
echo "Note: subagent_depth and provider timeout settings in opencode.json"
echo "were not reverted. You can remove them manually if no other tools"
echo "require them."
