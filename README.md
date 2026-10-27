# Claude Code super-team of agents

A **single team of specialists** with shared method and memory across ALL your
projects — while each project stays sovereign over its own conventions.

- **Shared layer** (team, standards, learnings, skills) lives here and installs at the
  user level (`~/.claude`). It applies in every project and every terminal.
- **Project-specific layer** lives in each repo's `CLAUDE.md` and `.claude/`. It takes
  priority and never bleeds into another project.
- This folder is the **source of truth** (versioned in git). The installer links it into
  `~/.claude` with symlinks: you edit here and it propagates on its own.

---

## Install

```bash
cd ~/projects/claude-code/team
bash install.sh          # or: bash install.sh --dry-run  to preview what it would do
```

Restart Claude Code. Verify with `/agents` and `/memory`.

`--dry-run` is a rehearsal: it prints exactly what the installer *would* do (which
symlinks it would create or prune) **without writing anything**.

`--external` also installs third-party skill packs via `npx skills` (currently
`heygen-com/hyperframes`: HTML → video, live slideshows, media). They're managed upstream
(lock file in `~/.agents/.skill-lock.json`) instead of vendored here; update them with
`npx skills update -g`. Flags combine: `bash install.sh --external --dry-run`.

The installer is **idempotent**: re-run it whenever you add or remove something. It links
new files and prunes dangling symlinks for anything you deleted.

---

## The team

23 agents in two tiers (11 Core + 12 Specialists) + 5 commands. Everything is authored in
**English** for precision and portability.

### Core Squad — build end-to-end (delegate a whole feature)
| Agent | For |
|---|---|
| `tech-lead` | Orchestrates large/ambiguous tasks, plans and delegates. |
| `architect` | System design, structure, technical trade-offs. |
| `fullstack-dev` | End-to-end feature implementation. |
| `ai-engineer` | LLMs, prompts, voice/chat agents, RAG, AI integrations. |
| `ml-engineer` | Computer vision, models, data pipelines. |
| `qa-engineer` | Tests, edge cases, verification. |
| `ux-designer` | Flows, experience, information architecture. |
| `ui-designer` | Visual interface, components, design systems. |
| `creative-frontend` | Distinctive, animated, high-craft sites (anime.js, Motion, Kokonut/Bklit UI). |
| `devops-engineer` | Deploy, CI/CD, infra, secrets, observability. |
| `code-reviewer` | Code and security review before merge. |

### Specialists — single focus, invoked on demand
| Agent | For |
|---|---|
| `planner` | Detailed, phased plan for complex features/refactors. |
| `security-reviewer` | Security audit (secrets, injection, authz, OWASP). |
| `silent-failure-hunter` | Swallowed errors, dangerous fallbacks, propagation. |
| `performance-optimizer` | Bottlenecks, memory, bundle, runtime. |
| `database-reviewer` | SQL, migrations, schema, query performance (Postgres). |
| `a11y-architect` | Accessibility WCAG 2.2 (web and native). |
| `seo-specialist` | Technical SEO, on-page, structured data, Core Web Vitals. |
| `tdd-guide` | Test-first discipline, coverage. |
| `typescript-reviewer` | Deep TS/JS review. |
| `python-reviewer` | Deep Python review (PEP 8, typing, security). |
| `refactor-cleaner` | Dead code, duplicates, consolidation. |
| `code-simplifier` | Simplify and clarify without changing behavior. |

### Commands
| Command | For |
|---|---|
| `/council` | Advisory panel (CEO/CFO/CTO/… + Red Team + Chairman) for strategic decisions. Deliberates in parallel with real subagents. |
| `/preflight` | Parallel pre-merge check: qa + code-reviewer + security + the language specialist → one verdict. |
| `/retro` | Retrospective: extract learnings and decide where they go (team vs. project). |
| `/handoff` | Clean handoff of the current state to resume later or in another terminal. |
| `/team` | Shows the team and commands, and suggests who to delegate to. |

---

## Usage best practices

- **Start with `tech-lead`** on large or ambiguous tasks: it decomposes and delegates to
  the right specialist. For the full map, run `/team`.
- **Close with `qa-engineer` + `code-reviewer`** (or just `/preflight`) before calling
  anything done. Nothing is assumed done without running it.
- **Reviewers don't edit**: they review and recommend; fixes go to `fullstack-dev`.
- **Strategic or hard-to-reverse decisions** → `/council`.
- **When you finish, run `/retro`**: promote reusable learnings to the shared knowledge.
  That's the bridge between projects (see below).

---

## How learnings are shared (the key point)

1. You work in any project with the team.
2. When you finish something, you run `/retro`.
3. The learning is classified:
   - **Reusable** across projects → `knowledge/lessons.md` (or `playbook.md` / `stack.md`).
   - **Project-specific** → that repo's `CLAUDE.md`.
4. Since `knowledge/` is imported by the global rules (`rules/00-team.md`), every project
   sees the new lessons in the next session.

Claude Code's native auto-memory stays per-repo (independent). The bridge between projects
is this shared `knowledge/`.

---

## Structure

```
team/
├── agents/          23 agents (11 Core Squad + 12 Specialists) — 1 .md file each
├── rules/           global standards loaded into every project
├── commands/        /council · /preflight · /retro · /handoff · /team
├── knowledge/       shared knowledge: playbook.md · lessons.md · stack.md
├── skills/          design + creative-web skills (creative-web, ui-ux-pro-max, design-system, ui-styling, …)
├── CONTRIBUTING.md  the authoring standard for agents
└── install.sh       links everything into ~/.claude
```

All agents follow a **single authoring standard**: normalized frontmatter
(`name`, `description`, `tools` optional, `model`), a uniform body structure, a bias to
verification, and explicit integration with the shared knowledge and `/retro`.
See `CONTRIBUTING.md`.

---

## Adding and maintaining things

- **New agent** → create a `.md` in `agents/` following the standard, re-run `install.sh`.
- **New skill** → drop the folder in `skills/`, re-run `install.sh`.
- **New command** → `.md` in `commands/`.
- **New global rule** → `.md` in `rules/`.
- **Delete something** → remove it from the source folder and re-run `install.sh` (it prunes the dangling symlink).

Each agent `.md` must have a unique `name:` in its frontmatter. Quick duplicate check:

```bash
grep -h '^name:' agents/*.md | sort | uniq -d   # must print nothing
```

---

## Security notes

- Secrets always in environment variables; never in git and never in `NEXT_PUBLIC_*`.
