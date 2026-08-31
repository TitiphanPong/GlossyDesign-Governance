# GlossyDesign Agent Instructions

Version: Governance V2  
Last reviewed: 2026-08-27 (Asia/Bangkok)

## Purpose

This file defines how Codex and other implementation agents work on GlossyDesign. Agents implement bounded tasks; they do not independently redefine product architecture, financial policy, or business rules.

## Project layout

- `GlossyPOS-Frontend` — Next.js + TypeScript + MUI
- `GlossyPOS-Backend` — NestJS + TypeScript + MongoDB
- Workspace-root governance — `AGENTS.md`, `PROJECT_RULES.md`, `TODO.md`, `ARCHITECTURE.md`, `WORKFLOW.md`, `DECISIONS.md`

The Frontend and Backend are separate Git repositories. The workspace root is currently not a Git repository.

## Governance location rule

- The six governance files at the workspace root are the active runtime/working copies and are the only copies agents should read for normal planning and execution.
- `GlossyDesign-Governance/` is the dedicated Git-versioned mirror of those six files, not a second runtime source of truth.
- Never choose between root and mirror copies by filesystem modified time. Content ownership is directional: edit the workspace-root copy first, then sync the same content into `GlossyDesign-Governance/` and version it there.
- If the root and mirror differ, treat the workspace-root copy as the active state, report governance drift, reconcile root → mirror, and do not run work from mixed copies.
- Do not edit the mirror first unless the explicit task is a recovery operation that has verified the intended canonical state.

## Source-of-truth order

1. Current checked-out source code tells you what the application actually does now.
2. Active entries in `DECISIONS.md` define approved durable product/technical decisions.
3. `PROJECT_RULES.md` defines non-negotiable engineering rules.
4. `ARCHITECTURE.md` is a verified snapshot and must carry current SHAs/date.
5. `TODO.md` contains active execution work only.
6. Files under `docs/archive/` are historical evidence only and must never be treated as current requirements.

If current source conflicts with an active decision/rule, do not silently reinterpret the rule. Report the conflict and implement only the assigned task.

## Before editing

1. Read `PROJECT_RULES.md`.
2. Read the assigned entry in `TODO.md` or the explicit task specification.
3. Read relevant active decisions in `DECISIONS.md`.
4. Inspect current Git branch, HEAD, status, and affected source.
5. If a task crosses FE/BE boundaries, inspect both request and backend contract before editing either side.
6. Verify the reported bug against current source instead of trusting archived audits.
7. For automated TODO selection, treat `REVIEW` as gated waiting work rather than resumable implementation. Skip unchanged `REVIEW` items and continue to the next safe actionable TODO.
8. Before revisiting a `REVIEW` item, compare its recorded review-branch HEAD and relevant `main` SHA(s). Resume only when new review feedback, explicit approval/instruction, a new failure, or a relevant SHA change provides new actionable evidence.

## Implementation rules

- Prefer TypeScript for application code.
- Keep the change narrowly scoped to the assigned task.
- Do not refactor unrelated code while fixing a bug.
- Do not delete files without explicit authorization.
- Do not weaken validation, authorization, tests, or financial invariants to make a task pass.
- Do not invent product/business rules. Put unresolved choices in `DECISIONS.md` under `Needs Decision` or report them to the Planner/Reviewer.
- Financial changes require explicit acceptance criteria and regression coverage.
- Bug fixes should add a regression test when practical.
- Cross-system changes must preserve or intentionally version the FE/BE API contract.
- Never expose or copy real secrets into source, logs, prompts, docs, fixtures, or commits.

## Financial safety

Treat payment, VAT, discount, running numbers, invoices, balances, order status derived from money, and historical financial records as high-risk areas.

For financial tasks:

- inspect server authority first;
- preserve satang precision;
- reject tampered financial facts rather than trusting the client;
- prefer immutable payment/reversal facts over silent historical edits;
- require idempotency/atomicity where retries or concurrency can occur;
- add focused tests for rounding, retry, overpayment, and state invariants as relevant.

## Verification

Before declaring a code task complete:

1. Run the smallest relevant tests first.
2. Run affected lint/type checks.
3. Run broader tests/build when the risk or task requires it.
4. Review `git diff` and confirm no unrelated files are included.
5. For FE/BE work, re-check the API contract after implementation.
6. Report any test/build step that was not run and why.

Never hide failing tests or claim a check passed when it was not run.

## Git behavior

Follow the risk-based policy in `PROJECT_RULES.md` and `WORKFLOW.md`.

- Never force-push shared history.
- Never rewrite shared history without explicit approval.
- Never commit unrelated changes together.
- Do not push directly to `main` by default; a small isolated change may be pushed directly only when the user/task explicitly allows it and verification passes.
- High-risk financial/security/schema/deployment work should use a branch and review/PR flow.

## Completion report

Every implementation report should include:

- task ID/title;
- files changed;
- behavior changed;
- tests/lint/type/build executed and results;
- Git status;
- remaining risks or follow-up work;
- commit/PR/push information only if performed.
