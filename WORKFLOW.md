# GlossyDesign Development Workflow

Version: Governance V2  
Last reviewed: 2026-08-27 (Asia/Bangkok)

## Roles

### Planner / Reviewer

Preferred: ChatGPT or another high-reasoning model.

Responsibilities:
- inspect current FE/BE behavior;
- identify the real problem;
- choose priority/risk;
- split work into bounded tasks;
- define acceptance criteria and exclusions;
- review final diff/contracts;
- decide the next task.

### Implementer

Preferred: Codex/coding agent. A smaller/lower-cost model is acceptable when the Planner has made the scope precise.

Responsibilities:
- implement only the assigned task;
- follow `AGENTS.md` and `PROJECT_RULES.md`;
- add/adjust tests;
- run verification;
- report changed files and remaining risk.

## Standard flow

1. **Analyze** — verify the issue against current source.
2. **Define task** — give it a stable TODO ID and one primary outcome.
3. **Define scope** — expected FE/BE area and explicit do-not-touch boundaries.
4. **Define acceptance** — observable pass/fail conditions.
5. **Implement** — smallest coherent change.
6. **Verify** — affected tests first, then lint/type/build appropriate to risk.
7. **Review diff** — reject unrelated edits or accidental generated files.
8. **Review contracts** — for cross-system work, compare FE request/response with BE controller/DTO/service.
9. **Choose Git path** — direct main only for explicitly approved low-risk work; otherwise branch + review/PR.
10. **Commit** — one task-oriented commit or a small logical series.
11. **Push / PR** — according to risk/task instruction.
12. **Update TODO** — move status and remove completed work from the active queue after durable evidence exists.

## Task sizing and phases

Bad:

> Fix payment system.

Good:

> P0-01A — Make `addPayment()` atomic without changing the existing successful response shape.

Classify executable implementation work by real scope/risk before choosing phases:

- **Small** — 1–3 phases.
- **Medium** — 4–7 phases.
- **Large** — 8–15 phases.
- If more than 15 meaningful phases are needed, split the work into smaller TODOs/epics.

A phase is a coherent execution slice with an observable outcome, not a time-box label. Each required phase should record scope, status, acceptance/exit criteria, verification, completion evidence, and the next action/phase. Do not split work into ceremonial phases merely to hit a count.

A good task specification contains:

```text
Task ID:
Problem:
Risk:
Task size: Small | Medium | Large
Scope:
Expected files/area:
Do not touch:
Phases:
  Phase NN — title
    Status:
    Scope:
    Acceptance / exit criteria:
    Verification:
    Evidence:
    Next:
Overall acceptance criteria:
Overall verification:
Git path:
```

For resumable automation, the active phase is execution truth. Resume an actionable `IN_PROGRESS` phase before starting a later phase. A TODO is `DONE` only after all required phases are `DONE` or explicitly approved `SKIPPED`, required verification passes, and required Git integration is complete.

## Recommended risk levels

### Low
- documentation;
- isolated presentation changes;
- narrow bug with no auth/money/schema impact.

### Medium
- non-financial API behavior;
- performance/refactor across several modules;
- compatibility cleanup.

### High
- auth/RBAC;
- deployment/runtime configuration;
- uploads with data-loss/security implications;
- tax document behavior;
- cross-repo contract migrations.

### Critical
- payment concurrency/idempotency;
- financial reconciliation;
- destructive financial data migration;
- credential compromise response.

Higher risk means smaller implementation steps, more explicit acceptance criteria, and stronger review/rollback requirements.

## TODO state machine

Allowed statuses:
- `OPEN`
- `IN_PROGRESS`
- `REVIEW`
- `BLOCKED`
- `DONE`

Use `DONE` only after required verification and durable commit/PR evidence. Periodically remove DONE items from active `TODO.md`; Git history and archived snapshots preserve history.

### Automated runner selection and continuation rules

For the Glossy Design ChatGPT Project only, every fresh `ทำต่อ` / `continue` / `resume` chat and every Native ChatGPT implementation continuation wake starts with the same bootstrap before selecting or mutating work:

1. Read `AGENTS.md`, `PROJECT_RULES.md`, `DECISIONS.md`, workspace-root `TODO.md`, and `docs/SCHEDULE_CONTINUATION_CONTEXT.md`.
2. Inspect active durable goals, phase/pending-step truth, blockers, tracked tasks, and lease/worker liveness.
3. Inspect Native ChatGPT Scheduled Task state and classify continuation health. Historical/disabled/Complete one-time tasks do not count as future coverage.
4. Resume a safe actionable `IN_PROGRESS` phase first; otherwise select the next safe approved `OPEN` phase/TODO.
5. Acquire the relevant durable goal lease before mutation; if another healthy worker owns it, do not compete.

This bootstrap is workspace-specific and must not be reused automatically for unrelated projects. `docs/SCHEDULE_CONTINUATION_CONTEXT.md` explains incidents and diagnostics; only rules promoted into active governance are normative.

- `REVIEW` is a review-gated state, not active implementation work. Automated TODO runs must skip `REVIEW` tasks and select the next safe actionable task instead.
- Do not modify source, add extra hardening/refactors, or re-run full verification for an unchanged `REVIEW` task unless there is new review feedback, explicit approval/instruction, a new test failure, or relevant branch/main changes.
- Use branch/main SHA fingerprints as a repeat-work guard. If the review branch HEAD and relevant `main` SHA(s) are unchanged from the last recorded review evidence, treat that task as `SKIP_REVIEW_UNCHANGED` for automated selection.
- An `IN_PROGRESS` task may be resumed only when there is actual unfinished implementation or verification work that can safely continue. For phased TODOs, inspect required phase status and resume the safe actionable `IN_PROGRESS` phase first; otherwise select the earliest/highest-priority safe required `OPEN` phase.
- Do not return `NO_ACTIONABLE_TASK` while an `IN_PROGRESS` TODO has a required safe approved `OPEN`/`IN_PROGRESS` phase. If every higher-priority task/phase is `DONE`, `BLOCKED`, `REVIEW`, `SKIPPED` with approved reason, or requires an unresolved business/policy decision, continue to the next safe actionable TODO. If none exists, report `NO_ACTIONABLE_TASK` rather than re-opening or repeatedly verifying gated work.
- New review feedback or approval may make a `REVIEW` task actionable again; record the triggering evidence before resuming it.
- A Native ChatGPT implementation wake should keep doing useful work through milestones, targeting roughly 20–25 minutes when the host/tool budget allows. A checkpoint is not itself a reason to stop.
- If safe actionable work remains when the wake must end, checkpoint the exact phase/progress/next action/evidence and create exactly one new Native ChatGPT one-time successor for approximately +5 minutes. A fired one-time task may become `Complete`; the chain continues through the already-created successor until no safe actionable work remains or a genuine owner gate/blocker is reached.
- Never use an hourly recurring implementation watchdog, Windows Task Scheduler, cron, shell timers, DOM automation, or a second local execution queue for this continuation chain. Never maintain more than one live successor for the same chain.

## Verification guidance

### Frontend

Typical progression:
1. focused test file;
2. `npm test`;
3. `npm run lint`;
4. `npm run build` for routing/build-impacting changes.

### Backend

Typical progression:
1. focused Jest spec;
2. `npm test`;
3. `npm run test:e2e` where the contract is affected;
4. `npm run lint`;
5. `npm run build`.

Concurrency/data-integrity tasks need an isolated/disposable database test strategy before claiming concurrency safety.

## Review checklist

- Does the change solve the stated problem instead of a nearby problem?
- Did any financial/security invariant get weaker?
- Are FE and BE contracts still aligned?
- Are retries/error paths safe?
- Are tests testing the regression rather than implementation details only?
- Is the Git diff task-scoped?
- Is documentation/TODO updated only with verified facts?
