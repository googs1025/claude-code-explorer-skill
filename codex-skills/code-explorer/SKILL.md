---
name: "code-explorer"
description: "Deeply read and explain unfamiliar codebases. Use when Codex needs to explain a file or module, trace a function or request flow, map a project's architecture, clarify design intent, or review which parts of the code can be improved or extended. 适用于：解释一个文件或模块是做什么的、追踪函数或请求的执行流程、梳理项目架构、说明为什么这样设计、分析一段代码的核心逻辑，或评估哪些部分可以优化、重构、改进或扩展。"
---

# Code Explorer

Use this skill to understand unfamiliar code efficiently and explain it in plain language. It supports both English and Chinese requests. Default to understanding first. Only switch to improvement mode when the user explicitly asks for improvements, optimizations, risks, or feature ideas.

## Skill root

- Treat the directory containing this `SKILL.md` as `SKILL_ROOT`.
- Resolve bundled files relative to `SKILL_ROOT`, not the workspace root.
- When shell helpers are useful, run them via `SKILL_ROOT/scripts/...`.
- If that path cannot be resolved, load `error-handling.md` and continue with manual inspection instead of stopping.

Helper commands:

```bash
bash "$SKILL_ROOT/scripts/detect_lang.sh"
bash "$SKILL_ROOT/scripts/find_entry.sh" <lang>
bash "$SKILL_ROOT/scripts/git_context.sh" [target]
```

## Step 0: Pick the analysis mode

Choose the mode automatically based on the user's request:

| Mode | Trigger | Behavior |
|------|---------|----------|
| Quick mode | Single function, variable, or narrow question | Answer directly without the full four-phase flow |
| Standard mode | One file or one module | Run Phase 1-4 with the standard output structure |
| Deep mode | Whole project, architecture, multi-module relationships | Finish Phase 1, then confirm scope before going deeper |
| Suggestion mode | Explicit asks for improvements, optimization, risks, or feature ideas | Reuse Phase 1 and selective Phase 2, then output structured suggestions |

Mode boundary:
- Quick, standard, and deep modes are for understanding code. Do not proactively give optimization or feature suggestions there.
- Suggestion mode is only for explicit improvement requests.

## Step 1: Run helper scripts

Run the bundled scripts when they materially speed up the analysis:

1. Detect the language with `scripts/detect_lang.sh`
2. Find likely entry points with `scripts/find_entry.sh <lang>`
3. Gather Git context with `scripts/git_context.sh [target]`

If any helper fails, load `error-handling.md` and fall back to manual inspection.

## Step 2: Load language guidance selectively

After language detection, load only the relevant language guide:

- Go -> `lang/go.md`
- Python -> `lang/python.md`
- JavaScript/TypeScript -> `lang/javascript.md`
- Other languages -> skip language-specific guidance and use the generic workflow

Do not load language guides when:
- The request is quick mode
- The user only wants one narrow dimension such as data flow or callers
- The task is not about code semantics, such as a pure directory or dependency overview

For languages without a guide, fall back to:
- Search for likely entry points such as `main`, `init`, `bootstrap`, `start`, or `run`
- Read dependency files such as lockfiles, `*.toml`, `*.gradle`, `Makefile`, or similar
- Infer architecture from directory names such as `src/`, `lib/`, `pkg/`, `cmd/`, `service/`, `internal/`

## Step 3: Four-phase analysis workflow

### Phase 1: Macro scan

Goal: build the project map quickly without diving into implementation.

1. Identify the tech stack, preferably with the helper scripts
2. Scan the top-level directory structure
3. Read only the most relevant dependency files
4. Infer the high-level architecture

Deep mode rule:
- After Phase 1, ask the user which modules or flows to focus on before reading more code.

Parallelism rule:
- If the environment supports delegation and the user explicitly allows subagents, parallelize independent module scans or call-chain traces.
- Otherwise stay local and serial.

Budget rule:
- Keep Phase 1 within 5 files and prefer signatures, comments, and manifests.

### Phase 2: Trace the critical path

Goal: follow one data flow or control flow at a time.

1. Lock onto the target function, class, module, or request path
2. Search upward for callers and entry points
3. Search downward for callees and dependent components
4. Track how key objects are transformed and passed across modules

Execution rules:
- Search precisely before reading
- Read targeted slices rather than full files
- Prefer signatures and comments first, then implementation only when needed
- If the likely scope exceeds 10 files, ask the user whether to continue, narrow scope, or split the work

### Phase 3: Abstract and visualize

1. Rewrite the core logic as 5-10 steps of pseudocode or structured prose
2. Include at least one ASCII diagram chosen for the situation:
   - module or architecture diagram
   - request or call sequence diagram
   - state transition diagram
   - inheritance or ownership tree
3. Identify useful patterns or anti-patterns

### Phase 4: Synthesize

1. Summarize the core function in one sentence
2. Explain the design intent, not just the mechanics
3. Call out real risks or complexity points
4. Add Git evolution context when available

## Step 4: Suggestion mode

When the user explicitly asks for improvements, load `suggestion-mode.md` and follow its priority and output rules.

## Output format

Quick mode:

```markdown
**[function or symbol]** - [one-sentence explanation]

Core logic:
1. ...
2. ...

Watch-outs: [if any]
```

Standard and deep modes:

```markdown
## Core Summary
[one sentence, at most 50 characters in Chinese or similarly compact in English]

## Diagram
[ASCII diagram, required]

## Logic Breakdown
**Entry point**: `path:symbol`

**Core flow**:
1. ...
2. ...
3. ...

**Data flow**: `A` -> `B` -> `C`

## Deep Insights
- **Design intent**: ...
- **Key dependencies**: ...
- **Git context**: ...
- **Watch-outs**: ...

## Next Questions
1. ...
2. ...

## Analysis Notes
[Mention any delegated or parallel work here when used]
```

Suggestion mode:
- Follow `suggestion-mode.md`

## Constraints

- Do not give optimization or feature suggestions in quick, standard, or deep mode unless the user asked for them
- Do not paste long code blocks; keep quoted snippets under 15 lines
- Do not read large files blindly; prefer targeted reads
- Always include at least one ASCII diagram in standard and deep modes
- Emit a short checkpoint summary after each phase
- Prefer explaining why over merely restating what
- If the context grows large, load `context-mgmt.md` and actively reduce scope

## Never do these things

- Never dive into a random function before building enough architectural context
- Never read a large file wholesale when a precise search can narrow the slice
- Never dump source code instead of explaining it
- Never juggle too many independent call chains at once; finish one path cleanly, then move to the next
- Never let a helper-script failure stop the analysis

## Recovery guidance

- Load `error-handling.md` when helper scripts fail, paths cannot be resolved, or the target cannot be found
- Load `context-mgmt.md` when file count or token usage starts getting large
