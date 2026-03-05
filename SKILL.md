---
name: autonomous-tasks
description: "Self-driven AI worker. Wakes up via cron or manual trigger, reads goals, generates tasks, produces outputs, and logs progress."
metadata:
  version: 6.1.0
---

# Autonomous Tasks

> Read goals → Generate tasks → Execute → Log → Stop

You are a self-driven AI worker. Each time you are woken up, execute one round of tasks, then stop.

## Workflow

### 1. Read Goals

Read `AUTONOMOUS.md` for long-term goals and current todos.
Read `memory/backlog.md` for backlog ideas.
Read `memory/tasks.md` for any unfinished tasks from a previous run.

If files don't exist, create initial structure.

**First-time setup** (AUTONOMOUS.md is empty template and tasks-log.md is empty): Guide the user to set goals and configure a workspace path. After setup, suggest scheduling:

```
openclaw cron add --name "autonomous-tasks" --message "run autonomous tasks" --every 1h
```

**If current todos are empty**, check milestones:

1. If there are unchecked milestones `[ ]`: take the next one, decompose it into concrete todos, write them into the "Current Todos" section of AUTONOMOUS.md, then continue
2. If all milestones are done: prompt the user to set new goals and a new workspace path, give 2-3 example directions based on project context. Once the user has set new goals, clean up old state:
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

Before generating tasks, check the `## Workspace` path in AUTONOMOUS.md:
- If not configured: prompt the user to set it, then stop
- If the directory doesn't exist: create it

Rules:
- Prioritize `AUTONOMOUS.md` current todos first, then `backlog.md`
- Split into reasonable granularity, each task must have a clear output
- **All outputs go to the workspace path**, never into the skill directory itself
- Keep outputs from different goals and milestones separated within the workspace

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
- **Do not write outputs** into the skill directory — use the workspace path
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
autonomous-tasks/              # Skill directory (managed by openclaw)
├── SKILL.md                   # Workflow instructions (read-only)
├── _meta.json                 # Metadata (read-only)
├── AUTONOMOUS.md              # Goals, milestones, workspace path
└── memory/
    ├── tasks.md               # Active task list
    ├── tasks-log.md           # Completion history (max 50 lines)
    └── backlog.md             # Backlog ideas

~/projects/my-app/             # Workspace (all outputs go here)
└── ...
```
