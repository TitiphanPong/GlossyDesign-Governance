---
name: glossy-todo-runner
description: "Use when executing, continuing, or automatically selecting implementation work from the GlossyDesign workspace-root TODO.md, including scheduled TODO Runner runs, 'do the next TODO', or resuming a genuinely actionable backlog item. Select safe OPEN/IN_PROGRESS work, skip unchanged REVIEW/BLOCKED/decision-gated work, implement narrowly, verify fully, and integrate Git only under Governance V2."
---

# Glossy TODO Runner

Turn one safe actionable Governance V2 backlog item into verified durable implementation evidence. Do not reinterpret the backlog or bypass gates merely because the run is automated.

## Authority

- Workspace-root `TODO.md` is the sole active execution backlog.
- Read root `AGENTS.md`, `PROJECT_RULES.md`, relevant `DECISIONS.md`, `WORKFLOW.md`, and the selected TODO before editing.
- Current checked-out source is authoritative for current behavior.
- Frontend and Backend are separate Git repositories and require separate Git evidence when both change.
- Existing owner authorization for the automated TODO Runner applies only within the gates and risk boundaries defined by Governance V2.

## Startup and collision check

1. Check active durable goals/runners. Do not start a second implementation worker on overlapping scope.
2. Inspect Frontend and Backend branch, HEAD, and working-tree status. Preserve unrelated user WIP.
3. Read the current TODO states and any recorded branch/main SHA review evidence.
4. If the user explicitly named a TODO/task, prefer that task only if it is actionable and authorized. Otherwise use automatic selection rules below.

Never reset, clean, stash, overwrite, or discard unrelated WIP just to obtain a clean tree.

## Select one actionable task

Selection order for an automatic run:

1. Resume a genuine `IN_PROGRESS` task when unfinished implementation or verification work remains and no collision/blocker exists.
2. Otherwise select the highest-priority safe `OPEN` task whose dependencies and acceptance criteria are sufficiently defined.
3. Continue past higher-priority items that are `DONE`, `BLOCKED`, unchanged `REVIEW`, or decision/approval gated.
4. If no safe actionable item exists, return `NO_ACTIONABLE_TASK`. Do not reopen completed/gated work to fill a scheduled run.

`REVIEW` is not unfinished implementation. Resume a REVIEW item only when there is new review feedback, explicit approval/instruction, a new failure, or a relevant recorded branch/main SHA change that creates new actionable evidence.

Do not autonomously begin destructive migrations, unusual high-risk financial/security work, unresolved business-policy work, or another task whose governance explicitly requires fresh owner approval.

## Define the implementation boundary

Before editing:

- state the task ID and one primary outcome;
- identify expected FE/BE area and do-not-touch boundaries;
- verify the reported problem against current source;
- identify acceptance criteria and required verification;
- read relevant active decisions;
- if the task crosses FE/BE, inspect both sides of the contract before changing either side;
- choose the Git path required by task risk.

Use specialized skills when they fit the selected task. For example, use `glossy-pos-ui` for Glossy frontend UI/responsive/shared-component work, Playwright for relevant browser-visible regression checks, and security/deployment skills only when the task actually requires those workflows.

## Implement

- Make the smallest coherent change that satisfies the selected TODO.
- Do not expand the task into unrelated refactoring or legacy technical-debt cleanup.
- Prefer guarded lnwjud source edits (`edit_file`, `apply_patch`, `write_file`) over shell-based text rewriting.
- Preserve existing validation, authorization, tests, financial invariants, and FE↔BE compatibility unless the TODO explicitly and safely changes them.
- Bug fixes should add a focused regression test when practical.
- Do not delete source/data without explicit authorization.
- Never copy secrets into source, logs, docs, fixtures, prompts, or commits.

For financial tasks, Backend remains authoritative; preserve satang precision, immutable/auditable facts, retry/idempotency/atomicity invariants, and focused edge-case coverage required by governance.

## Verification ladder

Use narrow checks while developing, but all gates required by `PROJECT_RULES.md` must pass before automated integration.

1. Run the smallest relevant focused tests first.
2. Run repository ESLint using the configured zero-warning policy.
3. Run TypeScript/typecheck verification when available or required by build.
4. Run the production build.
5. Run configured quality checks relevant to the repository/task, such as UTF-8/mojibake, security/audit, dead-code, duplicate-code, coverage, or Sonar only when actually configured and executable.
6. Review `git diff --check` and the complete task-scoped diff.
7. Re-check FE↔BE request/response behavior after cross-repo changes.
8. For browser-visible behavior, run focused runtime/Playwright verification when appropriate and available.

A failed required gate blocks integration. Fix it and rerun affected gates, or leave the feature branch intact and report a blocker. Never claim an unavailable scanner or unexecuted check passed.

## Git integration

For automated implementation that is not an explicitly approved direct-to-main low-risk fix:

1. Work on a dedicated feature branch.
2. Keep Frontend and Backend commits separate when both repositories change.
3. Commit only task-related files after verification.
4. Push verified feature branch(es).
5. Merge into local `main` without rewriting history.
6. Verify the resulting `main` with critical/relevant checks.
7. Push `main` only after those checks pass.
8. Only then record durable completion evidence and move the TODO to `DONE`.

Do not force-push shared history. Do not push `main` when a required gate is failing. Direct-to-main is allowed only when the task/user explicitly permits the low-risk path.

## TODO and governance updates

- Mark work `IN_PROGRESS` only when implementation has actually begun.
- Mark `DONE` only after required verification and durable Git evidence exist.
- Use `BLOCKED` when an external dependency, decision, authorization, or unresolved safety issue prevents completion.
- Use `REVIEW` only for work genuinely waiting on review/approval rather than as a generic incomplete state.
- When one of the six root governance files changes, update the workspace-root active copy first and reconcile root → `GlossyDesign-Governance` mirror according to DEC-010/governance rules. Never edit the mirror first.

## Terminal outcomes

A run should end in one of these clear states:

- `DONE` — implementation, required verification, Git integration, and TODO evidence are complete;
- `REVIEW` — implementation is ready but explicitly requires review/approval before further action;
- `BLOCKED` — a real blocker prevents safe continuation;
- `NO_ACTIONABLE_TASK` — no safe executable backlog item exists;
- `IN_PROGRESS` — only when concrete unfinished work remains and a durable continuation mechanism owns the next step.

Do not leave long-running required work untracked. If a build/test legitimately outlives the current interaction and durable continuation is authorized, use the installed lnwjud scheduled-continuation workflow rather than pretending the task is complete.

## Completion report

Report:

- TODO ID/title and terminal status;
- files/repos changed;
- behavior and contract changes;
- tests/lint/type/build/quality/browser checks actually run and results;
- branch/commit/merge/push evidence actually performed;
- final Git status and unrelated pre-existing WIP;
- remaining risk, blocker, review need, or follow-up.

The runner succeeds by completing one bounded safe task correctly, not by maximizing the amount of code changed per scheduled run.
