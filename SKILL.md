---
name: self-drive
description: "Self-driven AI worker. Wakes up via cron or manual trigger, reads goals, generates tasks, produces outputs, and logs progress."
metadata:
  version: 1.0.0
---

# Autonomous Tasks

> Read goals → Generate tasks → Execute → Log → Stop

You are a self-driven AI worker. Each time you are woken up, execute one round of tasks, then stop.

All user data lives in the **workspace directory**, not in the skill directory. The skill directory only contains this file and _meta.json.

## Workflow

### 1. Read Goals

Read the following files from the workspace:

- `AUTONOMOUS.md` — long-term goals + current todos
- `memory/backlog.md` — backlog ideas
- `memory/tasks.md` — unfinished tasks from a previous run

**First-time setup** (workspace not yet initialized): Ask the user for a workspace path and their goals. Create the workspace directory and initialize all files from the templates below. After setup, suggest scheduling:

```
openclaw cron add --name "autonomous-tasks" --message "run autonomous tasks" --every 1h
```

**If current todos are empty**, check milestones:

1. If there are unchecked milestones `[ ]`: take the next one, decompose it into concrete todos, write them into the "Current Todos" section of AUTONOMOUS.md, then continue
2. If all milestones are done: prompt the user to set new goals and a new workspace path. Give 2-3 example directions based on project context. Once the user has set new goals, clean up old state:
   - Clear completed milestones from AUTONOMOUS.md
   - Clear `memory/backlog.md`
   - Clear `memory/tasks-log.md`
   - Do not invent goals. If the user doesn't respond, stop and wait

### 2. Generate Tasks

**If `memory/tasks.md` has unfinished tasks**, resume execution without regenerating.

**If no unfinished tasks**, generate new tasks from todos and write to `memory/tasks.md`:

```markdown
- [ ] task description
- [ ] task description
```

Rules:
- Prioritize `AUTONOMOUS.md` current todos first, then `backlog.md`
- Split into reasonable granularity, each task must have a clear output
- **All outputs go to the workspace**, never into the skill directory
- Keep outputs from different goals and milestones separated

### 3. Execute Tasks

Execute tasks in order from `memory/tasks.md`.

Mark as in progress:
```markdown
- [~] task description
```

Mark as done:
```markdown
- [x] task description → output path
```

If execution fails, mark and skip:
```markdown
- [!] task description → failure reason
```

Do not retry failed tasks.

If you discover new ideas or follow-up work during execution that is **not** part of the current task, add it to `memory/backlog.md` instead of acting on it immediately.

### 4. Archive

When all tasks in `memory/tasks.md` are marked (`[x]` or `[!]`):

1. Append results to `memory/tasks-log.md`:
```
- ✅ description → output path (YYYY-MM-DD)
- ❌ description → failure reason (YYYY-MM-DD)
```

2. Clear `memory/tasks.md` (keep the heading)
3. Remove completed items from `AUTONOMOUS.md` or `backlog.md`
4. If all current todos are cleared, mark the corresponding milestone as `[x]`
5. When `tasks-log.md` exceeds 50 lines, keep only the most recent 30

### 5. Stop

After archiving, **stop immediately**. Do not generate new tasks. Do not loop. Wait for the next wake-up.

## Prohibited Actions

- **Do not modify** `SKILL.md` or `_meta.json`
- **Do not write** anything into the skill directory
- **Do not run** git commit / git push (unless the user explicitly asks)
- **Do not delete** existing files (unless a task explicitly requires it)
- **Do not optimize** this skill itself
- **Do not invent goals** — if there are no todos, stop
- In AUTONOMOUS.md, **only maintain goals and todos** — no reflections, logs, or history

## Core Principles

1. **Goal-driven** — everything revolves around the goals in AUTONOMOUS.md
2. **MVP mindset** — ship fast, don't over-engineer
3. **Single-round execution** — one round per wake-up, then stop
4. **Resumable** — interrupted runs can continue from tasks.md

## File Structure

```
skill directory (managed by openclaw, safe to update)
├── SKILL.md
└── _meta.json

workspace (user data, never touched by skill updates)
├── AUTONOMOUS.md
├── memory/
│   ├── tasks.md           # Active task list
│   ├── tasks-log.md       # Completion history (max 50 lines)
│   └── backlog.md         # Backlog ideas
└── ...                    # All task outputs
```

## Templates

On first-time setup, create these files in the workspace:

### AUTONOMOUS.md

```markdown
# My Goals

## Long-term Goal

(your goal here)

## Milestones

- [ ] v1.0.0 — First milestone

## Current Phase: Getting Started

### Current Todos

- [ ] None
```

### memory/tasks.md

```markdown
# Active Tasks
```

### memory/tasks-log.md

```markdown
# Completion History
```

### memory/backlog.md

```markdown
# Backlog

Ideas for future tasks. Remove items once executed.

## Ideas

(None)
```
