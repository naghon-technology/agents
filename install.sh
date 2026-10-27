#!/usr/bin/env bash
# Install the super-team into ~/.claude via symlinks (source of truth = this folder).
# Re-run this script whenever you add/remove agents, rules, commands, or skills.
#
# Usage:
#   bash install.sh            # install / update
#   bash install.sh --dry-run  # show what it would do, without touching anything
#   bash install.sh --external # also install/update third-party skill packs (needs network + npx)
set -euo pipefail

DRY_RUN=0
EXTERNAL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=1 ;;
    --external) EXTERNAL=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# Third-party skill packs, managed by `npx skills` (lock file: ~/.agents/.skill-lock.json).
# Not vendored in this repo so they stay updatable from upstream.
EXTERNAL_SKILLS=(
  "heygen-com/hyperframes"   # HyperFrames: HTML -> video, slideshows, media
)

TEAM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Items that are never linked (FS junk / leftover skill git dirs).
IGNORE=(".git" ".DS_Store" ".gitignore")

run() { if [ "$DRY_RUN" = 1 ]; then echo "    [dry-run] $*"; else eval "$@"; fi; }

echo "==> Installing the super-team into $CLAUDE_DIR"
echo "    Source: $TEAM_DIR"
[ "$DRY_RUN" = 1 ] && echo "    (dry-run mode: nothing is written)"
echo

linked=0
pruned=0

for sub in agents rules commands skills; do
  [ -d "$TEAM_DIR/$sub" ] || continue
  run "mkdir -p \"$CLAUDE_DIR/$sub\""

  # 1) Link every item from the source.
  for item in "$TEAM_DIR/$sub"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    skip=0
    for ig in "${IGNORE[@]}"; do [ "$name" = "$ig" ] && skip=1; done
    [ "$skip" = 1 ] && continue
    run "ln -sfn \"$item\" \"$CLAUDE_DIR/$sub/$name\""
    echo "    linked  $sub/$name"
    linked=$((linked + 1))
  done

  # 2) Prune dangling symlinks that pointed into this folder (removed items).
  if [ -d "$CLAUDE_DIR/$sub" ]; then
    for link in "$CLAUDE_DIR/$sub"/*; do
      [ -L "$link" ] || continue
      target="$(readlink "$link")"
      case "$target" in
        "$TEAM_DIR/"*) [ -e "$link" ] || { run "rm -f \"$link\""; echo "    pruned  $sub/$(basename "$link")"; pruned=$((pruned + 1)); } ;;
      esac
    done
  fi
done

if [ "$EXTERNAL" = 1 ]; then
  echo
  echo "==> Installing external skill packs (npx skills, global)"
  for pkg in "${EXTERNAL_SKILLS[@]}"; do
    run "npx -y skills add \"$pkg\" -g -y"
    echo "    added   $pkg"
  done
fi

echo
echo "==> Done. Linked: $linked · Pruned: $pruned"
[ "$DRY_RUN" = 1 ] && exit 0
echo "    Restart Claude Code so it picks up agents, rules, commands, and skills."
echo "    Verify with:  /team   ·   /memory   ·   ls -l ~/.claude/agents"
