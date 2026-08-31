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

## Task sizing

Bad:

> Fix payment system.

Good:

> P0-01A — Make `addPayment()` atomic without changing the existing successful response shape.

A good task specification contains:

```text
Task ID:
Problem:
Risk:
Scope:
Expected files/area:
Do not touch:
Acceptance criteria:
Verification:
Git path:
```

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

### Automated runner selection rules

- `REVIEW` is a review-gated state, not active implementation work. Automated TODO runs must skip `REVIEW` tasks and select the next safe actionable task instead.
- Do not modify source, add extra hardening/refactors, or re-run full verification for an unchanged `REVIEW` task unless there is new review feedback, explicit approval/instruction, a new test failure, or relevant branch/main changes.
- Use branch/main SHA fingerprints as a repeat-work guard. If the review branch HEAD and relevant `main` SHA(s) are unchanged from the last recorded review evidence, treat that task as `SKIP_REVIEW_UNCHANGED` for automated selection.
- An `IN_PROGRESS` task may be resumed only when there is actual unfinished implementation or verification work that can safely continue. Do not treat `REVIEW` as `IN_PROGRESS` merely because a feature branch still exists.
- If every higher-priority item is `DONE`, `BLOCKED`, `REVIEW`, or requires an unresolved business/policy decision, continue to the next safe actionable TODO. If none exists, report `NO_ACTIONABLE_TASK` rather than re-opening or repeatedly verifying gated work.
- New review feedback or approval may make a `REVIEW` task actionable again; record the triggering evidence before resuming it.

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
