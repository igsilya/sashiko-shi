#!/bin/bash
#
# sashiko-shi installer
#
# Installs sashiko-shi agents, commands, and skills into a target
# repository's .opencode/ directory. Also patches the target's
# opencode.json to set subagent_depth and add a reference to the
# sashiko-shi clone (which auto-allows external directory access).
#
# Usage: ./install.sh [--provider=<name>]... <target-repo>
#
# Example:
#   ./install.sh /path/to/linux
#   ./install.sh --provider=google-vertex-anthropic /path/to/linux
#   ./install.sh --provider=anthropic --provider=openai /path/to/linux
#   ./install.sh .                    # install into current directory
#
# The --provider flag configures timeouts for the specified LLM provider
# to prevent stream hangs during long reviews. Can be specified multiple
# times for multiple providers.
#
# After updating sashiko-shi (git pull), re-run install.sh to update.
#
# Attribution:
#   Review protocol derived from Sashiko (Apache 2.0, The Linux Foundation)
#   Per-subsystem prompts from review-prompts (MIT, Chris Mason)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse options
PROVIDERS=()
MODEL=""
SMALL_MODEL=""
while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --provider=*)
            PROVIDERS+=("${1#--provider=}")
            shift
            ;;
        --model=*)
            MODEL="${1#--model=}"
            shift
            ;;
        --small-model=*)
            SMALL_MODEL="${1#--small-model=}"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [OPTIONS] <target-repo>"
            exit 1
            ;;
    esac
done

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [OPTIONS] <target-repo>"
    echo ""
    echo "Installs sashiko-shi into the target repository's .opencode/ directory."
    echo ""
    echo "Options:"
    echo "  --provider=<name>    Configure timeouts for the specified LLM provider."
    echo "                       Prevents stream hangs during long reviews."
    echo "                       Can be specified multiple times."
    echo ""
    echo "  --model=<id>         Model for analysis stages and series coordination."
    echo "  --small-model=<id>   Model for orchestrator, pre-screen, and planner."
    echo "                       Both --model and --small-model must be specified"
    echo "                       together. If neither is given, all agents inherit"
    echo "                       the default model."
    echo ""
    echo "Example:"
    echo "  $0 /path/to/net-next"
    echo "  $0 --provider=google-vertex-anthropic /path/to/net-next"
    echo "  $0 --provider=google-vertex-anthropic \\"
    echo "      --model=google-vertex-anthropic/claude-opus-4-6@default \\"
    echo "      --small-model=google-vertex-anthropic/claude-sonnet-4-6@default \\"
    echo "      /path/to/net-next"
    exit 1
fi

# Validate model flags
if [ -n "$MODEL" ] && [ -z "$SMALL_MODEL" ]; then
    echo "Error: --model requires --small-model"
    exit 1
fi
if [ -z "$MODEL" ] && [ -n "$SMALL_MODEL" ]; then
    echo "Error: --small-model requires --model"
    exit 1
fi

TARGET="$(cd "$1" && pwd)"

echo "sashiko-shi installer"
echo "====================="
echo ""
echo "Source:  $SCRIPT_DIR"
echo "Target:  $TARGET"
if [ ${#PROVIDERS[@]} -gt 0 ]; then
    echo "Providers: ${PROVIDERS[*]}"
fi
if [ -n "$MODEL" ]; then
    echo "Model:       $MODEL"
    echo "Small model: $SMALL_MODEL"
fi
echo ""

# Verify target is a git repo
if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: $TARGET is not a git repository"
    exit 1
fi

# Initialize submodule if needed
if [ ! -f "$SCRIPT_DIR/third_party/review-prompts/README.md" ]; then
    echo "Initializing review-prompts submodule..."
    git -C "$SCRIPT_DIR" submodule update --init --recursive
fi

# Create target directories
mkdir -p "$TARGET/.opencode/agents"
mkdir -p "$TARGET/.opencode/commands"
mkdir -p "$TARGET/.opencode/skills"

# Copy agents (sed substitution for path placeholders + optional model injection)
echo "Installing agents..."
installed_agents=0
for agent in "$SCRIPT_DIR"/agents/sashiko-shi*.md; do
    [ -f "$agent" ] || continue
    name=$(basename "$agent")
    if [ -n "$MODEL" ]; then
        # Orchestrator, prescreen, and planner use the small model.
        # Everything else (coordinator, all stages) uses the main model.
        case "$name" in
            sashiko-shi-orchestrator.md|sashiko-shi-prescreen.md|sashiko-shi-planner.md)
                agent_model="$SMALL_MODEL" ;;
            *)
                agent_model="$MODEL" ;;
        esac
        sed -e "s|{{SASHIKO_SHI_DIR}}|$SCRIPT_DIR|g" \
            -e "s|^steps: .*|&\nmodel: $agent_model|" \
            "$agent" > "$TARGET/.opencode/agents/$name"
        echo "  $name ($agent_model)"
    else
        sed "s|{{SASHIKO_SHI_DIR}}|$SCRIPT_DIR|g" "$agent" \
            > "$TARGET/.opencode/agents/$name"
    fi
    installed_agents=$((installed_agents + 1))
done
if [ -z "$MODEL" ]; then
    echo "  $installed_agents agents installed"
fi

# Copy command
echo "Installing commands..."
installed_commands=0
for cmd in "$SCRIPT_DIR"/commands/sashiko-shi*.md; do
    [ -f "$cmd" ] || continue
    name=$(basename "$cmd")
    cp "$cmd" "$TARGET/.opencode/commands/$name"
    installed_commands=$((installed_commands + 1))
done
echo "  $installed_commands commands installed"

# Generate skills (sed substitution for path placeholders)
echo "Installing skills..."
installed_skills=0
for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    skill_src="$skill_dir/SKILL.md"
    [ -f "$skill_src" ] || continue

    target_dir="$TARGET/.opencode/skills/$skill_name"
    mkdir -p "$target_dir"
    sed "s|{{SASHIKO_SHI_DIR}}|$SCRIPT_DIR|g" "$skill_src" > "$target_dir/SKILL.md"
    installed_skills=$((installed_skills + 1))
    echo "  $skill_name"
done
echo "  $installed_skills skills installed"

# Patch opencode.json in the target repo
echo "Configuring opencode.json..."
config_file="$TARGET/opencode.json"
if command -v python3 &>/dev/null; then
    python3 - "$config_file" "$SCRIPT_DIR" "${PROVIDERS[@]}" <<'PYEOF'
import json, sys, os

cfg_path = sys.argv[1]
sashiko_dir = sys.argv[2]
providers = sys.argv[3:]
changed = False

cfg = {}
if os.path.exists(cfg_path):
    with open(cfg_path) as f:
        cfg = json.load(f)

cfg.setdefault("$schema", "https://opencode.ai/config.json")

# Ensure subagent_depth >= 3 for OpenCode v1.
# The /sashiko-shi command runs the series coordinator as a subtask (depth 1),
# which invokes the orchestrator per commit (depth 2),
# which invokes stage subagents (depth 3).
if cfg.get("subagent_depth", 1) < 3:
    cfg["subagent_depth"] = 3
    changed = True
    print("  Set subagent_depth=3")
else:
    print("  subagent_depth already >= 3")


# Ensure subagent_depth >= 3 for OpenCode v2 that puts it under "experimental".
experimental = cfg.setdefault("experimental", {})
if experimental.get("subagent_depth", 1) < 3:
    experimental["subagent_depth"] = 3
    changed = True
    print("  Set experimental.subagent_depth=3")
else:
    print("  experimental.subagent_depth already >= 3")

# Add reference to sashiko-shi clone
# This auto-allows external directory access per OpenCode's design:
# "OpenCode automatically allows reference directories through its
#  external-directory permission boundary."
refs = cfg.setdefault("references", {})
ref = refs.get("sashiko-shi", {})
if isinstance(ref, str):
    ref = {"path": ref}
if ref.get("path") != sashiko_dir:
    refs["sashiko-shi"] = {
        "path": sashiko_dir,
        "description": "Sashiko-shi review prompts and analysis context",
        "hidden": True
    }
    changed = True
    print("  Added reference: sashiko-shi -> " + sashiko_dir)
else:
    print("  Reference sashiko-shi already configured")

# Configure provider timeouts to prevent stream hangs
timeouts = {
    "chunkTimeout": 60000,
    "headerTimeout": 120000,
    "timeout": 600000
}
for provider_name in providers:
    prov = cfg.setdefault("provider", {})
    p = prov.setdefault(provider_name, {})
    if isinstance(p, str):
        p = {}
        prov[provider_name] = p
    opts = p.setdefault("options", {})
    if isinstance(opts, str):
        opts = {}
        p["options"] = opts
    prov_changed = False
    for k, v in timeouts.items():
        if opts.get(k) != v:
            opts[k] = v
            prov_changed = True
    if prov_changed:
        changed = True
        print(f"  Configured timeouts for provider: {provider_name}")
    else:
        print(f"  Provider {provider_name} timeouts already configured")

if changed:
    with open(cfg_path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    print("  Updated " + cfg_path)
PYEOF
else
    echo "  WARNING: python3 not found, cannot patch opencode.json"
    echo "  Please manually add to $config_file:"
    echo '    "subagent_depth": 3,'
    echo '    "experimental": {"subagent_depth": 3},'
    echo '    "references": {"sashiko-shi": {"path": "'"$SCRIPT_DIR"'"}}'
fi

echo ""
echo "Installation complete."
echo ""
echo "Usage:"
echo "  cd $TARGET"
echo "  opencode"
echo "  /sashiko-shi SHA             # review the commit SHA"
echo "  /sashiko-shi HEAD~N..HEAD~M  # review a range of commits"
echo "  /sashiko-shi -N              # review the last N commits"
echo ""
echo "To uninstall: $SCRIPT_DIR/uninstall.sh $TARGET"
echo ""
echo "Note: You may want to add the following to $TARGET/.gitignore:"
echo "  .opencode/agents/sashiko-shi*.md"
echo "  .opencode/commands/sashiko-shi.md"
echo "  .opencode/skills/kernel/"
echo "  .opencode/skills/ovs/"
echo "  .opencode/skills/ovn/"
echo "  .opencode/skills/generic/"
echo "  .sashiko-shi/"
