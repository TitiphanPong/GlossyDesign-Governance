# GlossyDesign Project Rules

Version: Governance V2  
Last reviewed: 2026-09-01 (Asia/Bangkok)

## 1. Stack and repository boundaries

Frontend:
- Next.js App Router
- TypeScript
- MUI

Backend:
- NestJS
- TypeScript
- MongoDB / Mongoose
- Private S3 storage for uploaded files

`GlossyPOS-Frontend` and `GlossyPOS-Backend` are separate Git repositories. Do not assume one repository can atomically commit the other.

## 2. Governance rules

- Current source is authoritative for describing current behavior.
- Active `DECISIONS.md` entries are authoritative for approved durable decisions.
- `TODO.md` is the only active execution backlog for Governance V2.
- Archived audits/plans under `docs/archive/` are historical evidence only.
- Do not reopen an archived finding without re-verifying it against current source.
- Keep completed work out of the active TODO after it has durable Git/history evidence.

## 3. Financial rules

- Backend financial calculation is authoritative.
- Currency precision must preserve satang; canonical monetary calculations use two decimal places / integer minor-unit semantics.
- Product prices are VAT-exclusive unless an active decision explicitly changes the policy.
- VAT rate is 7%.
- A regular receipt (`taxInvoice = no`) does not add VAT.
- A tax invoice (`taxInvoice = yes`) adds 7% VAT to the discounted VAT-exclusive base.
- Client-authored aggregate totals or financial status must not override server-calculated facts.
- Payment status must derive from authoritative payment facts.
- Historical payment facts must not be silently edited to repair a balance.
- Normal cashier workflows must not hard-delete financial records; cancellation/void/refund/reversal must be auditable.
- Running numbers must remain monotonic through the server-owned counter mechanism; agents must not invent client-side order numbers.

## 4. Date and business-time rules

- Business timezone is `Asia/Bangkok`.
- `createdAt` is the actual record/audit creation time.
- A backdated sale uses `saleDate` for the business sale date while preserving the actual creation time.
- Order numbering follows the actual number-issuance time, not the historical `saleDate`.
- Future backdated sale dates are invalid.
- All authenticated roles may create a backdated sale up to 30 Bangkok calendar days in the past.
- `backdatedReason` is mandatory whenever `saleDate` is earlier than the current Bangkok business date.
- Dates older than the 30-day window are rejected; there is no automatic role-based bypass.
- Backdated Orders keep the current monotonic Order number and should show an explicit backdated indicator in staff UI.

## 5. Authorization rules

- Frontend visibility is UX only; backend authorization is the security boundary.
- Role-sensitive UI and backend permissions must describe the same user capability.
- Do not expose a cashier action that the authenticated cashier role can never complete through the backend contract.
- Never weaken backend role checks merely to make frontend flows work.

## 6. Development rules

- Inspect before editing.
- One task must have one clear primary outcome.
- Avoid unrelated refactors.
- Prefer shared domain helpers over duplicating financial/business calculations.
- Bug fixes require regression tests when practical.
- Relevant tests must run before a task is complete.
- Lint/type/build failures must be reported truthfully.
- Do not delete source or data without explicit authorization.
- Do not make destructive database migrations without migration, reconciliation, backup, rollback, and owner approval.
- Do not change application source during governance-only tasks.
- `REVIEW` is a gated waiting state, not unfinished implementation. Automated runners must skip unchanged `REVIEW` work unless new review feedback, explicit approval/instruction, a new failure, or relevant branch/main changes make it actionable.
- Automated runners must use recorded branch/main SHA evidence to avoid repeating unchanged review/verification work. When no safe actionable TODO remains, report that state instead of reopening gated work.

## 7. Git rules — risk based

### Small / isolated / low-risk

Examples: copy fix, narrow UI bug, focused regression fix with no financial/schema/security migration.

- Direct commit to `main` may be used only when explicitly requested.
- Relevant verification must pass first.
- Commit only task-related files.

### Medium / high / critical risk

Examples: payment, auth/RBAC, Mongo schema/index/migration, tax invoice, running number, deployment/security, cross-repo contract change.

- Use a dedicated branch.
- Review the diff before merge.
- PR/review is preferred and required whenever the task specification says so.
- Include rollback/reconciliation notes where data or money can be affected.

### Automated TODO Runner integration policy

The project owner explicitly authorizes the automated TODO Runner to integrate completed implementation work into `main` without asking again for each task, provided every required gate below passes.

Required order for implementation tasks:

1. Implement the bounded task on a dedicated feature branch when the task is not an explicitly approved direct-to-main change.
2. Run relevant tests.
3. Run ESLint with the repository's configured zero-warning policy.
4. Run TypeScript/typecheck verification when available or as part of the production build.
5. Run the production build.
6. Run configured quality checks, including UTF-8/mojibake, security/audit, dead-code, duplicate-code, or Sonar checks when those tools are configured for that repository/task. Never claim an unavailable scanner ran.
7. Review the Git diff and exclude unrelated changes.
8. Commit Frontend and Backend separately in their own repositories when both are changed.
9. Push the feature branch(es).
10. Merge the verified feature branch(es) into local `main` without rewriting history.
11. Verify the resulting `main` state with critical/relevant checks.
12. Push `main`.
13. Only then mark the task/goal complete and report the commit/merge/push evidence.

If any required gate fails, do not merge or push `main`; fix the failure and rerun the affected gates. If the failure cannot be safely resolved, leave the feature branch intact and report a blocker.

Existing technical debt discovered by dead-code/duplicate/static analysis must not silently expand a bounded feature into a broad cleanup. New/touched code must be clean; unrelated legacy findings should become separate TODO items unless they make the current change unsafe.

### Automated Project Scanner policy

The Project Scanner is a read-only Planner against Frontend/Backend application source and is separate from the implementation TODO Runner.

- Run on a 6-hour cadence and keep scan state/latest report under `docs/reports/`.
- Prefer incremental analysis from the last recorded Frontend/Backend SHAs; perform at least one full-project scan per Bangkok calendar day.
- Inspect architecture/contracts, security, data integrity, FE↔BE API behavior, performance, tests/coverage, dead/duplicate/stale code, and rendered/runtime UX evidence where useful.
- Use available lnwjud context/graph/diagnostic/review tools and relevant local Skills/Recipes when they materially improve evidence. Never claim Knip, jscpd, SonarQube, or another scanner ran unless it is actually configured and executed.
- Re-verify each finding against current source and search `TODO.md` for an equivalent item before proposing a new TODO.
- New TODO candidates must include concrete evidence, priority/risk, FE/BE ownership, dependencies/blockers, do-not-touch boundaries, acceptance criteria, and required verification.
- Product/business-policy ambiguity is routed to Needs Decision / `BLOCKED`; Scanner does not invent behavior.
- Scanner never edits FE/BE application source, commits implementation code, merges branches, resets/cleans user WIP, or performs destructive actions.
- If an implementation durable goal is active, Scanner may inspect but must write findings only to its report/state files; do not concurrently mutate `TODO.md` or `DECISIONS.md`. Reconcile pending findings when the implementation runner is idle.

### Automated Feature Scout policy

The Feature Scout is a read-only Product/Opportunity Planner and is separate from both the technical Project Scanner and the implementation TODO Runner.

- Run once per Bangkok calendar day after the first daily Project Scanner window.
- Ground every opportunity in current source/capabilities, active TODO/DECISIONS, scanner evidence, and current durable-goal/WIP state.
- Use a change guard: if Frontend SHA, Backend SHA, TODO/DECISIONS, and meaningful scanner evidence are unchanged from the prior scout, keep the run lightweight and report no materially new opportunity rather than manufacturing candidates.
- Rank only a small differentiated set by business value, user frequency, readiness, complexity, risk, and dependencies.
- Deduplicate against active TODOs/decisions and classify candidates only as `READY_FOR_DISCUSSION`, `NEEDS_DECISION`, `DEPENDENCY_GATED`, `DEFER`, or `DUPLICATE`.
- Feature Scout must never edit Frontend/Backend application source, create implementation branches/commits, or directly promote a feature candidate into an executable `OPEN` TODO.
- Product-feature promotion into `TODO.md` requires explicit owner/Planner approval and a bounded implementation specification. Technical scanner findings remain governed separately by DEC-009.
- Keep the latest concise scout evidence under `docs/reports/feature-scout-latest.md` when useful.

### Scheduled automation orchestration

- ChatGPT Scheduled Tasks are the recurring bootstrap layer for the TODO Runner, Project Scanner, and Feature Scout.
- A recurring bootstrap must first check for an overlapping active durable goal and return a no-op rather than creating a competing worker.
- An unfinished durable lnwjud goal uses `lnwjud-scheduled-continuation` with exactly one confirmed one-time cloud successor for cross-turn recovery. Recurring bootstrap tasks are not substitutes for the active goal's continuation.
- Do not use Windows Task Scheduler, cron, shell timers, or another local recurring execution queue for these agent workflows.
- `NO_ACTIONABLE_TASK`, no new scanner finding, and no new scout opportunity are healthy terminal outcomes; automated workers must not invent work solely to keep the loop busy.

### Never

- force-push shared branches without explicit coordinated approval;
- rewrite shared Git history casually;
- commit secrets;
- mix unrelated work in one commit;
- mark a task complete while required verification is failing.

## 8. Testing and completion

Choose verification based on risk, but always report what ran.

Frontend scripts currently available include:
- `npm test`
- `npm run lint`
- `npm run build`
- `npm run check:utf8`

Backend scripts currently available include:
- `npm test`
- `npm run test:e2e`
- `npm run lint`
- `npm run build`

Financial/concurrency fixes require focused invariant tests in addition to normal unit/lint/build checks.
