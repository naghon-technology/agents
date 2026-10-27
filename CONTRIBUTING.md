# Agent authoring standard

Every agent in `agents/` follows ONE standard. Everything is written in **English** for
precision and portability.

## Frontmatter — exact field order and style

```yaml
---
name: <kebab-case, matches the filename>
description: <one single-line paragraph. Say WHAT it does and WHEN to route to it.
  Keep cues like "Use PROACTIVELY" / "MUST BE USED" when they help auto-selection.
  Mention the sibling agents it coordinates with.>
tools: [Read, Grep, Glob, Bash]   # OMIT this line for full-access builders
model: opus | sonnet | haiku
---
```

Rules:
- Field order is always: `name`, `description`, `tools` (optional), `model`.
- `tools` is a YAML flow array with **unquoted** identifiers: `[Read, Grep, Glob, Bash]`.
- **Builders** (that write code, run tools, delegate) OMIT `tools` → they inherit all tools.
- **Read-only reviewers/analysts** list a restricted `tools` set (least privilege).
- `description` on ONE line. Never use folded scalars (`>`) or multi-line descriptions.

## Model assignment
- All agents currently pin `model: claude-opus-5` (highest quality across the board).
- To trade cost/speed on a specific agent, drop it to `sonnet` or `haiku` — but the
  default for this team is Opus 5 everywhere.

## Body structure (unified)

```
# <Agent Title>

<One identity sentence: who you are and the one thing you own.>

## When you own the task            (builders)  — or —  ## Mission (reviewers/specialists)
## How you work                     (numbered, concrete, ordered steps; bias to verification)
## What you look for                (reviewers/analysts only: checklist by category)
## Output format                    (reviewers/analysts only: file:line, severity, impact, fix)
## Non-negotiables                  (hard rules and anti-patterns; secrets in env only)
## Team integration                 (respond in English; knowledge/; /retro; coordinate with siblings)
```

## Quality bar ("best in the world")
- **Routing clarity**: the `description` alone tells the orchestrator when to pick this agent.
- **Concrete over vague**: steps name real commands/artifacts.
- **Verification bias**: nothing is "done" until proven by running it.
- **Scope discipline**: do only what the role owns; hand off the rest; state assumptions and what was skipped.
- **Adversarial where it matters**: reviewers try to break things, not rubber-stamp.
- **No noise**: never include a "Prompt Defense Baseline" block.

## Length
- Builders/orchestrators: ~35–55 lines.
- Reviewers/specialists: ~50–90 lines (the checklist + output format earn the length).

## After adding or editing
```bash
grep -h '^name:' agents/*.md | sort | uniq -d   # unique names (must print nothing)
bash install.sh                                 # relink into ~/.claude
```
Restart Claude Code and verify with `/team` (or `ls -l ~/.claude/agents`).
