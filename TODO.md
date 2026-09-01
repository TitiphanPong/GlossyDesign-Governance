# GlossyDesign TODO

Governance: V2  
Last reviewed: 2026-09-01 (Asia/Bangkok)  
Frontend baseline: `2d36e586f50eb2aa12cf43978727cc989b1a2834`  
Backend baseline: `94a82b8178014b0f55696c3545e978d52556b4a7`

This is the only active execution backlog for Governance V2. Archived audits/plans are historical evidence only.

Allowed status: `OPEN`, `IN_PROGRESS`, `REVIEW`, `BLOCKED`, `DONE`.

Automated TODO runner rule (2026-08-28): `REVIEW` is review-gated waiting work and must not be treated as resumable implementation. An unchanged `REVIEW` item is skipped when its recorded review-branch HEAD and relevant `main` SHA(s) are unchanged; full verification must not be repeated solely because the scheduler ran again. Resume only on new review feedback, explicit approval/instruction, a new failure, or a relevant SHA change. If no safe actionable item exists, report `NO_ACTIONABLE_TASK` instead of reopening gated work.

Owner product focus (2026-08-29): after safely finishing any genuinely `IN_PROGRESS` work, prioritize the verified hardening gaps from the fresh full-project scan before larger feature expansion. Preferred actionable sequence is `P1-11 → P1-12 → P2-25 → P2-26 → P2-27 → P2-28`, then P2-29/P2-30 as their dependencies permit. Existing decision-gated or external-service blockers remain blocked and must not be bypassed merely to preserve this order.

Fresh full-project gap scan (2026-08-29): current source was re-reviewed across Frontend routes/navigation, Orders/payment/workflow, customer display, Uploads/S3, Inventory, Dashboard, Notifications, Auth/configuration, and Backend controllers/schemas. The scan confirmed several gaps that are not covered by the completed Tracking/Stock work: Backend workflow transitions are not yet constrained to the same forward-only state graph exposed by the UI; customer-facing PromptPay account identity is partly hard-coded separately from the configured QR target; stale notification helpers still reason about the legacy mixed `status`; Dashboard explicitly reports `dueDates: false`, `urgentFlag: false`, and `uploadOrderLink: false`; Upload intake has no real Order relation and uses a collision-prone random four-digit daily display code; and the current architecture snapshot is materially behind source reality. New tasks below capture only gaps with source evidence. Product/BOM auto-consumption remains dependency-gated rather than being invented ahead of P2-08.

Fresh full-project gap scan (2026-08-30): current `main` was re-reviewed at Frontend `16f7bd2629089fb56b04c0f35c63546364cea12f` and Backend `ce6d5a31e6a3cfdc7f0c276ab47eb8339e3e3147`. The scan found six substantial gaps not already represented by the active backlog: Production Jobs can be created through the Backend but have no executable Frontend creation workflow; the Production Board silently loads only 100 jobs and customer-name search also truncates matching Orders to 100; Customer detail derives active Production Jobs and linked Uploads only from its latest 100 Orders; Dashboard/Action Center still advertise no due-date/urgent capability despite the real Production Job `dueAt`/`rush` model; Customer Display sessions have no explicit revoke/rotate lifecycle and retain per-session in-memory event Subjects indefinitely; and Production Job responses expose a customer milestone derived from job stage while public Tracking remains derived exclusively from Order workflow, creating a dual-truth risk that needs an explicit multi-job aggregation decision. The actionable follow-up sequence from this scan is `P2-32 → P2-34 → P2-33 → P2-35 → P2-36`; P1-13 is now actionable under DEC-014 (2026-08-31).

The previously reported Customer PromptPay whole-baht bug is not active: current Frontend main preserves satang and contains regression coverage.

## Review evidence — 2026-08-27

Backend main merge: `0900393`  
Frontend main merge: `88f6f22`  
Remote branch cleanup: both GitHub repositories now retain only `main`; local merged branch/worktree metadata may remain because lnwjud hard-blocks destructive Git ref/worktree cleanup.

Verified before push:
- Frontend tests: 98/98 passed.
- Frontend lint: passed.
- Frontend production build: passed.
- Backend unit tests: 65 passed; 4 Mongo-integration tests are intentionally excluded from the default unit run.
- Backend E2E: 29/29 passed.
- Backend isolated-Mongo payment concurrency suite: 4/4 passed.
- Backend lint: passed.
- Backend build: passed.
- Backend `npm audit`: 0 vulnerabilities after compatible dependency updates and a scoped `minimatch@3.1.5` / `brace-expansion@1.1.18` security override.
- Docker image/deploy smoke test is still unverified because the local Docker Desktop engine returned an API 500 during this review.

Items completed in the 2026-08-27 review batch are marked `DONE` only after their verified branches were merged and pushed to both `main` branches. `P1-08` remains blocked on an actual Docker/deploy smoke check.

## P0 — Critical (1)

### P0-01 — Make added payments atomic and idempotent

Status: DONE  
Area: Backend / Orders / Payments  
Risk: Financial integrity

Progress (2026-08-27):
- Backend commit `acbd853` on pushed branch `fix/p0-01a-atomic-add-payment` implements atomic compare-and-swap payment acceptance, payment-level idempotency, payment-fact reconciliation guards, and regression coverage.
- Frontend commit `a48e8fb` on pushed branch `fix/payment-idempotency-and-maintenance-2026-08-27` generates/reuses an idempotency key for a remaining-payment attempt and sends it through `Idempotency-Key`.
- Deterministic tests cover 2- and 5-request races, losing overpayment, conflicting idempotency reuse, and satang precision.
- Real isolated-Mongo suite `npm run test:mongo:payments` passed 4/4: five-payment race, competing overpayment, same-key concurrent retry deduplication, and `33.33 + 66.67 = 100.00` reconciliation.
- Full Backend unit/E2E/lint/build verification passed before push.
- Merged to Backend `main` at `ad18705` and Frontend `main` at `7565db1`; no additional implementation gap is currently known against this task's acceptance criteria.

Original problem on the Governance V2 baseline:
`OrdersService.addPayment()` read the Order, checked `remainingTotal`, mutated payment/balance/status in memory, then called `save()`. There was no payment-level idempotency key or atomic balance predicate.

Tasks:
- [x] Define a stable payment receipt/idempotency identity.
- [x] Make balance acceptance and payment append atomic/transactional.
- [x] Reject concurrent overpayment at the database boundary.
- [x] Derive/reconcile `paidAmount`, `remainingTotal`, and financial status from authoritative payment facts.
- [x] Add retry + 2–5 concurrent-request regression tests against an isolated Mongo target.

Acceptance:
- retrying the same payment cannot duplicate money received;
- concurrent payments cannot lose/overwrite payment facts;
- two requests cannot both spend the same remaining balance;
- overpayment is rejected atomically;
- stored payment facts reconcile to paid/remaining/status.

## P1 — High (13)

### P1-01 — Close the generic PATCH financial-status bypass

Status: DONE  
Area: Backend / Orders

Progress (2026-08-27):
- Pushed in Backend commit `acbd853`.
- A shared service guard now rejects direct writes to `awaiting_payment`, `partial`, and `paid` through both the status route and generic customer/order PATCH shapes.
- Regression coverage passed for all three financial statuses; full Backend unit/E2E/lint/build verification also passed.

Original problem on the Governance V2 baseline:
`updateStatus()` rejected direct writes to `awaiting_payment`, `partial`, and `paid`, but `updateOrder()` could still set `status` directly when status was submitted together with customer fields.

Acceptance:
All financial statuses are derived from payment facts regardless of which PATCH route/body shape is used.

### P1-02 — Replace cashier hard-delete Order behavior with an auditable correction policy

Status: DONE  
Area: Backend / Orders / Authorization

Progress (2026-08-31):
- Removed the production `DELETE /orders/:id` hard-delete route and replaced it with dedicated `POST /orders/:id/cancel` requiring a reason.
- Cancellation preserves the Order and original payment facts, records actor/time/reason, appends signed refund adjustment facts, zeroes the cancelled outstanding balance projection, and marks tax-document corrections explicitly when required.
- Cancellation uses a compare-and-swap predicate over workflow/financial state; a concurrent loser re-reads and returns an already-cancelled Order instead of appending duplicate refund facts.
- Dashboard received/payment projections now include dated financial adjustments instead of hiding cancelled Orders entirely.
- Frontend removed permanent-delete UI/password flow and uses the dedicated cancellation command with reason/refund/tax-document warnings.
- Verification passed before merge: Frontend tests 192/192, ESLint, UTF-8, production build/TypeScript, `npm audit` 0 vulnerabilities, `git diff --check`; Backend unit tests 195 passed with 15 expected skips, focused cancellation/reporting tests 34/34, E2E 37/37, ESLint, production build/TypeScript, `npm audit` 0 vulnerabilities, `git diff --check`.
- Feature commits `bf3b1cd` (Frontend) and `6af8593` (Backend) were pushed; verified feature branches were merged and pushed to `main` at Frontend `53e3df4` and Backend `f274b76`. Post-merge Frontend tests 192/192 + ESLint and Backend focused tests 34/34 + ESLint passed on `main`.

Problem:
`DELETE /orders/:id` is available to any authenticated role that can confirm its own password and physically calls `findByIdAndDelete()`.

Owner decision resolved by DEC-013 (2026-08-31):
- remove physical Order hard delete from normal production workflows;
- use one audited Cancel flow initially; do not create a separate Void semantic yet;
- every cancellation requires actor/time/reason and retains Order number/history;
- when money was received, record an append-only Refund fact for the amount actually returned, including method/actor/time/reason; never delete or rewrite original payment facts;
- reporting/balance projections must show both receipt and refund facts;
- initial correction scope is full cancellation/refund rather than partial refund complexity;
- issued tax documents use an explicit corrective-document/cancellation path.

Acceptance:
Normal production cashier flows cannot physically delete financial Orders; cancellation/refund facts are append-only, idempotent, auditable, concurrency-safe, preserve satang precision, and keep tax-document history correct.

### P1-03 — Resolve the public Tracking contract

Status: DONE  
Area: Frontend + Backend

Progress (2026-08-27):
- Pushed in Backend commit `acbd853`.
- Added one exact public `POST /tracking/lookup` contract requiring full order number plus phone suffix, with rate limiting and DTO validation.
- Public response is intentionally minimal (`orderNumber`, `status`, `createdAt`, `updatedAt`) and does not expose customer name, phone, cart, or financial totals.
- Tracking service/controller tests passed and the existing Frontend `/track` contract is aligned with the new route.

Original problem on the Governance V2 baseline:
Frontend posted to public `/tracking/lookup`, but no backend Tracking controller/module registered that route.

Acceptance:
Either implement one exact rate-limited minimal-PII lookup contract with tests, or intentionally disable/remove the public tracking UI until it exists.

### P1-04 — Make tax-invoice conversion and number allocation transaction-safe

Status: DONE  
Area: Backend / Orders / Counters / Tax invoice

Progress (2026-08-27):
- Active Backend branch: `fix/p1-04-tax-invoice-atomicity` from merged `main` `ad18705`.
- Conversion is being moved into one MongoDB transaction covering Order read, tax-invoice counter allocation, and Order update.
- Counter allocation now accepts the transaction session so a failed Order update can roll the allocated sequence back with the transaction.
- Conversion rejects partially populated legacy invoice identity instead of mixing an old invoice number with newly allocated book/sequence fields.
- Financial totals are checked against authoritative `payments[]` before conversion, and tax/VAT totals use satang/minor-unit arithmetic.
- Replica-set Mongo integration coverage now passes 3/3: five-way concurrent conversion allocates one identity/counter increment, failed Order update rolls the counter allocation back, and incomplete legacy identity is blocked before allocation.
- Full verification on the branch passes: unit tests 65 passed (7 integration tests skipped by default), E2E 29/29, payment Mongo 4/4, tax-invoice replica-set Mongo 3/3, lint, build, `git diff --check`, and `npm audit` with 0 vulnerabilities.
- Committed as `24d3bf0`, merged and pushed to Backend `main` at `39648e7`; acceptance criteria are satisfied.

Original problem on the Governance V2 baseline:
Tax-invoice number allocation occurred before the Order update and was not committed atomically with the document conversion.

Acceptance:
Concurrent/retried conversion cannot create multiple logical documents for one Order; response is idempotent and number allocation/update have a defined failure/reconciliation policy.

### P1-05 — Separate audit persistence failure from committed mutation outcome

Status: DONE  
Area: Backend / Reliability / Audit

Progress (2026-08-27):
- `AuditService.record()` now has an explicit best-effort post-commit contract: audit persistence failure is logged and returns `false` instead of throwing into an already completed business operation.
- This removes the ambiguous `mutation committed → audit write fails → client sees request failure → retry` outcome across Orders, Products, Quick Products, Uploads, and Auth call sites that use the shared audit boundary.
- Regression tests verify successful persistence returns `true` and audit database failure resolves `false` without rejecting the caller.
- Full verification passed: 67 unit tests, E2E 29/29, lint, build, and `npm audit` 0 vulnerabilities.
- Committed as `e4cc984`, merged and pushed to Backend `main` at `16415fe`.

Original problem on the Governance V2 baseline:
Controllers commonly mutated data first and then awaited audit persistence. If audit persistence failed after the mutation committed, the client could see a failed request and retry a non-idempotent command.

Acceptance:
Client-visible mutation outcome is unambiguous; audit failure is handled by an explicit transaction/outbox/best-effort contract appropriate to the command.

### P1-06 — Make S3/Mongo upload lifecycle recoverable

Status: DONE  
Area: Backend / Uploads / S3 / MongoDB

Progress (2026-08-27):
- Pushed in Backend commit `acbd853`.
- Create now compensates already-uploaded S3 objects if Mongo persistence fails.
- Delete now keeps the Mongo ownership reference until all referenced S3 objects are deleted, so an S3 failure can be retried instead of losing ownership state.
- Upload lifecycle regression tests passed 4/4.
- Residual distributed-systems ambiguity remains if S3 accepts a write but the network fails before the SDK can confirm success; a future reconciliation job would provide stronger orphan detection.

Original problem on the Governance V2 baseline:
Create uploaded S3 objects before Mongo create; delete removed Mongo first and then deleted S3. Partial failures could create orphaned objects or lost references.

Acceptance:
Create/delete have compensation or reconciliation, are retry-safe, and expose partial failure instead of silently losing ownership state.

### P1-07 — Align cashier capabilities with backend `priceOverride` authorization

Status: DONE  
Area: Frontend + Backend / POS / Quick Seller / RBAC

Progress (2026-08-27):
- Frontend committed as `c5c1409` and Backend regression coverage committed as `c6e2ad4`; both were pushed, merged, and pushed to `main` at Frontend `0253b12` and Backend `92c20a4`.
- Configured POS now carries authoritative catalog variant price metadata into cart items when the selected variant can be matched, including the edit-item path.
- `buildPendingOrderPayload()` omits `priceOverride` when the submitted unit price equals the matched active catalog variant; dynamic/custom pricing remains an explicit override.
- Quick Seller fetches the current authenticated role through the server session endpoint, hides manual price editing and disables custom-priced items for staff, and has a second submit-time fail-closed guard.
- Configured POS checks the same capability before order submission and explains that a Manager/Admin must confirm custom pricing instead of allowing a confusing backend `403` after the draft is locked.
- Backend authorization is not weakened: staff catalog pricing is covered as allowed while staff `priceOverride` remains rejected.
- Verification on the merged `main` results passes: Frontend 100/100 tests, ESLint, production build/TypeScript; Backend 67 unit tests, pricing regression coverage, ESLint, build, and merge diff checks.
- The generated `next-env.d.ts` build-only change was restored and was not included in the P1-07 commit.

Original problem:
Backend allows `priceOverride` only for manager/admin. Configured POS sent a `priceOverride` for cart lines, and Quick Seller exposed custom/manual price actions while staff can access cashier routes.

Acceptance:
Normal staff checkout succeeds for approved catalog pricing; custom/manual override UI and backend permissions describe the same role capability without weakening server authorization.

### P1-08 — Align production deployment files with runtime requirements

Status: BLOCKED  
Area: Backend / Deployment

Progress (2026-08-27):
- Pushed in Backend commit `c830882`.
- `render.yaml` now declares the env contract required by current validation instead of stale Google/PromptPay deployment variables.
- Docker runtime moved to Node 22 and reproducible `npm ci`; `.env.example` and README were aligned with the current AWS/auth runtime.
- Backend dependency audit was reduced from 31 advisories to 0 using compatible updates plus a scoped safe transitive override; unit/E2E/lint/build all pass.
- Blocker: local Docker Desktop engine returned API 500, so an actual image build/deploy smoke check could not be completed on this machine.

Original problem on the Governance V2 baseline:
Runtime env validation required `FRONTEND_ORIGIN` and AWS S3 variables, while `render.yaml` still declared stale Google/PromptPay variables and omitted required AWS/origin values. Docker used Node 18 + `npm install` while backend development/types targeted Node 22-era dependencies.

Acceptance:
The chosen production path has one documented env contract, supported Node runtime, reproducible install/build, and a deploy smoke check.

### P1-09 — Close historical credential-exposure evidence

Status: BLOCKED  
Area: Security / Operations

Problem:
Frontend Git history still contains historical `.env*` commits, and `docs/SECURITY_ROTATION_CHECKLIST.md` has no recorded closure evidence in this workspace.

Acceptance:
Secret classes are privately verified rotated/revoked, active sessions/keys are handled as required, provider-side evidence is recorded outside source, and the owner decides whether coordinated history rewrite is necessary.

Blocker:
Requires private provider/account verification; do not paste replacement secrets into this project.

### P1-10 — Prevent pre-hydration login credentials from entering the URL

Status: DONE  
Area: Frontend / Auth / Security

Progress (2026-08-29):
- Removed the native form `name` attributes from the login username/password controls, so a no-JS or pre-hydration browser submit has no credential fields to serialize into a GET query string. The hydrated application flow remains unchanged and still posts credentials through `/api/admin/session`.
- Added Playwright coverage with JavaScript disabled that submits the native login form and verifies the username/password do not appear in the resulting URL or any observed request URL.
- Final verification passed on the feature branch and again after merge to `main`: browser E2E 4/4, Frontend Node tests 142/142, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check`.
- Feature commit `9583b78` from `security/p1-10-login-prehydration` was pushed, fast-forward merged, and pushed to Frontend `main` at `9583b78`. Backend was not changed. The build-generated Frontend `next-env.d.ts` working-tree change was preserved and excluded from the task commit.

Acceptance:
The login form must fail closed before hydration and must never place username/password in the URL, history, referrer, or query string. Preserve the existing authenticated `/api/admin/session` POST behavior after hydration and add regression coverage for the pre-hydration/native-submit boundary.

### P1-11 — Enforce the production workflow state machine at the Backend boundary

Status: DONE  
Area: Frontend + Backend / Orders / Workflow integrity  
Risk: Operational integrity / auditability

Fresh-scan evidence (2026-08-29):
- Frontend Order detail intentionally exposes only the forward progression `pending → producing → ready_for_pickup → delivered`.
- Backend `assertWorkflowStatusWritable()` currently rejects only financial statuses. Both `PATCH /orders/:id/status` and the mixed customer/order PATCH path can therefore write a workflow status without validating the current workflow state, allowing API callers to skip or move backward between production stages even though the UI does not offer that behavior.
- `statusHistory.changedBy` exists in the schema, but normal workflow updates currently append history without the authenticated actor; the separate audit event does not make the embedded workflow timeline self-attributing.
- Cancellation/void/refund semantics remain governed by blocked P1-02 and must not be invented inside this task.

Progress (2026-08-29):
- Backend now owns the normal production transition graph `pending → producing → ready_for_pickup → delivered`; skip-forward and backward transitions return conflict, while exact same-state retries are idempotent and do not append duplicate history.
- Workflow progression uses an atomic current-state predicate so a concurrent loser cannot append an impossible sequence. The generic `PATCH /orders/:id` path and dedicated status endpoint share the same transition boundary.
- `statusHistory.changedBy` records the authenticated user id for workflow mutations and initial Order creation when an actor is available. Ordinary production progression leaves authoritative financial `status` unchanged.
- Existing cancellation behavior remains separate in this task's scope; future correction semantics are now governed by P1-02 and DEC-013.
- Verification passed before merge and again on merged Backend `main`: focused OrdersService 24/24, full unit 129 passed with 15 integration tests skipped by the default suite, E2E 30/30, ESLint, production build, and `git diff --check`.
- Feature commit `660f9bf` from `fix/p1-11-workflow-state-machine` was pushed, fast-forward merged, and pushed to Backend `main` at `660f9bf`.

Acceptance:
- Backend owns and tests the legal non-cancellation transition graph used by the storefront workflow; Frontend progression is UX, not the integrity boundary.
- A request cannot skip forward or move backward through normal production states. Exact same-state retry is idempotent and must not append duplicate history.
- Concurrent progression attempts use an atomic current-state predicate or equivalent protection so two callers cannot produce an impossible history sequence.
- Authenticated actor identity is persisted with workflow history/audit evidence without exposing secrets or PII publicly.
- Financial `status` remains derived from payment facts and is not overwritten by ordinary production progression.
- The generic PATCH path and dedicated status path enforce the same workflow rule.
- Do not implement cancellation/refund changes inside P1-11; those semantics belong to P1-02 under DEC-013.

### P1-12 — Unify the configured PromptPay payment identity shown to customers

Status: DONE  
Area: Frontend / Payments / Customer Display / Configuration  
Risk: Payment instruction integrity

Fresh-scan evidence (2026-08-29):
- QR payload generation correctly uses configured `NEXT_PUBLIC_PROMPTPAY_ID` and fails closed when that target is absent.
- `CustomerActiveOrderScreen.tsx` separately hard-codes a personal account name and account number for the text displayed beneath the QR. Those values can drift from the configured QR target after an environment change and currently require a source-code deployment to update.
- Quick Sale and Customer Display should describe one payment destination rather than independent UI copies.

Progress (2026-08-29):
- Added one normalized PromptPay profile contract in `src/lib/promptpay.ts` using `NEXT_PUBLIC_PROMPTPAY_ID` plus `NEXT_PUBLIC_PROMPTPAY_DISPLAY_NAME`. The visible identifier is derived from the configured QR target, so customer-facing identity cannot drift to a separately hard-coded account number.
- Customer Display and Quick Sale now consume the same profile. Missing/incomplete configuration fails closed: Customer Display shows a configuration error instead of a QR, and Quick Sale cannot confirm a PromptPay payment without a complete profile.
- Removed the hard-coded personal account name/number from React source. `.env.example` and README document placeholder/public-display configuration only; no secret value was committed.
- Added focused normalization/missing-config tests and browser coverage proving Quick Sale and Customer Display show the same configured profile.
- Verification passed before merge and again on merged Frontend `main`: Node tests 144/144, browser E2E 5/5, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check`.
- Feature commit `d818e0d` from `fix/p1-12-promptpay-profile` was pushed, fast-forward merged, and pushed to Frontend `main` at `d818e0d`. Backend was not changed. The build-generated `next-env.d.ts` working-tree change remained uncommitted and was preserved.

Acceptance:
- Define one explicit, documented customer-facing PromptPay profile contract for QR target plus safe display name/identifier; no personal bank/account value is hard-coded in React source.
- Quick Sale and Customer Display consume the same normalized profile and cannot display an account identity that disagrees with the configured payment destination.
- Missing/incomplete configuration fails visibly and does not fabricate fallback payment details or a QR.
- Keep configuration values outside Git secrets; examples use placeholders or intentionally public business-display values only.
- Add focused tests for profile normalization, missing configuration, and both customer-facing payment surfaces.

### P1-13 — Resolve Production Job ↔ public Tracking workflow authority

Status: DONE  
Area: Frontend + Backend / Production / Orders / Customer Tracking  
Risk: Customer-facing operational correctness

Fresh-scan evidence (2026-08-30):
- `ProductionService.toResponse()` exposes `customerMilestone` derived directly from the Production Job stage (`file_check/queued → received`, `producing/quality_check → in_progress`, `ready → ready`, `delivered → completed`). The Job Ticket therefore presents a customer-facing projection sourced from Production Job state.
- `ProductionService.updateStage()` mutates only the Production Job and its stage history; it does not update the owning Order workflow.
- Public `/tracking/lookup` and `/tracking/token` call `OrdersService.buildPublicTrackingResponse()`, which derives milestones exclusively from Order `workflowStatus` / `statusHistory` and never reads Production Jobs.
- One Order may own multiple Production Jobs, so automatically projecting one job transition onto the Order without an aggregation rule could report `ready` or `completed` while sibling work is unfinished.

Owner decision resolved by DEC-014 (2026-08-31):
- Production Job progress contributes to public Order Tracking;
- active work may project the Order to `in_progress`;
- an Order becomes `ready` only when every non-cancelled required Production Job is ready-or-later; one sibling Job cannot advance the whole Order prematurely;
- `completed` / `delivered` remains an explicit staff-confirmed Order handoff and is not automatically derived from Job completion;
- Orders with no Production Job keep the existing Order workflow/tracking behavior;
- financial status remains independent.

Acceptance:
- Production Job/Order Tracking exposes one intentional customer-status authority consistent with DEC-014.
- Multi-job Orders have a deterministic tested aggregation rule and cannot become ready/completed from one sibling job alone.
- Aggregation/projection is retry/concurrency safe and preserves Order financial status independently.
- Existing secure tracking-token and phone-suffix privacy contracts remain unchanged.

Completion evidence (2026-08-31):
- Backend feature commit `0f44aae` implements read-time Production Job aggregation for public Tracking; merged and pushed to Backend `main` at `da9b346`.
- Multi-job coverage proves one ready sibling cannot advance the Order, all ready-or-later siblings aggregate `ready` at the last readiness timestamp, and no Production Job preserves the existing Order workflow behavior.
- Verification passed: Backend unit 197/197 (15 skipped integration tests unchanged), E2E 37/37, ESLint, TypeScript build, `git diff --check`, and `npm audit` with 0 vulnerabilities; the same unit/E2E/lint/build suite passed again on merged `main`.

## P2 — Medium (38)

### P2-01 — Define and enforce the backdate policy

Status: DONE  
Area: Backend + Quick Seller

Owner decision resolved on 2026-08-29 via DEC-003:
- all authenticated roles (`staff`, `manager`, `admin`) may backdate;
- maximum window is 30 Bangkok calendar days;
- `backdatedReason` is mandatory for every backdated sale;
- future/out-of-window dates are rejected with no automatic role bypass;
- Order numbers remain current/monotonic and staff UI should mark the Order as backdated;
- reporting uses `saleDate` while `createdAt` remains the actual audit timestamp.

Progress (2026-08-29):
- Backend now enforces one server-owned backdate boundary: a valid historical `saleDate` is required, future dates are rejected, the maximum age is 30 Bangkok calendar days, and `backdatedReason` must contain non-whitespace text. No role-specific backdate restriction was added, so the existing authenticated staff/manager/admin create path remains available as approved.
- Order-number allocation was left unchanged, so numbering continues from actual issuance time. Existing reporting already uses effective `saleDate` with `createdAt` fallback and no financial calculation rule was changed.
- Quick Sale applies the same 30-day/reason validation before confirmation and submit, limits the picker to the supported window, and shows an explicit validation error. Order detail now shows a `รายการย้อนหลัง` badge, historical sale date, and recorded reason.
- Verification before merge passed: Frontend Node tests 167/167, ESLint, UTF-8 validation, production build/TypeScript, staged diff review, and `git diff --check`; Backend focused backdate/Orders tests 28/28, full unit 155 passed with 15 integration tests skipped by the default suite, E2E 35/35, ESLint, production build, staged diff review, and `git diff --check`.
- Feature branch `feature/p2-01-backdate-policy` was pushed and fast-forward merged to Frontend `main` at `0e8d3e6` and Backend `main` at `8b96d1e`, then both `main` branches were pushed. Merged-main verification passed Frontend full Node tests and Backend focused backdate/Orders 28/28.
- Frontend build-generated `next-env.d.ts` remains uncommitted and preserved; it was excluded from the task commit.

Acceptance:
Enforce DEC-003 at the Backend boundary with Bangkok date-boundary tests, preserve current Order numbering, and surface a clear backdated indicator in the relevant Quick Seller/Order UI without changing financial calculation semantics.

### P2-02 — Move Storage filtering/group semantics before pagination

Status: DONE  
Area: Frontend + Backend / Upload Storage

Progress (2026-08-27):
- Frontend Storage now sends search/status/date/sort/page/limit to the server, consumes server grouped rows/counts/summary, and no longer applies grouping/filtering only to the currently loaded raw page.
- Frontend pagination was standardized to `10 / 25 / 50 / 100` with default `10`; the related Frontend work was merged and pushed to `main` at `829e6ba`.
- Backend `GET /uploads` / `/upload` now derives Storage status, resolves batch grouping, filters the grouped full result, sorts it, and only then applies `$facet` count/summary/pagination.
- Grouped responses carry `sourceIds` so bulk/status/delete actions still target every raw upload record in the displayed batch.
- Backend focused UploadsService tests passed 5/5; full Backend unit verification passed 72 tests with 12 integration tests intentionally skipped by the default run; E2E passed 29/29; lint, build, and `git diff --check` passed.
- Backend committed as `299af0a`, merged by fast-forward, and pushed to `main` at `299af0a`.

Acceptance:
Filtering/counts/grouped batch semantics represent the full server result, not only the currently loaded raw page.

### P2-03 — Make the public upload create/open/config contract coherent

Status: DONE  
Area: Frontend + Backend / Upload

Progress (2026-08-27):
- Public `/upload` no longer requires a browser-visible `NEXT_PUBLIC_API_URL`; browser calls continue through the same-origin `/api/backend` BFF, while server-side resolution prefers `BACKEND_API_URL` with the legacy public variable only as a fallback.
- A successful anonymous upload now returns a short-lived signed preview URL in the same public create response, so the uploader can open the file it just submitted without calling the authenticated signed-URL endpoint.
- Immediate public preview URLs expire after 15 minutes; the upload UI shows the expiry window and keeps later signed-URL retrieval protected for authenticated staff workflows.
- The displayed upload limit now derives from the real `7,500,000` byte limit and shows `7.5 MB` consistently in validation and helper text.
- Frontend verification passed on merged `main`: 109/109 tests, ESLint, production build/TypeScript, UTF-8 check, and diff check. Frontend feature commit `dd140bc` was merged and pushed to `main` at `ba1291d`.
- Backend verification passed on merged `main`: 73 unit tests with 12 integration tests intentionally skipped by the default run, E2E 29/29, ESLint, build, and diff check. Backend feature commit `8c59585` was merged and pushed to `main` at `e87c383`.
- Sonar evidence: VS Code has `sonarsource.sonarlint-vscode` installed, but this machine has no `sonar-scanner` CLI and lnwjud has no configured TypeScript/Sonar diagnostics bridge. Therefore no SonarQube server scan was claimed; ESLint/static build checks are verified, while SonarQube remains an environment/tooling gap rather than a code failure.

Acceptance:
Anonymous upload behavior, post-upload open behavior, API configuration, and displayed size limit all match one tested contract.

### P2-04 — Harden public upload content and aggregate resource limits

Status: DONE  
Area: Backend / Upload security

Progress (2026-08-28):
- Git history review found that security baseline commit `a3d1f73` is already an ancestor of Backend `main` (`888cc39`), despite the earlier TODO note saying it had not been merged. The Governance record is corrected here to match current Git reality; no history rewrite was attempted.
- The baseline replaced unbounded aggregate Multer memory buffering with a request-shared `BoundedMemoryStorage` budget capped at `25,000,000` bytes while preserving the existing `7,500,000` byte per-file cap and max 10 files.
- Baseline validation requires a compatible extension/MIME pair and checks content signatures for PDF, JPEG, PNG, AI (PDF/PostScript), PSD, ZIP/OOXML, legacy OLE Office files, plus text-like CSV rejection of binary/control payloads. Public-upload policy remains fail-closed before persistence: mismatched/spoofed files are rejected rather than quarantined into S3.
- Security review identified one residual spoof gap: DOCX/XLSX validation accepted any ZIP signature. Follow-up branch `security/p2-04-ooxml-container-validation` now requires OOXML packages to contain `[Content_Types].xml` plus the correct `word/` or `xl/` package family; generic ZIPs and wrong-family packages are rejected.
- Initial OOXML follow-up committed as `fe99d02` and pushed for security review. A second review found that scanning local ZIP headers could be spoofed by header-like bytes embedded in payload data; commit `715d4ab` now validates OOXML entry names from the bounded classic ZIP central directory/EOCD instead and rejects malformed/multi-disk layouts fail-closed.
- A third review found that central-directory marker names were not yet bound back to their referenced local file headers. Commit `8e5bbb7` now requires each central-directory entry to reference a real local header with the same filename and bounded compressed-data region, so forged directory-only OOXML markers fail closed.
- A fourth review found that accepting any `word/` or `xl/` entry still allowed OOXML-looking ZIPs without the actual core document. Commit `48b9532` now requires exact core parts `word/document.xml` for DOCX and `xl/workbook.xml` for XLSX in addition to `[Content_Types].xml`.
- A fifth review found that a forged central-directory entry could still point its `localHeaderOffset` into the payload region of another ZIP entry if matching fake local headers were embedded there. Commit `f30b801` records each referenced local header/data region and rejects overlapping regions, preventing nested payload offsets from being treated as independent OOXML package entries.
- Regression coverage now includes generic ZIP disguise, wrong OOXML package family, missing core OOXML document parts, valid DOCX/XLSX package markers, fake local headers embedded only in ZIP payload data, forged central-directory names that disagree with local headers, and central-directory entries that point inside another entry payload. Focused validator verification passed 12/12; full Backend verification on the current review branch passed 90 unit tests with 12 integration tests intentionally skipped by the default run, E2E 30/30, ESLint, build, and `git diff --check`.
- Branch `security/p2-04-ooxml-container-validation` is pushed at `f30b801` and intentionally remains unmerged because P2-04 changes the public upload security boundary.
- Independent review/verification on 2026-08-28 re-ran the current branch without further source changes: focused upload validator 12/12, full Backend unit 90 passed with 12 integration tests skipped by the default suite, E2E 30/30, ESLint, build, and `git diff --check` all passed. Diff review remained limited to the upload validator and its regression spec; no additional defect was identified that could be corrected safely without introducing a new content-inspection policy or compatibility trade-off. Status remains `REVIEW` pending the security review/merge boundary.
- A second independent verification on 2026-08-28 confirmed the same branch HEAD `f30b801` remains clean and reproducible: focused validator 12/12, unit 90 passed, E2E 30/30, ESLint, build, and `git diff --check main...HEAD` all passed. No source change was justified in this review, so the security branch was intentionally left unchanged and unmerged.
- Owner approval was given on 2026-08-28 to cross the P2-04 security review gate. Final pre-merge verification passed again: Backend unit tests, E2E 30/30, ESLint, build, and `git diff --check main...HEAD`. The approved branch `security/p2-04-ooxml-container-validation` at `f30b801` was merged and pushed to Backend `main` at `e6aa2ac`; P2-04 is now complete.

Original problem:
Public upload used memory buffering for up to 10 files at 7,500,000 bytes each and validated extension + browser-reported MIME independently, so allowed-but-mismatched types could pass and one request could buffer roughly 75 MB.

Acceptance:
Define aggregate memory/request limits and a content-signature/quarantine policy appropriate for public uploads; add spoof/oversize tests.

### P2-05 — Make Dashboard drill-down URL state executable

Status: DONE  
Area: Frontend + Backend / Dashboard + Orders

Progress (2026-08-27):
- Dashboard `status`, `payment=unpaid`, and `month` links now hydrate executable Orders filters instead of only reading `month`.
- Orders exposes visible status and outstanding-payment controls/chips, keeps supported drill-down state synchronized with the URL, and removes invalid drill-down values while preserving unrelated query params.
- Frontend order list/export requests now forward `status` and `payment` filters to the server.
- Backend defines `payment=unpaid` as `remainingTotal > 0` while excluding cancelled Orders, so both `awaiting_payment` and `partial` outstanding balances are represented correctly.
- Verification passed before and after merge: Frontend 102/102 tests, ESLint, production build/TypeScript; Backend 68 unit tests, ESLint, build, and diff checks.
- Frontend commit `3923b67` and Backend commit `a0e0102` were merged and pushed to `main` at Frontend `79772c8` and Backend `cc59a37`; remote feature branches were removed after merge.

Original problem:
Dashboard links generated `status`, `payment`, and `month` query parameters, but Orders read only `month` from the URL.

Acceptance:
Supported dashboard links land on the intended filtered Orders state; unsupported parameters are removed or handled explicitly.

### P2-06 — Bind order-create idempotency to actor and canonical payload

Status: DONE  
Area: Backend / Orders

Progress (2026-08-27):
- Idempotent create commands now persist a SHA-256 fingerprint over normalized idempotency identity, authenticated actor id, and a recursively key-sorted validated request payload.
- Same actor + same canonical command replays the original Order; same identity with a different actor or materially different payload returns `409 Conflict`.
- Concurrent same-command retries deduplicate to one stored Order, and legacy idempotency rows without a command fingerprint fail closed instead of returning an unverifiable Order.
- Real Mongo integration coverage passes 5/5; full regression remains green with unit 67, E2E 29/29, payment Mongo 4/4, tax-invoice Mongo 3/3, lint, build, and dependency audit 0 vulnerabilities.
- Committed as `548592f`, merged and pushed to Backend `main` at `c2e4302`.

Original problem on the Governance V2 baseline:
Create idempotency returned an existing Order by `clientDraftId`/`Idempotency-Key` without verifying that the actor and canonical request payload matched the original command.

Acceptance:
Same key + same authorized command returns the original result; same key + materially different actor/payload returns an explicit conflict.

### P2-07 — Implement the approved customer-display synchronization target

Status: DONE  
Area: Frontend + Backend / Customer display

Owner decision resolved on 2026-08-29 via DEC-007: support both same-machine second-display use and separately paired tablet/phone/computer use, synchronize checkout state in real time, and isolate each counter/display pair with its own session/pairing identity.

Progress (2026-08-30):
- Preserved the existing same-machine `localStorage` + `BroadcastChannel` path and added a paired-device path from both Quick Sale and configured POS. Staff can create/reuse a customer-display session and open/share a QR/link for `/customer?display=<opaque token>`.
- Backend now persists scoped `CustomerDisplaySession` records with a collision-safe UUID session id, a 256-bit opaque display capability hashed at rest, authenticated publisher ownership, and a 12-hour TTL. A signed-in user cannot publish into another user's session.
- Cross-device reads are read-only capability-scoped endpoints. SSE is scoped to one session, sends the persisted latest state immediately, refreshes from Mongo every three seconds so separate backend instances converge, and supports normal EventSource reconnect. The paired display clears its visible Order while disconnected instead of continuing to show stale checkout state.
- Checkout publication remains best-effort and cannot block a sale. The public display projection explicitly strips customer name, phone, internal/order notes, staff controls, and other unnecessary PII; only approved item/payment/display fields are sent.
- Frontend regression coverage locks the public BFF allowlist and display projection privacy boundary. Backend service coverage verifies cross-owner update rejection, opaque-token lookup, invalid-token rejection, and clearing state without destroying the pairing.
- Verification passed before merge and again on merged `main`: Frontend 174/174 tests, ESLint, UTF-8 validation, production build/TypeScript, and staged `git diff --check`; Backend 163 unit tests passed with 15 integration tests skipped by the default suite, E2E 35/35, ESLint, production build, and staged `git diff --check`.
- Frontend feature commit `3406dcc` and Backend feature commit `ce6d5a3` were pushed from `feature/p2-07-customer-display-sync`, fast-forward merged, and pushed to `main`; merged `HEAD` values are Frontend `3406dcc9110799b4fda59982e624fd074567c88c` and Backend `ce6d5a31e6a3cfdc7f0c276ab47eb8339e3e3147`.
- Frontend build regenerated `next-env.d.ts`; it was deliberately excluded from the task commit and preserved rather than mixed into the feature.
- Local and remote cleanup of `feature/p2-07-customer-display-sync` was attempted in both repositories but blocked by destructive-Git protection; the fully merged branches were preserved without bypassing policy.

Acceptance:
Implement and document/test the DEC-007 topology. Preserve same-machine support, add safe paired multi-device real-time synchronization and reconnect behavior, prevent cross-counter display leakage, and expose only the approved customer-facing checkout/payment fields.

### P2-08 — Resolve Product vs QuickProduct catalog ownership

Status: DONE  
Area: Frontend + Backend / Catalog

Owner decision resolved by DEC-011 (2026-08-31):
- `Product` / variant identity is the long-term canonical catalog lifecycle;
- Quick Seller remains the primary cashier workflow but should evolve into a presentation/shortcut layer that maps configured choices to canonical Product/Variant identities;
- custom/ad-hoc line items and per-sale custom prices remain supported without mutating shared catalog prices;
- migration must be incremental and non-destructive so existing QuickProduct identifiers and historical Orders remain readable.

Progress (2026-08-31):
- QuickProduct remains the Quick Seller shortcut/presentation record with its own stable `_id`, `code`, and `typeCode`, while optional `productId`/`variantId` now link a shortcut explicitly to the canonical Product/Variant lifecycle without destructive collection merging or historical rewrites.
- Quick Seller settings now load the canonical Product catalog and provide an explicit Product/Variant mapping selector. Legacy/unmapped shortcuts remain valid; mapped shortcuts may be remapped, while unlink semantics are intentionally not introduced during this migration.
- Quick Sale cart/order submission now carries `quickProductId` separately from canonical `productId`/`variantId`. Backend pricing resolves an explicit QuickProduct first, follows its canonical mapping when present, validates Product/Variant consistency, and stores both identities on the Order line.
- Existing unmapped QuickProducts remain readable through the legacy Quick Sale resolution path, and custom/ad-hoc items plus authorized per-sale price overrides remain supported without changing shared catalog prices.
- Verification before merge passed: Frontend 192/192 tests, ESLint, `npx tsc --noEmit`, UTF-8/production build, and `git diff --check`; Backend 198 unit tests passed with 15 default-suite integration skips, mapped QuickProduct regression 7/7, ESLint, production build/TypeScript, and `git diff --check`.
- Feature commits `d241f75` (Frontend) and `d8ecdf1` (Backend) were pushed and fast-forward merged to `main`. Merged-main verification passed Frontend 192/192 tests + ESLint and Backend mapped regression 7/7 + ESLint; both `main` branches were pushed at those commits.

Acceptance:
Document and implement the DEC-011 lifecycle boundary, preserve custom-item/custom-price behavior, add explicit deterministic Quick Seller → Product/Variant mapping where applicable, and keep existing historical Orders/legacy identities readable throughout migration.

### P2-09 — Put Governance V2 under versioned ownership and migrate old Codex automation

Status: DONE  
Area: Governance / Automation

Owner decisions resolved by DEC-010 and DEC-012 (2026-08-31):
- workspace-root `TODO.md` remains the sole active execution backlog/source of truth;
- the six cross-repo governance files belong in a dedicated `GlossyDesign-Governance` Git repository rather than either application repo or a parent repo that absorbs nested histories;
- legacy Frontend Codex/GitHub TODO automation must be disabled or migrated so it cannot independently act as a second queue; legacy scripts/history may remain temporarily for reference only;
- the Governance V2 TODO Runner remains the approved implementation worker under DEC-008.

Progress (2026-08-31):
- Adopted the dedicated `TitiphanPong/GlossyDesign-Governance` repository and prepared the six canonical Governance V2 files plus a read-only drift checker; the workspace-root copies remain the runtime source of truth and no parent Git repository was introduced around the Frontend/Backend histories.
- Refreshed `ARCHITECTURE.md` against current application reality and recorded Frontend `d04012ae8c76b63df56fb97187c9b5122a80adf9` / Backend `d8ecdf1c9b2c41f779854f4daa0781944d8ed7ea` main SHAs.
- Disabled the three legacy Frontend Codex GitHub workflows so they are manual/inert and cannot select, mutate, or complete repository-local TODO work; removed the legacy `codex:todo:*` npm entry points and documented the migration boundary.
- Frontend verification passed before merge: 192/192 tests, ESLint, `npx tsc --noEmit`, UTF-8 validation, production build/TypeScript, and `git diff --check`. Feature commit `d04012a` was pushed, fast-forward merged, and pushed to Frontend `main`.
- Governance drift check passed with all six files identical before final status update and both recorded application SHAs matching checked-out `main`; the governance repository is versioned/pushed with the final canonical state.

Acceptance:
Create/adopt the dedicated governance repository, version the canonical governance files without rewriting FE/BE histories, disable or migrate competing legacy TODO execution behavior, refresh the architecture snapshot against current FE/BE main SHAs, and define lightweight SHA-drift reporting.

### P2-10 — Turn notifications into an actionable cashier Action Center

Status: DONE  
Area: Frontend + Backend / Notifications / Orders / Uploads

Progress (2026-08-27):
- Replaced the notification-feed semantics with an Action Center that surfaces operational summaries for urgent work, outstanding payment, and uploads waiting for review.
- Added `GET /notifications/action-center` so summary and actionable items are returned from one snapshot; legacy `order_created` noise is excluded from the operational queue.
- Action-required items can no longer be manually resolved/dismissed while the underlying condition is active; payment/upload lifecycle state resolves the corresponding items.
- Order creation now evaluates outstanding-payment state instead of creating a generic "new order waiting" notification for every sale.
- Notification actions now use semantic actions and current routes: payment opens the focused Order + remaining-payment flow, and upload review opens the focused Storage record. Legacy order-detail links are normalized for compatibility.
- Upload create/update/delete are connected to Action Center lifecycle without weakening existing S3/Mongo recovery behavior.
- Verification passed on feature branches and merged `main`: Frontend 108/108 tests, ESLint, production build/TypeScript/UTF-8; Backend 71 unit tests, E2E 29/29, ESLint, build, and `git diff --check`.
- Frontend feature commit `b90307f` and Backend feature commit `2693102` were merged and pushed to `main` at Frontend `88f6f22` and Backend `0900393`.

Acceptance:
The cashier Action Center shows only work that requires operational follow-up, actions deep-link to executable workflows, and critical action items disappear from business-state transitions rather than a cosmetic "done" button.

### P2-11 — Keep Frontend session authorization synchronized with backend identity

Status: DONE  
Area: Frontend + Backend / Auth / RBAC

Progress (2026-08-28):
- Backend authorization was inspected and left unchanged: every bearer-token request resolves the current active User document, so current role remains authoritative at the Backend boundary.
- Frontend `GET /api/admin/session` now consumes the current `username` and `role` returned by Backend `/auth/me` instead of returning stale role metadata from the signed browser cookie.
- After a successful identity refresh, Frontend re-signs the HTTP-only session cookie with the current Backend identity while preserving the existing backend access token and original expiry; a role refresh cannot extend the Backend session lifetime.
- Invalid/malformed `/auth/me` identity payloads fail closed with a service-unavailable response rather than falling back to stale privileged metadata.
- Regression coverage verifies stale `admin → staff` demotion and `staff → manager` promotion are reflected immediately by the session broker, including refreshed cookie role metadata.
- Verification passed on the feature branch and merged `main`: focused session tests 4/4, full Frontend tests 135/135, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check`. Frontend feature/main commit is `fcf7fc9`; `HEAD` matches `origin/main`. Backend remained unchanged at `3866a20`, also matching `origin/main`.
- Local and remote cleanup of `fix/p2-11-session-identity-sync` was attempted after merge but denied by lnwjud destructive-Git policy; the fully merged branch is preserved without bypassing protection. The pre-existing/generated Frontend `next-env.d.ts` working-tree change was also preserved and excluded from the task commit.

Acceptance:
Frontend session/route capability state reflects the backend's current authenticated identity after a role change; demotion cannot leave privileged UI visible and promotion does not require waiting for cookie expiry. Backend authorization remains authoritative and regression tests cover role changes.

### P2-12 — Bound and stream the Next.js backend proxy

Status: DONE  
Area: Frontend / BFF / Reliability / Public upload

Progress (2026-08-28):
- Replaced `await request.arrayBuffer()` in the Next.js backend proxy with direct request-body streaming, so multipart uploads are forwarded without materializing a second full body buffer in the Frontend runtime.
- Added deterministic ingress bounds: public `/upload` and `/uploads` requests are capped at the existing Backend aggregate limit of `25,000,000` bytes, while normal proxied command bodies use a `5,000,000` byte bound. `Content-Length` is rejected early when available and a streaming byte counter enforces the bound for bodies without a trusted length.
- Client request cancellation is forwarded to the upstream fetch through `AbortController`; Backend requests also have a deterministic 120-second timeout that returns `504 Backend service timed out`. Oversized bodies return `413`, while other upstream failures retain the existing `502` contract.
- Added regression coverage for upload vs non-upload proxy limits, early `Content-Length` rejection, and bounded streaming behavior without weakening Backend upload limits.
- Frontend verification passed before merge and again on merged `main`: full tests passed, ESLint passed, production build/TypeScript passed, UTF-8 validation passed, and task-scoped `git diff --check` passed.
- Feature commit `3b8fd5c` from `fix/p2-12-bounded-streaming-proxy` was pushed, fast-forward merged, and pushed to Frontend `main` at `3b8fd5c`. The pre-existing/generated `next-env.d.ts` working-tree change was preserved and excluded from the task commit.

Acceptance:
Use bounded streaming/forwarding where the supported Next.js runtime allows it; otherwise enforce an explicit ingress bound before buffering. Propagate request cancellation where practical, add a deterministic upstream timeout/error contract, and cover upload/non-upload proxy behavior with regression tests without weakening the Backend upload limits.

### P2-13 — Add real production readiness probes

Status: DONE  
Area: Backend / Deployment / Reliability

Progress (2026-08-28):
- Kept public `GET /health` as the cheap dependency-independent liveness response and added public `GET /health/ready` as the production traffic readiness gate.
- Readiness checks MongoDB with a bounded ping and S3 with a bounded non-mutating `HeadBucket` capability check; dependency failures return generic HTTP 503 `unready` without exposing bucket names, credentials, connection strings, or provider error details.
- S3 readiness uses an abort signal with a 2.5-second bound, while MongoDB ping is wrapped in the same readiness timeout. Missing/uninitialized Mongo state fails closed as unready.
- `render.yaml` now sets `healthCheckPath: /health/ready`, and README documents liveness vs readiness plus the non-mutating bucket permission required by the deployed AWS principal.
- Focused health tests passed 6/6. Full Backend unit verification passed 121 tests with 15 integration tests skipped by the default suite; E2E passed 30/30; ESLint, production build, and `git diff --check` passed.
- Feature commit `d06f363` from `feature/p2-13-readiness-probes` was pushed, fast-forward merged, and pushed to Backend `main` at `d06f363`; merged `main` was re-verified with full unit, E2E, ESLint, and build passing.

Acceptance:
Keep a cheap liveness probe and add a bounded readiness probe that verifies the dependencies required to serve production traffic. Mongo connectivity must be represented; S3 readiness must use a safe non-mutating capability/configuration check appropriate to deployed permissions. Tests cover healthy/unready states and deployment docs/config identify which probe should gate traffic.

### P2-14 — Make Action Center notification deduplication reopen-safe

Status: DONE  
Area: Backend / Notifications / Reliability

Progress (2026-08-28):
- Re-verification against current Backend `main` found that P2-21 already closed this reliability gap in commit `636756b`, which is an ancestor of current `main` `d06f363`.
- `createNotification()` now uses one atomic `findOneAndUpdate({ notificationKey }, ..., { upsert: true })` path for keyed notifications. Existing resolved/dismissed documents are reactivated in place, `resolvedAt`/`dismissedAt` are cleared, and `isRead` resets to false; the globally unique key therefore remains the stable logical-condition identity instead of causing a duplicate insert.
- Active deduplication remains one document per `notificationKey`; callers using the same logical key update/reactivate the existing record rather than creating another Action Center item.
- Focused NotificationsService regression coverage explicitly verifies reopen-safe atomic upsert behavior. Re-verification on 2026-08-28 passed 5/5 focused notification tests, full Backend unit tests passed 121 with 15 integration tests skipped by the default suite, ESLint passed, production build passed, and `git diff --check` passed.
- No new application-source change was required for P2-14; this TODO correction records functionality already merged through P2-21 rather than duplicating the implementation.

Acceptance:
The same logical condition can transition `active → resolved/dismissed → active` without duplicate-key errors. Define and test whether the existing document is reactivated or a versioned occurrence identity is created; active deduplication must continue preventing duplicate Action Center items.

### P2-15 — Add browser E2E smoke coverage for critical workflows

Status: DONE  
Area: Frontend + Backend / Quality / Regression safety

Progress (2026-08-28):
- Added Playwright as a Frontend dev dependency plus reproducible `npm run test:e2e:browser` coverage using Chromium, a local Next.js dev server, and a controlled local mock Backend. No production credentials or production data are required.
- Browser smoke coverage now exercises: protected cashier-route redirect + login/session restoration, a Quick Sale cash checkout through the real UI/BFF with controlled catalog/order responses, and anonymous multipart upload through the public `/upload` UI/BFF contract.
- The mock Backend implements only the minimal auth, current-user, Quick Product, Action Center, Order, tracking-access, upload, and health contracts required by the smoke suite. Test artifacts are ignored from Git.
- During authoring, browser execution exposed a separate pre-hydration native login-form GET that can place credentials in the URL; that security issue is intentionally tracked separately as P1-10 rather than being silently changed inside this quality task. The smoke helper waits for application hydration before exercising the intended login contract.
- Verification passed on the feature branch and again after merge to `main`: browser E2E 3/3, Frontend Node tests 142/142, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check` all passed.
- Feature commit `6ec7432` from `test/p2-15-browser-smoke` was pushed, fast-forward merged, and pushed to Frontend `main` at `6ec7432`; `HEAD` matches `origin/main`. Backend was not changed.
- The pre-existing/build-generated Frontend `next-env.d.ts` working-tree change was preserved and excluded from the task commit. Post-merge local and remote branch cleanup was attempted but denied by lnwjud destructive-Git policy, so the fully merged branch remains preserved without bypassing protection.

Acceptance:
Add a reproducible browser E2E smoke command covering at minimum authentication/route guard behavior, one cashier checkout path, and the anonymous upload contract. Tests use controlled test data/environment, are deterministic enough for automated verification, and do not require production credentials.

### P2-16 — Expand public Order Tracking into a customer-safe milestone contract

Status: DONE  
Area: Frontend + Backend / Customer Tracking

Progress (2026-08-28):
- Public `POST /tracking/lookup` keeps the existing exact order identity + phone suffix verifier and rate-limit boundary, but the response no longer exposes raw internal `status`.
- Backend now projects Order history into customer-safe milestones: `received`, `in_progress`, `ready`, `completed`, and `cancelled`, returning only the public milestone name and timestamp. Internal notes, actors, payment/financial statuses, customer/contact data, cart data, audit data, and detailed financial facts are not included.
- Financial statuses such as `awaiting_payment`, `partial`, and `paid` do not overwrite the latest customer workflow milestone; regression coverage verifies a paid Order can remain customer-facing `ready` when that is its latest workflow state.
- Frontend `/track` was minimally adapted to consume the new milestone contract without doing the P2-17 timeline redesign early; customer-friendly milestone copy replaces raw internal status wording.
- Backend focused tracking tests passed 6/6; full Backend unit, E2E 30/30, ESLint, build, and `git diff --check` passed. Frontend tests passed 109/109; ESLint, production build, UTF-8 check, and `git diff --check` passed.
- Backend feature commit `4ecbdda` and Frontend feature commit `cffccb4` were pushed and merged. Backend `main` is `473e208`; Frontend `main` is `34c934f`, and both match `origin/main` with clean working trees.

Acceptance:
Introduce an explicit customer-facing milestone projection for the existing Order lifecycle (for example received / in progress / ready / completed) and return only customer-safe milestone/timestamp information. Preserve the existing verifier and rate limit. Do not expose customer name, full phone, cart details, internal status notes/actors, audit data, or detailed financial facts. Add regression coverage for the projection and privacy boundary.

### P2-17 — Redesign `/track` as a customer Order Tracking timeline

Status: DONE  
Area: Frontend / Customer Tracking / Responsive UX

Dependency:
P2-16 customer-safe tracking contract.

Progress (2026-08-28):
- Public `/track` now renders the customer-safe milestone contract as a responsive vertical timeline with distinct completed, current, upcoming, and cancelled states plus customer-friendly descriptions and reached timestamps.
- The current milestone is emphasized separately with the latest update time, while loading and lookup failure/not-found feedback remain explicit and mobile-safe.
- `?order=<orderNumber>` now prefills only the order-number field from the URL; the customer must still enter the phone suffix verifier and no phone data or other PII is read from or added to the query string.
- Added pure tracking helpers and focused coverage for URL order prefill, normal milestone ordering/state projection, and cancelled-flow rendering. Focused tracking tests passed 4/4; full Frontend tests passed 112/112, ESLint, production build/TypeScript, UTF-8 check, and `git diff --check` passed.
- Frontend feature commit `6a6439e` was pushed from `feature/p2-17-tracking-timeline`, merged, and pushed to `main` at `eb2950b`.

Acceptance:
Redesign the public tracking result into a clear responsive milestone/timeline experience for desktop and mobile, with current-state emphasis, last-update time, loading/not-found/error states, and customer-friendly status wording. Support `?order=<orderNumber>` prefill for links/QR codes while still requiring the phone-suffix verifier; query parameters must not contain phone data or other PII. Add focused tests for URL prefill and status/timeline rendering helpers.

### P2-18 — Add Order Tracking QR to customer documents

Status: DONE  
Area: Frontend / Receipt + Invoice / Customer Tracking

Dependency:
P2-17 tracking page contract.

Progress (2026-08-28):
- Customer-facing thermal receipts and tax-invoice copies now include a scannable Order Tracking QR when the print page has a valid HTTP(S) origin.
- The generated destination is exactly `/track?order=<orderNumber>` on the current public origin; phone verifier data, session data, access tokens, and customer PII are never added to the QR URL.
- QR rendering fails closed when an absolute origin is unavailable/unsupported, while the receipt/invoice remains printable and readable without the QR.
- Added shared URL-generation regression coverage plus receipt/tax-invoice rendering coverage for QR presence, PII exclusion, and no-QR fallback.
- Frontend verification passed on the feature branch and merged `main`: 117/117 tests, ESLint, production build/TypeScript, UTF-8 check, and `git diff --check`.
- Frontend feature commit `bf78254` was pushed from `feature/p2-18-tracking-qr`, merged, and pushed to `main` at `b4b22de`.

Acceptance:
Add a scannable QR/link to appropriate customer-facing receipt/print documents that opens the public tracking page with only the order number prefilled. Do not embed phone number, session data, access tokens, or customer PII in the QR. Keep printed documents readable when QR generation is unavailable and add regression coverage for the generated tracking URL.

### P2-19 — Create Inventory Phase 1 domain and auditable stock movement ledger

Status: DONE  
Area: Backend / Inventory / Data integrity

Current evidence (2026-08-28):
No inventory/stock domain was registered in the Backend source tree before this task. GlossyDesign needs material stock rather than only finished-goods quantities (paper, sticker media, PVC, ink, binding/finishing supplies, etc.).

Progress (2026-08-28):
- Added Backend `InventoryModule` with `StockItem` and append-only `StockMovement` collections. New stock items start at zero on-hand so opening stock must be represented by a movement fact rather than an unexplained initial balance.
- Movement semantics cover `receive`, `issue`, `adjustment_in`, `adjustment_out`, and `waste`; the server maps each command to its signed delta and records actor, time, reason, optional business reference, resulting balance, and a command fingerprint.
- Quantity changes use transactional atomic `$inc` updates. Outbound movement filters include an on-hand `$gte` predicate so concurrent withdrawals cannot create a negative balance, and the movement fact is committed in the same Mongo transaction as the balance update.
- Optional movement idempotency keys are uniquely stored and bound to the canonical actor/item/type/quantity/reason/reference command. Same-command retries return the original fact; conflicting key reuse is rejected.
- Focused unit tests passed 8/8. Replica-set Mongo integrity coverage passed 3/3 for five concurrent inbound mutations, competing outbound mutations against one balance, and five concurrent same-key retries. Full Backend unit tests, E2E 30/30, ESLint, build, and `git diff --check` passed before merge.
- Feature commit `44516d9` was pushed from `feature/p2-19-inventory-ledger`, merged and pushed to Backend `main` at `54ccbf5`. Merged `main` was re-verified with full unit tests, ESLint, and build passing.
- Product/BOM-driven automatic deduction and stock management UI/API workflow remain intentionally deferred to P2-20+.

Acceptance:
Add an Inventory module with an explicit Stock Item model and append-only Stock Movement facts. At minimum support receive, issue/use, adjustment-in, adjustment-out, and waste movement semantics with actor/time/reason and optional business reference. The server owns movement direction and resulting on-hand quantity; normal workflows must not silently rewrite/delete movement history or produce an unexplained negative balance. Concurrent mutations must not lose stock updates, and focused tests cover movement arithmetic/retry/concurrency boundaries. Product/BOM auto-deduction is explicitly out of Phase 1.

### P2-20 — Add Stock management APIs and admin workflow

Status: DONE  
Area: Frontend + Backend / Inventory

Dependency:
P2-19 inventory ledger.

Progress (2026-08-28):
- Added authenticated Backend stock-item list/detail endpoints plus Manager/Admin-controlled item create/update/deactivate. Search covers stock code, name, and unit while inactive items remain opt-in for management views.
- Added movement API for `receive`, `issue`, `adjustment_in`, and `adjustment_out`. Authenticated staff may receive/issue stock; manual adjustment is enforced at the Backend boundary for Manager/Admin only. All quantity changes continue through the P2-19 transactional append-only movement ledger with reason, actor, non-negative balance guard, and optional idempotency key.
- Added audit events for stock item create/update and movement recording. The existing P2-19 `waste` ledger semantic remains available internally but is intentionally not exposed by the P2-20 management command DTO because this task's workflow scope is receive/issue/manual adjustment.
- Added responsive Frontend `/home/stock` and sidebar menu. The page supports searchable inventory, current on-hand quantity/unit/minimum level, low-stock indication, receive/withdraw dialogs, Manager/Admin adjustment controls, item create, and activation/deactivation. Frontend role gating is UX only; Backend authorization remains authoritative.
- Backend verification passed before merge: full unit tests, E2E 30/30, ESLint, build, and staged `git diff --check`; merged `main` was re-verified with full unit tests, ESLint, and build passing. Frontend verification passed before merge: full tests, ESLint, production build/TypeScript/UTF-8, and staged `git diff --check`; merged `main` was re-verified with full tests, ESLint, production build, and UTF-8 prebuild passing.
- Backend feature commit `77ebaeb` was merged and pushed to `main` at `01cda9f`. Frontend feature commit `5b2b823` was merged and pushed to `main` at `46b25d8`; both merged HEADs match `origin/main`. The pre-existing Frontend `next-env.d.ts` working-tree change was preserved and excluded from the P2-20 commit.
- Post-merge branch cleanup was attempted, but lnwjud Git protection denied both remote-ref deletion and local branch deletion as destructive operations. The fully merged feature branches are therefore preserved; no force/delete protection was bypassed. Earlier clean setup worktrees/branches created while attempting isolation are also preserved rather than removed through protected destructive Git operations.

Acceptance:
Provide authenticated stock-item listing/detail plus controlled item create/update/deactivate and movement commands for receive, issue/use, and manual adjustment. Add a responsive Stock menu/page with searchable inventory, current quantity/unit/minimum level, and clear receive/withdraw/adjust flows. Backend authorization is the security boundary; initial privileged metadata/manual-adjustment actions should use existing Manager/Admin capability patterns rather than frontend-only hiding. Preserve movement evidence for every quantity change.

### P2-21 — Add low-stock detection to Action Center

Status: DONE  
Area: Frontend + Backend / Inventory / Action Center

Dependency:
P2-19 inventory ledger.

Progress (2026-08-28):
- Backend Action Center now reconciles active Stock Items whose `onHand <= minimumLevel` into one `low_stock` action per item, including current quantity/unit and configured minimum level.
- Low-stock actions use stable keys `low_stock:<stockItemId>`. Notification creation now uses an atomic key-based upsert that reactivates the existing document and clears resolved/dismissed timestamps, so repeated `active → resolved → active` threshold crossings reuse the same key without duplicate-key failures.
- Low-stock notifications are automatically resolved from current inventory state when quantity rises above threshold or the Stock Item is deactivated. Reconciliation runs before each Action Center snapshot so missed/transient mutation-side notification writes cannot permanently desynchronize the queue from stock truth.
- Actions deep-link to `/home/stock?focus=<stockItemId>`; the Stock page reads the focus target, scrolls to the item, and visually emphasizes it. Action Center renders low-stock items with Stock context/icon.
- Backend focused lifecycle tests passed 5/5; full Backend unit tests passed 111 with 15 integration tests skipped by the default suite, E2E 30/30, ESLint, build, and `git diff --check` passed. Frontend full tests passed 127/127, ESLint, production build/TypeScript, UTF-8 check, and `git diff --check` passed.
- Backend feature commit `636756b` was merged and pushed to `main` at `6d8f9e5`. Frontend feature commit `9d58098` was merged and pushed to `main` at `98921c9`.
- Frontend build regenerated a local `next-env.d.ts` working-tree change; it was intentionally excluded from the task commit and preserved rather than discarded.

Acceptance:
When active stock falls at or below its configured minimum level, surface one deduplicated actionable low-stock item with current quantity/unit and deep-link to the Stock item. Resolve it automatically after quantity rises above threshold or the item is deactivated. Repeated threshold crossings must be reopen-safe and must not create duplicate-key failures. Add Backend lifecycle tests and Frontend action/deep-link coverage.

### P2-22 — Add Stock dashboard and movement history

Status: DONE  
Area: Frontend + Backend / Inventory / Reporting

Dependency:
P2-19 and P2-20.

Progress (2026-08-28):
- Backend added authenticated `GET /inventory/overview` and server-paginated `GET /inventory/movements`. The overview reports total active items, low-stock count, and recently moved Stock Items; movement history exposes item/type/date/search filters plus actor, reason, business reference, signed quantity, resulting balance, and material unit.
- Movement search resolves matching Stock Item code/name/unit plus movement reason/actor/reference. The complete filter is used for `countDocuments()` before `skip/limit`, so counts and pagination represent the full filtered result rather than only the loaded page.
- Frontend `/home/stock` now shows overview counters, recently moved materials, and a responsive movement-history table with item/type/date/search filters and server pagination. Existing receive/issue/adjustment management flows remain intact and refresh the reporting view after successful mutations.
- Regression coverage includes filtered-history count-before-pagination behavior and Frontend movement-filter query serialization. Backend verification passed: 115 unit tests with 15 integration tests skipped by the default suite, E2E 30/30, ESLint, build, focused inventory tests, and `git diff --check`. Frontend verification passed: 131/131 tests, ESLint, production build/TypeScript, UTF-8 validation, and task-file `git diff --check`.
- Backend feature commit `3866a20` was fast-forward merged and pushed to `main` at `3866a20`. Frontend feature commit `1ff4215` was fast-forward merged and pushed to `main` at `1ff4215`; both `HEAD` values match `origin/main` after push.
- Frontend `next-env.d.ts` remains as a build-generated local working-tree change and was deliberately excluded from the task commit. Local and remote cleanup of the fully merged feature branches was attempted but denied by lnwjud destructive-Git policy, so those refs are preserved without bypassing protection.

Acceptance:
Add a Stock overview showing total active items, low-stock count, recently moved items, and a server-paginated movement history with item/type/date/search filters. Quantities and units must remain understandable for print-shop materials, and history must make actor/reason/reference visible to authorized staff without exposing secrets. Filtering/counts must be computed before pagination. This phase does not calculate accounting COGS or automatically consume stock from Orders.

### P2-23 — Complete the storefront Order Tracking flow

Status: DONE  
Area: Frontend + Backend / Orders / Customer Tracking / POS

Problem confirmed (2026-08-28):
- Public tracking currently requires `orderNumber + phoneSuffix`, so Quick Sale / walk-in customers with no phone number cannot use the QR that is printed on their receipt.
- Receipt QR currently contains only `?order=<orderNumber>`, so scanning it still lands on the verifier form instead of granting a safe read-only tracking capability.
- Backend already supports workflow updates (`pending → producing → ready_for_pickup → delivered`) and customer-safe milestones, but the Orders UI exposes no normal status-progression control. Staff can view the timeline and cancel an Order, yet cannot advance production status from the primary workflow screen.

Implementation direction:
- Add a high-entropy opaque tracking capability that is issued/retrieved only through authenticated staff Order APIs, is not returned in normal Order lists, and can be used by a public rate-limited tracking lookup without phone data.
- Keep the existing `orderNumber + phoneSuffix` verifier as a fallback for Orders that have a phone number; do not downgrade to order-number-only tracking.
- Put the secure QR on customer-facing receipt/invoice output and the post-checkout success experience so walk-in customers can capture it immediately.
- Add an explicit staff workflow control in the Order detail drawer for the supported progression while keeping financial statuses server-derived and cancellation separate.

Progress (2026-08-28):
- Added a 256-bit opaque tracking capability for each Order. Authenticated staff can issue/retrieve it through `POST /orders/:id/tracking-access`; normal Order list/detail responses do not expose the token, while public lookup uses only its SHA-256 hash through rate-limited `POST /tracking/token`.
- Public token tracking returns the same milestone-only privacy contract as phone-suffix lookup. Existing `orderNumber + phoneSuffix` verification remains available and order-number-only access was not introduced.
- Receipt/tax-invoice printing, configured POS success, and Quick Sale success now use the secure `/track?t=<token>` QR when access is available; tracking preparation is best-effort and cannot invalidate an already completed sale/print flow.
- Added a separate production `workflowStatus` (`pending → producing → ready_for_pickup → delivered`, plus cancellation) so staff can advance customer workflow from the Order detail drawer without overwriting server-derived financial status. Existing tax-invoice and cancellation actions were preserved.
- Frontend verification passed: 123/123 tests, ESLint, production build/TypeScript, UTF-8 validation, and `git diff --check`. Backend verification passed: full unit suite, E2E 30/30, ESLint, build, and `git diff --check`.
- Backend feature commit `13628c8` was merged and pushed to `main` at `07ea4a9`. Frontend feature commit `8120fa7` was fast-forward pushed to `main` at `8120fa7` after verifying `origin/main` was its ancestor. A build-generated local `next-env.d.ts` change was intentionally excluded from the task commit and preserved because non-interactive Git protection does not permit discarding working-tree changes.

Acceptance:
A walk-in Order with no phone number can be tracked by scanning its secure QR; possessing only an Order number is insufficient. Normal public tracking responses remain milestone-only and do not expose PII/financial/internal notes. Staff can advance supported workflow states from Orders and the resulting customer timeline changes accordingly. Existing phone-suffix lookup remains compatible. Focused Backend/Frontend tests plus full lint/build pass before merge.

### P2-24 — Align Dashboard with operational workflow and executable drill-downs

Status: DONE  
Area: Frontend + Backend / Dashboard / Orders / Stock / Uploads

Progress (2026-08-28):
- Resumed the pre-existing `feature/dashboard-workflow-overhaul` WIP before selecting a new TODO, preserving concurrent edits rather than resetting or overwriting them.
- Dashboard now separates period-based sales/reporting metrics from current operational counters for `pending`, `producing`, `ready_for_pickup`, outstanding balances, uploads waiting for review, and low-stock items.
- Order drill-downs use the production `workflowStatus` contract and preserve supported report date state (`today`, month, or custom range); Orders list/export now forward workflow status to Backend reporting.
- Backend reporting derives an effective workflow status from canonical `workflowStatus`, legacy status history, or compatible legacy status. Legacy rows with no classifiable workflow state are counted explicitly as `unclassifiedWorkflow` instead of being silently indistinguishable from normal pending work; the Dashboard surfaces that condition to staff.
- Backend Dashboard operational snapshot regression coverage was added, including current pending-upload and low-stock counts. No inventory movement/accounting behavior or Order financial-state mutation was introduced.
- Verification passed before merge and again on merged `main`: Frontend 130/130 tests, ESLint, production build/TypeScript, UTF-8 validation, and diff check; Backend 114 unit tests passed with 15 integration tests skipped by the default suite, E2E 30/30, ESLint, build, and diff check.
- Frontend feature commits `cc46d2c` and `6644b08` were merged and pushed to `main` at `8c01bff`. Backend feature commits `65368a2` and `4af8e03` were merged and pushed to `main` at `435c2da`.

Acceptance:
Dashboard operational counters reflect actionable current workflow state rather than financial status, report-period links land on executable Orders filters, legacy unclassified workflow rows are visible rather than silently lost, and merged Frontend/Backend verification remains green.

### P2-25 — Finish Action Center migration to the separated production workflow

Status: DONE  
Area: Backend + Frontend / Notifications / Orders / Reliability

Fresh-scan evidence (2026-08-29):
- `checkAndNotifyOverdueOrders()` and `checkAndNotifyUnconfirmedOrders()` still query the legacy mixed `Order.status` (`pending`/`producing`) even though production truth now lives in `workflowStatus`/effective workflow.
- No active call site was found for either helper, despite `order_overdue` being an Action Center type; the comments themselves describe them as something a scheduled task would call.
- `autoResolvePickupNotifications()` reloads an Order and checks financial `order.status` for `delivered`/`paid`. A delivered Order with an outstanding balance can therefore leave a stale ready/pickup action because delivery is represented by `workflowStatus`, not financial `status`.
- A real due-date/SLA model does not exist yet; Dashboard explicitly reports `dueDates: false` and `urgentFlag: false`, so an invented "30 minutes since create" rule must not become production SLA by accident.

Progress (2026-08-29):
- Action Center ready/pickup lifecycle now resolves from effective production workflow, including legacy workflow history fallback, and `delivered` resolves pickup actions regardless of whether the financial state is paid or still outstanding.
- Notification status-change handling now accepts workflow statuses only; mixed financial statuses such as `paid`, `partial`, and `awaiting_payment` are no longer treated as production milestones.
- Retired `order_overdue` from the active Action Center type set and made the dormant createdAt-based overdue/unconfirmed helpers explicit no-ops until P2-27 introduces a real `dueAt`/SLA model.
- Regression coverage verifies delivered+outstanding, delivered+paid, paid-but-still-ready, and dormant pseudo-SLA behavior. Focused Notifications/Orders tests passed 33/33; full Backend unit passed 133 with 15 integration tests skipped by the default suite; E2E 30/30, ESLint, production build, and `git diff --check` all passed.
- Feature commit `01e1e78` from `fix/p2-25-action-center-workflow` was pushed, fast-forward merged, and pushed to Backend `main` at `01e1e78`; merged `main` was re-verified with the full unit/E2E/lint/build suite.

Acceptance:
- Ready/pickup lifecycle derives from effective production workflow; moving to `delivered` resolves ready/pickup actions regardless of whether payment remains outstanding, while payment actions continue to follow payment facts independently.
- Remove, explicitly retire, or safely defer dormant createdAt-based overdue/unconfirmed rules until the Production Job due-date model exists; do not silently activate the hard-coded 30/60-minute pseudo-SLA.
- No notification rule treats financial `paid/partial/awaiting_payment` as a production milestone.
- Add focused tests for `ready → delivered` with both paid and outstanding balances, plus regression evidence that dormant legacy rules cannot create misleading Action Center state.
- Preserve P3-08 as the separate client polling/performance task.

### P2-26 — Link customer Upload intake to Orders with collision-safe intake identity

Status: DONE  
Area: Frontend + Backend / Uploads / Orders / Storage

Fresh-scan evidence (2026-08-29):
- Public Upload creates its own `orderCode` in the form `GL-YYYYMMDD-####`; `CreateUploadDto`/Upload schema have no real Order id/order number relation.
- Dashboard currently reports `uploads.unlinked: 0` and capability `uploadOrderLink: false`, so the system cannot truthfully distinguish customer files that have been attached to a sale from unassigned intake.
- The four-digit daily random suffix has a unique index but create has no collision retry. A duplicate code causes the persisted upload attempt to fail after object handling instead of allocating another display identity.

Progress (2026-08-29):
- Preserved Upload intake identity separately from sales Order identity and strengthened new intake codes to `GL-YYYYMMDD-XXXXXXXX`; duplicate-key allocation now retries up to five times without deleting already-uploaded S3 objects, while legacy stored `orderCode` values remain readable.
- Added authenticated `PATCH /uploads/link-order` for link/unlink/reassign against an existing Order, storing canonical linked Order id/number and recording `upload.order_link` / `upload.order_unlink` audit events. Public `POST /uploads` still has no linkage field; E2E verifies a guessed `orderReference` is rejected before create.
- Storage now exposes linked/unlinked and Order-reference filters, shows intake/link state, and provides link/reassign/unlink controls. Order detail links back to `/home/storage?order=...` for related customer files.
- Dashboard `uploads.unlinked` now counts the real missing linkage relation and advertises `uploadOrderLink: true`; grouped Storage list filtering uses the same persisted relation.
- Verification before merge passed: Frontend 145/145 Node tests, ESLint, TypeScript, UTF-8, production build, Playwright browser smoke 5/5, and `git diff --check`; Backend focused Upload/Dashboard 9/9, full unit 135 passed with 15 integration tests skipped by the default suite, E2E 31/31, ESLint, production build, and `git diff --check`.
- Backend feature commit `d0bf240` and Frontend feature commit `caea520` were pushed, fast-forward merged, and pushed to `main`. Merged `main` re-verification passed Frontend 145/145 tests and Backend 135 unit + 31/31 E2E; `HEAD == origin/main` at Backend `d0bf240` and Frontend `caea520`. Existing Frontend `next-env.d.ts` WIP remained uncommitted and preserved.
- Local and remote branch cleanup for `feature/p2-26-upload-order-link` was blocked by destructive-Git policy in both repositories; the already-merged branches were preserved and no protection was bypassed.

Acceptance:
- Treat Upload intake identity and sales Order identity as separate concepts. Introduce a stable collision-safe upload/intake code without breaking existing stored records or public upload receipts.
- Add an optional protected linkage from an Upload/batch to an existing Order. Anonymous public create must not be able to attach itself to an Order merely by guessing an Order number/id.
- Storage staff can link/unlink or reassign an intake record through an authenticated workflow with audit evidence; the related Order can navigate back to its files.
- Dashboard `uploads.unlinked` and relevant Storage filters/counts use the real relation rather than a hard-coded zero.
- Duplicate intake-code allocation is retried/allocated atomically and has focused collision tests.
- Preserve S3 ownership/recovery and public upload privacy/security contracts from P1-06/P2-03/P2-04.

### P2-27 — Introduce a Production Job domain for print-shop operations

Status: DONE  
Area: Frontend + Backend / Production / Orders / Staff

Dependency:
P1-11 workflow integrity and P2-26 Upload↔Order linkage should be complete or explicitly accounted for first.

Product design (2026-08-29):
GlossyDesign needs a production object richer than the coarse customer milestone but separate from financial Order truth. A Production Job should represent the work the shop must execute, not another copy of payment totals.

Initial scope:
- One Order may own one or more production jobs when separate items/batches genuinely need independent execution; immediate Quick Sale items do not require a production job by default.
- Internal stages: `file_check → queued → producing → quality_check → ready → delivered`, plus controlled cancellation inherited from the approved Order policy.
- Operational fields: due date/time in Asia/Bangkok, `normal | rush` priority, optional assigned staff member, internal production note, linked Order, linked Upload/batch references, and append-only stage history with actor/time.
- Internal stages project to the existing customer-safe Tracking milestones instead of creating a second independent public truth. Detailed internal notes/assignee data remain private.

Progress (2026-08-29):
- Added a Backend `ProductionModule` and persisted Production Job model owned by an existing Order. Jobs carry a collision-safe `PJ-YYYYMMDD-XXXXXXXX` identity, work summary, `dueAt`, `normal | rush` priority, optional active-user assignee, internal note, linked Upload ids, current stage, and append-only actor/time stage history. Existing Orders are not backfilled or silently auto-created into jobs.
- Server transition integrity is forward-only `file_check → queued → producing → quality_check → ready → delivered`, exact same-stage retries are idempotent, and progression uses an atomic current-stage predicate so concurrent callers cannot append an impossible history sequence. Cancellation remains outside this graph and is governed separately by P1-02 under DEC-013.
- Linked Uploads must already be attached to the same Order through the P2-26 relation. List/detail responses expose normalized shop-floor data plus derived Bangkok due-time, rush/overdue state, and customer-safe milestone projection without copying Order payment totals, contact data, or other financial/customer PII. Production Job mutations do not update Order financial status.
- Added authenticated list/detail/create/update/stage APIs and audit events. Focused ProductionService tests passed 4/4; full Backend unit passed 139 with 15 integration tests skipped by the default suite; E2E passed 31/31; ESLint, production build, and `git diff --check` passed. The same unit/E2E/lint/build suite passed again on merged `main`.
- Feature commit `463e154` from `feature/p2-27-production-jobs` was pushed, fast-forward merged, and pushed to Backend `main` at `463e154`; `HEAD == origin/main` after verification. Frontend source was not changed and its existing `next-env.d.ts` WIP remained preserved.

Acceptance:
- Add a tested Production Job model/API with explicit Order ownership, dueAt, priority, assignee, stage, linked file references, and auditable stage history.
- Server owns the legal job-stage transitions and customer milestone projection. Order financial status is never mutated by a production-job update.
- Due-date semantics use Asia/Bangkok consistently; overdue/rush state is derived, not stored as an unexplained boolean where avoidable.
- Jobs expose enough normalized data for a board/list UI without returning secrets or unrelated financial/customer PII.
- Define behavior for legacy Orders with no Production Job and avoid silently creating thousands of historical jobs without an explicit migration plan.

### P2-28 — Add a responsive Production Board menu and Job Ticket workflow

Status: DONE  
Area: Frontend + Backend / Production UX

Dependency:
P2-27 Production Job domain.

Menu design:
Add `งานผลิต` under `OPERATIONS`, positioned before `คลังไฟล์ลูกค้า` and `สต็อกวัสดุ`. The menu is the shop-floor work queue; `/home/orders` remains the sales/payment/document record and must not become a giant production dashboard.

Progress (2026-08-29):
- Added `/home/production` plus the first `OPERATIONS` menu item `งานผลิต`, with responsive Kanban and compact list/table views. Filters cover stage, due today/overdue, rush/normal, assignee/my work, optional free-text job type, and search by Job/Order/work/customer while keeping customer PII out of Production responses.
- Added a responsive Job Ticket drawer with work specs, due/rush state, assignee/reassign-to-self, linked customer-file jumps, internal note editing, append-only stage history, customer-safe Tracking projection, authoritative Order jump, and a later-compatible stock-reference placeholder. Payment totals are not copied into the Production UX.
- Production actions reuse the P2-27 server transition boundary and only expose the next legal stage. Backend adds backward-compatible optional `jobType`, active-assignee lookup, and customer-name search through Order ids without returning customer details.
- Verification passed: Frontend focused tests 10/10, full unit 148/148, browser E2E 6/6 including `file_check → queued → producing → quality_check → ready`, ESLint, UTF-8 and production build; Backend focused ProductionService 5/5, full unit 140 passed with 15 integration tests skipped by the default suite, E2E 31/31, ESLint and production build; `git diff --check` passed in both repositories.
- Feature branch `feature/p2-28-production-board` was pushed and fast-forward merged to Frontend `main` at `45be076` and Backend `main` at `4405283`, then both `main` branches were pushed to origin.

Acceptance:
- `/home/production` provides responsive Kanban and compact list/table views over production stages, with filters for due today/overdue, rush, assignee, job type, and search by Order/customer/job.
- Cards show only actionable shop-floor context: Order/job number, work summary, due time, rush indicator, assignee, file-link state, and current stage. Do not make payment totals the visual focus of the board.
- Staff can advance one legal stage at a time, assign/reassign themselves or permitted staff, open linked customer files, and jump to the authoritative Order detail.
- A Job Ticket detail drawer/page shows production specifications, internal notes, linked files, stage history, Tracking projection, and later-compatible stock references.
- Mobile uses a stage filter/segmented view rather than forcing a desktop-width Kanban off-screen; tablet/desktop may use columns.
- Actions use the P2-27 server transition boundary and include browser E2E coverage for one normal job from intake through ready.

### P2-29 — Add a Customer directory / lightweight CRM for repeat business

Status: DONE  
Area: Frontend + Backend / Customers / POS / Orders / Privacy

Fresh-scan evidence (2026-08-29):
Customer/contact/tax data is denormalized into each Order and there is no Customer module/menu. Repeat customers must therefore be re-entered and there is no authoritative place to view their order history or reusable billing profile.

Menu design:
Add `ลูกค้า` under `SALES` after `รายการขาย`, because its main purpose is faster repeat sales and service history rather than system administration.

Progress (2026-08-29):
- Added an authenticated Backend Customer domain with explicit collision-safe customer codes, searchable contact/tax profile fields, active/inactive lifecycle, audited create/update commands, and no name/phone auto-merge behavior. Walk-in Orders remain valid without `customerId`.
- Orders may now carry an optional Customer ObjectId relation while preserving the existing denormalized billing/contact fields as the immutable historical sale/document snapshot; Customer edits do not rewrite prior Orders.
- Customer detail derives order history, current outstanding balance, active Production Jobs, and linked Upload intake through authorized server-side queries. Financial truth remains on Orders/payment facts rather than being copied into Customer documents.
- Added `/home/customers` after `รายการขาย` with responsive card/drawer UX, search/create workflow, order history/outstanding summary, active-job context, and linked-file navigation. Configured POS can select a saved Customer and safely prefill contact/tax/address data while carrying the Customer identity into Order creation.
- Customer APIs remain behind the authenticated Backend guard and are not added to the Frontend public BFF allowlist. Backend E2E explicitly rejects anonymous Customer list/detail access and permits authenticated staff; Frontend allowlist regression coverage also keeps Customer routes private.
- Verification passed before merge: Frontend Node tests 149/149, browser E2E 6/6, ESLint, UTF-8 validation, production build/TypeScript, and staged `git diff --check`; Backend focused Customer service 3/3, full unit 143 passed with 15 integration tests skipped by the default suite, E2E 33/33, ESLint, production build, and staged `git diff --check`.
- Feature commit `9498b65` was pushed and fast-forward merged to Frontend `main`; Backend feature commit `bfbc8f6` was pushed and fast-forward merged to Backend `main`. Merged-main verification passed Frontend 149/149 Node tests + production build and Backend 143 unit + 33/33 E2E + production build; both `HEAD == origin/main` at those SHAs.
- Follow-up WIP on `feat/customer-multi-phone-import-2026-08-29` was resumed instead of starting a new TODO. It extends Customer profiles/import with multiple phone numbers, safe dry-run/import support, profile edit/clear semantics, server-side customer list filtering/pagination, and a fuller responsive customer detail workflow. Frontend branch commit `0b99bb6` and Backend branch commit `0763c82` were pushed and fast-forward merged to `main` at the same SHAs. Pre-merge verification passed Frontend 171/171 tests, ESLint, UTF-8, production build/TypeScript, and diff checks; Backend 161 unit tests with 15 default-suite integration skips, E2E 35/35, ESLint, production build, and diff checks. Merged-main re-verification passed Frontend 171/171 tests and ESLint plus Backend 161 unit, E2E 35/35, ESLint, and build; the final Frontend merged-main production-build retry is still running after an initial transient "another next build process" contention, so branch cleanup remains deferred until that final check completes.

Acceptance:
- Add a Customer profile domain with explicit identity rules; never auto-merge people merely because names are equal. Walk-in/anonymous sales remain valid without a Customer record.
- Authenticated staff can search/select a saved customer during POS checkout and safely prefill contact/tax-address data; edits follow role/privacy rules and are audited where appropriate.
- Customer detail shows order history, current outstanding balance summary, active production jobs, and linked uploads using authorized server queries rather than copying financial truth into the Customer document.
- Existing Orders keep their historical snapshot of billing/contact fields so later Customer edits do not rewrite issued document history.
- No Customer endpoint becomes public through Tracking/Upload routes; add privacy/RBAC tests and responsive mobile UX.

### P2-30 — Add material recipes/BOM and auditable job stock consumption

Status: DONE  
Area: Frontend + Backend / Catalog / Inventory / Production

Dependencies resolved by DEC-011 (2026-08-31):
P2-27 Production Job exists and Product/Variant is now the approved canonical catalog owner for material recipes. Quick Seller presentation may map into that canonical identity while custom/ad-hoc lines remain explicit exceptions. Do not attach BOM truth to transient presentation names or silently guess recipes for custom work.

Progress (2026-08-31):
- Canonical Product and Variant records now own optional material recipes containing `stockItemId`, positive recipe quantity/unit, and an explicit `conversionFactor` whenever the recipe unit differs from the active Stock Item unit. Recipe writes validate active Stock Item identity and never infer missing conversions.
- Production Jobs may carry explicit `orderLineIndexes`; sibling Jobs cannot claim the same mapped Order line, and the mapping becomes immutable once material issue starts. `materialIssueStartedAt` locks the plan before the first stock movement so a partial failure/retry cannot silently change the authoritative recipe/order-line scope; legacy single-Job records without the new field remain supported.
- The server issues recipe material exactly at `queued → producing`, aggregates consumption by Stock Item, and records append-only Inventory `issue` movements linked to the Production Job and Order. Stable global idempotency keys are scoped to `productionJobId + stockItemId`, while ordinary manual movement keys remain actor-bound.
- Each automatic movement stores immutable Order/Job provenance plus a `recipeSnapshot` of the Product/Variant source, line quantity, recipe quantity/unit, conversion factor, stock unit, and issued quantity. Missing products/variants/recipes, inactive stock, invalid units, and insufficient stock fail visibly rather than guessing or rewriting history.
- `waste` is a separate movement fact and remains Manager/Admin-only for manual entry. Cost/COGS semantics were intentionally not introduced.
- Frontend `main` already contains the P2-30 execution surfaces for selecting Production Job Order lines, showing BOM/material-issued state, recipe contract normalization, and manual waste selection (introduced in commit `8065002` and verified on current Frontend `main` `2d36e58`). No additional Frontend source mutation was required in this final integration pass.
- Backend feature commit `94a82b8` was pushed on `feature/p2-30-bom`, fast-forward merged to `main`, and pushed to `origin/main` at the same SHA. Pre-merge verification passed 211 unit tests with 15 expected integration skips, E2E 37/37, replica-set Inventory concurrency 3/3, ESLint, production build/TypeScript, `git diff --check`, and `npm audit` with 0 vulnerabilities. Post-merge Backend `main` re-verification passed focused P2-30 tests 27/27, ESLint, and production build.

Acceptance:
- [x] Recipe/BOM ownership is attached to the approved canonical catalog model/variant, with units compatible with Stock Items and explicit conversion rules where required.
- [x] Starting the chosen production stage records idempotent append-only `issue` movements linked to Job/Order; retries cannot double-consume material.
- [x] Missing/incomplete recipes fail visibly and never silently guess consumption. Manager/Admin may perform an audited manual correction rather than rewrite movement history.
- [x] Waste remains a distinct movement fact with a reason and optional Job reference.
- [x] Cost/accounting COGS is not inferred unless a separate approved costing policy is introduced.

### P2-31 — Add cashier shift opening/closing and cash reconciliation

Status: BLOCKED  
Area: Frontend + Backend / Cashier / Financial operations

Product opportunity / blocker:
The system reports cash collections but has no shift/opening-float/cash-in-out/closing-count model. This is valuable for a cashier system, but discrepancy and correction semantics are financial policy and must be approved before implementation.

Proposed menu:
Add `กะเงินสด / ปิดกะ` under `SALES` or a cashier utility area once the owner approves the policy.

Decision required before implementation:
Define opening float, who may open/close a shift, cash-in/cash-out reasons, whether more than one cashier can share a drawer, expected-vs-counted cash calculation, discrepancy approval/reason requirements, reopening policy, and how refunds/reversals from P1-02 affect a closed shift.

Acceptance after policy approval:
- Shift has immutable open/close actor/time facts, opening float, authorized cash adjustments, expected cash from authoritative cash payments, counted closing cash, and an auditable discrepancy.
- PromptPay/non-cash receipts never inflate physical drawer expectation.
- Closed shifts cannot be silently edited; correction follows an approved append-only/reopen policy.
- Provide a mobile-safe cashier close flow plus daily/shift reconciliation report with tests around satang precision and concurrent close attempts.

### P2-32 — Add an executable Production Job creation workflow

Status: DONE  
Area: Frontend + Backend / Production / Orders

Fresh-scan evidence (2026-08-30):
- Backend already exposes authenticated `POST /production/jobs` with Order ownership, work summary, optional job type, `dueAt`, `normal | rush`, assignee, internal note, linked Upload validation, auditable initial `file_check` history, and collision-safe job numbering.
- Frontend `src/lib/production.ts` exposes list/get/update/advance helpers but no create command.
- `/home/production` has filters, refresh, stage progression, and Job Ticket editing, but no create action. A source-wide Frontend search found no executable `POST /production/jobs` workflow.

Progress (2026-08-30):
- Resumed existing WIP on `feature/p2-32-production-job-create` without touching unrelated Storage changes.
- Added a Production Board create dialog that searches existing Orders, captures work summary, Bangkok-local due date/time, priority, optional job type/assignee/internal note, and linked Upload ids; Backend remains the authorization and same-Order Upload validation boundary.
- Successful creation inserts the returned Job into the board and opens its Job Ticket; the create action is disabled while the request is in flight so the UI does not issue overlapping duplicate submissions.
- Added Bangkok datetime conversion coverage and browser E2E for search Order → create Rush Job → visible on board/detail.
- Verification passed before merge: Frontend Node tests 179/179, focused browser E2E 1/1, full ESLint, production build/TypeScript, UTF-8 commit hook, staged diff review, and `git diff --check`.
- Feature commit `e41ff3f` was pushed, fast-forward merged, and pushed to Frontend `main` at `e41ff3f`; merged-main Node tests passed 179/179. Backend source was not changed.
- Pre-existing Storage WIP in `src/app/home/storage/StorageTable.tsx` and `src/app/home/storage/page.tsx` remained uncommitted and preserved throughout switch/merge.

Acceptance:
- Authenticated staff can create a Production Job for an existing Order from an obvious workflow such as Order detail and/or Production Board.
- Creation captures work summary, due date/time in Asia/Bangkok, priority, optional job type/assignee/internal note, and only Uploads already linked to the same Order.
- Successful creation refreshes/opens the new Job and cannot silently create duplicate jobs on UI retry.
- Do not auto-create Production Jobs for historical Orders or Quick Sale items merely to populate the board.
- Add focused Frontend coverage plus browser E2E for create → visible on board/detail while preserving Backend authorization/audit rules.

### P2-33 — Make Production Board query semantics complete beyond 100 jobs

Status: DONE  
Area: Frontend + Backend / Production / Scalability / Search correctness

Progress (2026-08-30):
- Implementation was committed on `fix/p2-33-production-board-pagination` in both repositories and is now contained in `origin/main`: Frontend task commit `4ce38b8` (current `origin/main` `e321172`) and Backend `4ba0b82` (current `origin/main` `4ba0b82`). No unrelated WIP was discarded.
- Backend Production listing uses one aggregation pipeline: customer-name search joins Orders directly instead of materializing the first 100 matching Order ids; paged items/total and full-filter stage counts are returned from one `$facet` result.
- Frontend Production Board loads 50 rows per page with explicit total, stage counts, and a deduplicated `โหลดเพิ่ม` path, so work beyond the first page is visible instead of silently truncated.
- Merged-main verification now passes full Frontend unit tests, full Frontend ESLint, and production build/TypeScript; Backend full unit tests, ESLint, and production build also pass. Commit-scoped `git diff --check` passes for both `4ce38b8` and `4ba0b82`.
- Backend full E2E was re-run on merged main: 5 suites / 28 tests pass; the existing `uploads.e2e-spec.ts` suite still fails 7 tests because its test module does not provide the current `UploadsController` dependency `LineLoginService`. This is the same baseline harness failure recorded under P2-34 and is outside the P2-33 production diff.
- Focused browser regression for 51 jobs passed 1/1 on clean detached Frontend merged-main snapshot `e321172`: the Board showed 50/51, `โหลดเพิ่ม (50/51)` loaded `PJ-PAGING-051`, then showed 51/51 and hid the load-more control. The primary checkout/dev session remained untouched.
- Final repeat-work review (2026-08-30): Frontend `main == origin/main == d021c47`, Backend `main == origin/main == 4ba0b82`; P2-33 task commits remain ancestors. Current Frontend WIP is limited to three Customer/Orders files and was preserved. A focused browser rerun on the primary checkout was attempted but correctly stopped because the user's existing Next dev server (PID 26896) owns the project dev lock; it was not terminated. Comparing P2-33 task paths from verified snapshot `e321172` to current `d021c47` shows only the Production **list-view** rendering migrated to shared `DataTable`; paging/load-more, board rendering, stage-count, query serialization, E2E fixture, and mock-backend paging behavior are unchanged. Under the Governance SHA/path repeat-work guard, the existing 1/1 browser regression plus already-passed merged-main unit/lint/build and Backend verification remain applicable, so P2-33 is closed without disturbing user WIP or the running dev server.

Fresh-scan evidence (2026-08-30):
- Frontend `/home/production` always calls `listProductionJobs({ limit: 100, ... })`, stores only `response.items`, and has no pagination/load-more control or total indicator. Kanban columns and list view therefore silently omit matching work after the first 100 rows.
- Backend already returns `page`, `limit`, `total`, and `totalPages`, so the fixed Frontend cap is not a server-contract requirement.
- Backend customer-name search first resolves matching Orders with `.limit(100)` before applying their ids to the Production Job query, so a customer search can also miss valid jobs when more than 100 Orders match.

Acceptance:
- No matching Production Job is silently hidden by a fixed 100-row client fetch; provide server-backed paging/load-more or another bounded complete board contract.
- Stage totals/counts shown by the board represent the full active filter result rather than only the currently loaded page.
- Customer-name search does not truncate correctness at an arbitrary first 100 matching Orders; use a complete bounded server query/aggregation strategy.
- Mobile stage filtering and current due/priority/assignee/job-type/search behavior remain usable.
- Regression coverage includes more than 100 matching jobs and customer-name matches beyond the first 100 Orders.

### P2-34 — Make Customer CRM related-work results independent of the 100-Order history cap

Status: DONE  
Area: Backend + Frontend / Customers / Production / Uploads

Fresh-scan evidence (2026-08-30):
- `CustomersService.detail()` correctly aggregates `orderCount` and outstanding balance across all Customer Orders, but separately fetches only the latest 100 Orders for history.
- The service then derives `activeProductionJobs` and `linkedUploads` only from ids in that 100-row history slice. An older Order with an unfinished Production Job or linked Upload therefore disappears from Customer detail even though the summary still counts the Customer's full history.
- Frontend Customer detail presents those related-work arrays as operational context, so this is a correctness gap rather than merely a history-display limit.

Progress (2026-08-30):
- Backend Customer detail now derives active Production Jobs and linked Uploads from the complete Customer Order ownership set using Order-rooted `$lookup` pipelines, while the displayed recent Order history remains bounded at 100 rows.
- The lookup path uses the indexed `customerId` ownership boundary and joins to Production Job `orderId` / Upload `linkedOrderId` without materializing an unbounded application-side `$in` list.
- Added regression coverage for 101 Customer Orders where an older Order outside the visible 100-row history owns an active Production Job and linked Upload; both remain present in Customer detail.
- Verification passed for focused CustomersService 5/5, full Backend unit 188 passed with 15 integration tests skipped by the default suite, full ESLint, production build, merged-main focused CustomersService 5/5, and `git diff --check`.
- Full Backend E2E was also attempted: 5 suites / 28 tests passed, while the existing `uploads.e2e-spec.ts` suite failed because its test module does not provide the current `UploadsController` dependency `LineLoginService`. Neither that E2E file nor `UploadsController` differs from `origin/main`, so this baseline test-harness failure was not changed as part of P2-34.
- Feature branch `fix/p2-34-customer-related-work` was pushed and fast-forward merged to Backend `main` at `61d7099`; Frontend source was not changed and its pre-existing WIP remained untouched.
- Post-merge branch cleanup was attempted for both remote and local refs, but the active destructive-Git protection denied both deletions; the fully merged branch was preserved without bypassing policy.

Acceptance:
- Active Production Jobs and relevant linked Uploads cover the Customer's full Order ownership, independent of any recent-order display limit.
- Recent Order history may remain bounded or become server-paginated, but its presentation limit must not define operational related-work correctness.
- Avoid replacing the 100 cap with an unbounded giant `$in`; use a server query/aggregation that remains bounded and indexable.
- Add regression coverage with more than 100 Customer Orders where an older Order still owns an active Job and/or linked Upload.

### P2-35 — Integrate Production Job due/rush truth into Dashboard and Action Center

Status: DONE  
Area: Frontend + Backend / Production / Dashboard / Action Center

Fresh-scan evidence (2026-08-30):
- Production Jobs now have authoritative `dueAt`, `priority`, `isRush`, and derived `isOverdue` semantics.
- `DashboardService` does not read Production Jobs, still returns `today.urgentJobs: 0`, and advertises `capabilities.dueDates: false` / `urgentFlag: false` even though those capabilities now exist in the production domain.
- P2-25 intentionally deferred the old createdAt-based overdue notification rule until a real Production Job due-date model existed. That model now exists, but Action Center still has no Production Job due/rush integration.

Acceptance:
- Dashboard operational state derives real due-today/overdue/rush counts from incomplete Production Jobs, not Order age or a hard-coded pseudo-SLA.
- Dashboard capability flags become truthful and drill-downs open executable Production Board filters.
- Action Center surfaces genuinely overdue production work with a stable deduplicated identity and resolves/reopens from current Production Job due/stage state; rush priority may be surfaced without inventing a time threshold.
- Ready/delivered jobs are not reported as overdue; due-date edits and stage changes reconcile the action state.
- Add Backend lifecycle/count tests and Frontend drill-down/action coverage.

### P2-36 — Complete Customer Display pairing-session revoke and cleanup lifecycle

Status: DONE  
Area: Frontend + Backend / Customer Display / Reliability / Security surface

Fresh-scan evidence (2026-08-30):
- Customer Display sessions expire after 12 hours and the public token is stored hashed, but the controller exposes create/update/read/events only; there is no staff revoke/unpair/rotate command for an active pairing link.
- Frontend pairing UI can create/copy/open a session but has no explicit disconnect/rotate action, so a shared or accidentally exposed pairing URL remains usable until expiry.
- `CustomerDisplayService` keeps `sessionEvents` in a process-local `Map<string, Subject<void>>`; `getSubject()` adds entries but no lifecycle path removes/completes them after expiry/disconnect. Database TTL therefore does not bound this in-memory registry.
- Cross-instance changes are currently reconciled by the existing 3-second Mongo refresh fallback; this task does not need to replace that transport merely to complete lifecycle safety.

Progress (2026-08-31):
- Implemented explicit Customer Display rotate/revoke lifecycle, invalidating old public pairing tokens immediately and exposing staff-facing pairing replacement/disconnect controls.
- SSE/read handling now revalidates revoked/expired sessions and process-local event Subjects/listeners are cleaned up instead of accumulating indefinitely.
- Frontend merge `924bf336885f12fab2596a551fa52fd113fa92d8` and Backend merge `5bca8540700c7f9a2686a882e6c10e579364f1b8` remain the current clean repository HEADs during recovery, so the previously completed verification evidence still applies to the exact merged source.
- Recovery reconciled only governance state; no Frontend/Backend application source was changed.

Acceptance:
- The owning authenticated staff user can explicitly revoke/unpair or rotate a Customer Display session; an old public token becomes unusable immediately.
- Frontend clears/replaces its locally stored pairing identity and exposes an understandable disconnect/rotate workflow.
- SSE/read paths fail/terminate cleanly for revoked/expired sessions.
- Process-local event Subjects/listeners are cleaned up when no longer needed so session churn cannot grow the in-memory registry indefinitely.
- Preserve hashed-token storage, database expiry, counter ownership isolation, and multi-instance fallback behavior with focused Backend/Frontend tests.

### P2-37 — Separate continuous project gap scanning from implementation execution

Status: DONE  
Area: Governance / Automation / Architecture review  
Risk: Medium

Fresh-scan evidence (2026-08-30):
- The current hourly Governance V2 TODO Runner is responsible for both discovering new gaps and implementing safe actionable TODOs in the same run.
- Current source has grown substantially across Production Jobs, Customer CRM, Inventory, Customer Display pairing, Tracking, LINE integration, and new shared UI contracts, while `ARCHITECTURE.md` is still verified only against the older 2026-08-27 Frontend/Backend snapshots.
- Combining discovery and implementation can make broad architecture drift, cross-domain contract mismatches, and newly introduced TODO candidates less visible when the same run immediately prioritizes executable backlog work.
- Frontend may also contain unrelated active WIP, so a discovery pass should be able to remain read-only and report findings without colliding with implementation state.

Implementation direction:
- Split continuous improvement into two explicit responsibilities: a read-only Project Gap Scanner / Planner pass and the existing TODO Implementer/Runner pass.
- The scanner should inspect current Frontend + Backend together, compare source with active decisions/rules and the current backlog, detect duplicate findings, and propose or record only source-verified new TODOs.
- The scanner must never modify application source, reset/discard WIP, merge branches, or turn unresolved product/business questions into implementation rules.
- Findings that require policy must be routed to `DECISIONS.md` / Needs Decision rather than silently becoming executable behavior.
- The implementation runner remains responsible for resuming safe `IN_PROGRESS` work and executing safe `OPEN` TODOs after normal WIP/Git/risk checks.

Progress (2026-08-30):
- Split the automation responsibilities into two active schedules instead of allowing two hourly runners to compete for the same backlog.
- `Glossy Project Scanner` is now a read-only Planner/Gap Scanner on a 6-hour cadence. It inspects current Frontend + Backend, re-verifies findings against source/decisions, avoids duplicate TODOs, may update workspace-root governance/TODO planning only, and never edits application source or performs Git implementation work.
- `Glossy TODO Runner` remains the implementation worker on the existing hourly cadence. Its prompt now explicitly consumes existing safe `IN_PROGRESS` / `OPEN` backlog work and does not perform broad discovery as its primary responsibility.
- Both automations explicitly preserve existing Frontend/Backend WIP, skip unresolved decision/policy work, and fall back to bounded direct workspace reads when indexed lnwjud search is unavailable.
- The duplicate hourly implementation behavior was removed by repurposing the newer automation as the Scanner rather than leaving two TODO Runners active.
- No Frontend or Backend application source was changed for this governance task.

Acceptance:
- Continuous project discovery and TODO implementation have separate documented automation responsibilities/prompts so a discovery cycle can complete without editing application source.
- The scanner reports current FE/BE HEAD + dirty state, inspected domains, verified new gaps, duplicate/backlog matches, architecture drift, and decision-gated findings.
- New TODO candidates contain evidence, priority/risk, FE/BE ownership, dependencies/blockers, do-not-touch boundaries, acceptance criteria, and required verification; duplicate TODOs are not created.
- Existing user WIP is never reset, overwritten, deleted, cleaned, or implicitly adopted by the scanner.
- `ARCHITECTURE.md` drift is detected using current SHAs and can trigger a bounded architecture-refresh TODO rather than silently rewriting architecture during unrelated implementation.
- The implementation runner continues to obey DEC-008 selection rules and may consume scanner-created safe TODOs on later runs.

### P2-38 — Redesign Quick Seller + Quick Seller Settings around service families with deliberate modal confirmation

Status: BLOCKED  
Area: Frontend + Backend / Quick Seller / Quick Seller Settings / UX  
Risk: Medium / Cashier speed and configuration correctness

Owner plan (2026-08-30):
- This item is intentionally **plan-only** for now. Do not implement, migrate data, or alter Quick Seller behavior until the owner explicitly approves the final mockup/flow for implementation.
- Preserve deliberate confirmation steps. The goal is to reduce duplicated choices, not to minimize clicks so aggressively that staff can select the wrong job/options without noticing.
- Preferred cashier flow: `เลือกกลุ่มงาน → Modal เลือกรายละเอียด → เพิ่ม Cart → ตรวจรายการ → Modal ชำระเงิน → จบการขาย`.
- Keep the existing payment-modal concept for payment method, cash received/change, PromptPay, customer/tax document data, and backdated sale controls rather than crowding those responsibilities onto the main selling surface.

Problem / current evidence:
- Current Quick Seller effectively presents `1 SKU = 1 card`, which explodes related document combinations into separate cards such as Print/Copy × A4/A3 × BW/Color and makes the selling surface increasingly scan-heavy as the catalog grows.
- Current Quick Seller Settings combines product creation, code/typeCode, category, price, active state, hot-menu state, icon/tint, and numeric sort order in one admin workflow. This behaves more like Product/SKU administration than a clear "design the selling screen" workflow.
- The redesign must not merely shrink cards; it should introduce a presentation/configuration layer while preserving the existing SKU/Order identity underneath.

Planned product model:
- Change the Quick Seller presentation mental model from `SKU → Card` to `Service Family → Options → explicit SKU mapping → Order`.
- Initial service-family candidates: `งานเอกสาร`, `สติ๊กเกอร์`, `ตรายาง`, `นามบัตร`, `เข้าเล่ม / เคลือบ / ตัด`, `งานแปลน / งานพิมพ์ใหญ่`, and `อื่นๆ / Custom`.
- Keep long-tail/special jobs behind search or `งานอื่นๆ` instead of letting them dominate the primary card grid.
- Catalog ownership is now resolved by DEC-011: Product/Variant is canonical and Quick Seller is a presentation/shortcut layer. This plan must still preserve existing Product/QuickProduct collections and historical Orders through a non-destructive migration.

Quick Seller V2 plan:
- Main surface shows compact service-family choices rather than every option combination as its own card.
- Selecting a family that requires configuration opens one purposeful configurator Modal. Do **not** create a wizard/modal-per-option flow.
- Document-work Modal should support, at minimum:
  - work type: Print / Copy / Scan;
  - size: A4 / A3 and configured larger sizes where applicable;
  - color mode: B&W / Color where applicable;
  - quantity with `− / +` plus quick presets such as 1 / 5 / 10 / 20 / 50;
  - resolved unit price, selection summary, total, and one explicit `เพิ่มลงรายการ` confirmation.
- Defaults may make common jobs faster, but the selected configuration and price must remain visible before Add-to-Cart.
- Cart keeps the current persistent-summary concept and should allow quantity adjustment, delete, and `แก้ไข` that reopens the relevant configurator with the current selection.
- Keep Modals for actions where confirmation/context is useful: configurable product options, edit-cart-item, custom/manual-price item, payment, VAT/customer information, and complex/special jobs.
- Search/category switching and other lightweight navigation should remain on the main page without unnecessary Modals.

Quick Seller Settings V2 plan:
- Reframe the main Settings experience around configuring the selling screen, not exposing raw SKU administration first.
- Proposed primary sections/tabs: `จัดหน้าขาย`, `ราคาและตัวเลือก`, and `Preview`; keep SKU/Product administration as a secondary `Advanced` surface.
- `จัดหน้าขาย`: show service families as a reorderable list with drag/drop and understandable enable/disable controls. Do not require users to manage numeric sort-order values directly.
- Selecting a service family opens a focused Modal/Drawer editor for display name/icon, enabled state, featured/hot state, available option groups, default selections, and live preview.
- `ราคาและตัวเลือก`: show human-readable matrices where appropriate (for example Print/Copy × size × B&W/Color) instead of forcing one-row-per-SKU editing for related combinations.
- Hide `code`, `typeCode`, raw IDs, and mapping internals under Advanced settings; a user who does not know SKU internals should still be able to arrange Quick Seller and maintain ordinary prices/options.
- Provide a live Preview so Settings changes can be understood as their resulting cashier UI before save/publish.

Data/API direction (after approval):
- Prefer adding a non-destructive presentation layer such as `QuickSaleGroup` rather than rewriting historical `quick_products` or Orders.
- Candidate fields: group id/name/icon/active/featured/sort order, option groups, default selection, and explicit combination → existing SKU/QuickProduct mapping.
- Runtime selection must use stored explicit mappings; do not repeatedly infer SKU identity by parsing product names such as `A4`, `ขาวดำ`, etc.
- A one-time migration helper may propose mappings from existing data, but mappings must be reviewable/persisted explicitly before use.
- If a selected combination has no valid mapping/price, fail visibly and disable Add-to-Cart rather than guessing another SKU.

Implementation phases after owner approval:
1. UX/IA — finalize Quick Seller, configurator Modal, Cart edit flow, Settings layout, group editor, price matrix, and Preview mockups.
2. Data/API — define the presentation-layer schema/API and reviewed migration/mapping approach without destructive catalog changes.
3. Quick Seller V2 — implement service families and the document-work configurator first, then integrate with the existing Cart/order payload.
4. Settings V2 — implement selling-screen arrangement, group editor, options/defaults, price matrix, explicit mapping/Advanced view, and Preview.
5. Migration + QA — migrate/review existing combinations and verify parity with the current Order/price behavior before rollout.

QA scenarios after implementation:
- Print A4 B&W ×1 and ×50; Print A4 Color; Copy A4 B&W; A3 Color.
- Print + Copy in the same Order.
- Custom/manual-price item with existing RBAC rules preserved.
- Change quantity, edit configured options after an item is in Cart, and delete an item.
- Cash, PromptPay, VAT/tax invoice, customer selection, and backdated-sale checkout paths.
- Missing/disabled SKU mapping must fail closed with a clear message.
- Existing historical Orders and current QuickProduct/SKU identifiers remain readable and unchanged.

Definition of Done after implementation:
- The main Quick Seller no longer requires a card wall for Print/Copy × A4/A3 × B&W/Color combinations.
- Common document jobs are fast to configure while still presenting a deliberate summary/confirmation before Add-to-Cart.
- Related options are handled inside one coherent configurator Modal, not a chain of Modals.
- The payment flow remains a deliberate Modal and retains its current financial/customer/tax/backdate responsibilities unless separately approved.
- A non-technical Settings user can arrange the selling screen and maintain normal options/prices without understanding `code`, `typeCode`, numeric sort order, or raw SKU IDs.
- SKU resolution is explicit and deterministic; unmapped combinations cannot silently create the wrong Order line.
- Existing Orders/catalog data are preserved; no destructive catalog merge or P2-08 ownership decision is smuggled into this redesign.

Blocker / implementation gate:
- Await explicit owner approval of the final Quick Seller + Settings V2 mockup/interaction flow. Until then, this TODO is planning evidence only and must not be selected by the automated implementation runner.

## P3 — Low (14)

### P3-01 — Remove verified dead Dashboard legacy implementation

Status: DONE  
Area: Backend cleanup

Progress (2026-08-27): pushed in Backend commit `0010de4`; the verified unused legacy dashboard summary/pipeline chain was removed and full Backend tests/lint/build passed.

`DashboardService.getLegacySummary()` was verified private with no current caller before removal.

Acceptance:
Remove it in a cleanup-only change after confirming no reflective/test usage.

### P3-02 — Resolve dormant tracking service helpers after P1-03

Status: DONE  
Area: Backend cleanup

Progress (2026-08-27): pushed in Backend commit `acbd853`; the old broad tracking search/full-data response path was removed from active code and replaced by the minimal public verifier tracked in P1-03.

The former `findTrackingByOrderNumber`, `searchTracking`, and full tracking-response helper path is no longer the public contract.

Acceptance:
After the Tracking product decision, either connect them through the approved contract or remove the dormant path.

### P3-03 — Retire legacy route/API aliases deliberately

Status: DONE  
Area: Frontend + Backend cleanup

Progress (2026-08-28):
- Frontend `/home/saleListPage` no longer re-exports the full Orders page; it is now a compatibility-only permanent redirect to `/home/orders` with Frontend ownership, deprecation date `2026-08-28`, and planned removal after `2026-11-30` if usage evidence shows no remaining legacy bookmarks.
- Frontend Storage no longer retries the retired singular backend `/upload` API alias and uses canonical `/uploads` only. The public Frontend page `/upload` is unchanged because it is a customer-facing route, not the backend API alias.
- Backend controller now exposes canonical `/uploads` only; the singular `/upload` API alias was removed.
- Backend E2E regression coverage verifies `POST /upload` returns `404` and never invokes upload creation.
- Verification passed before and after merge: Frontend 109/109 tests, ESLint, production build/TypeScript/UTF-8, and diff check; Backend 83 unit tests with 12 integration tests intentionally skipped by the default run, E2E 30/30, ESLint, build, and diff check.
- Frontend feature commit `b492eb1` was merged and pushed to `main` at `e09b00a`; Backend feature commit `52187a5` was merged and pushed to `main` at `888cc39`.

Acceptance:
Keep only aliases with a documented compatibility owner/deprecation date; remove dead aliases in isolated cleanup changes.

### P3-04 — Sync README/comments with current runtime

Status: DONE  
Area: Documentation

Progress (2026-08-27):
- Backend runtime/auth/upload documentation and notification comments were aligned in pushed commits `0010de4` and `c830882`.
- Frontend runtime/auth/payment documentation and the stale Frontend-root TODO plan were cleaned up in pushed commit `6d167d9`.
- Frontend and Backend verification passed before push.

Examples that were stale during the audit:
- Backend README said admin auth was not implemented.
- Backend README described an 8MB upload cap while code used 7,500,000 bytes.
- Frontend README described an outdated auth/runtime contract despite the current backend session flow.
- Notifications delete comment said admin-only without a matching role decorator.

Acceptance:
Documentation and comments describe verified current behavior and do not create phantom requirements.

### P3-05 — Validate the dedicated Agent login environment contract

Status: DONE  
Area: Backend / Auth / Configuration

Progress (2026-08-29):
- `env.validation.ts` now declares `AGENT_LOGIN_USERNAME`, `AGENT_LOGIN_PASSWORD`, and `AGENT_LOGIN_ROLE`; Agent username/password must be provided together, while leaving all Agent variables unset remains valid.
- `AGENT_LOGIN_ROLE` is restricted at startup to `staff | manager | admin`, so an unsupported value is rejected instead of silently falling back to `staff`.
- Focused configuration coverage verifies unset deployment, all supported roles, incomplete credential pairs, invalid role rejection, and that validation errors do not include the Agent password value.
- Verification passed: focused config 6/6, Backend unit 149 passed with 15 integration tests skipped by the default suite, E2E 33/33, ESLint, production build, and `git diff --check`.
- Feature commit `f44fee9` on `fix/p3-05-agent-env-validation` was pushed, fast-forward merged, and pushed to Backend `main`; merged `main` focused config verification passed 6/6 and `HEAD == origin/main == f44fee9`.
- Branch cleanup was attempted after merge but both remote and local deletion were blocked by the active destructive-Git protection, so the merged branch was preserved.

Acceptance:
Startup validation requires Agent username/password as a pair, restricts role to `staff | manager | admin`, never logs secret values, and has focused configuration tests. Leaving all Agent variables unset remains a valid deployment.

### P3-06 — Remove the retired singular upload path from the public BFF allowlist

Status: DONE  
Area: Frontend / BFF / Cleanup / Security surface

Current evidence (2026-08-28):
P3-03 removed the Backend singular `/upload` API alias and Storage now uses canonical `/uploads`, but `src/app/api/backend/[...path]/route.ts` still listed `'upload'` in `PUBLIC_POST_PATHS`. The BFF therefore treated a retired backend path as anonymously forwardable even though the Backend returned `404`.

Progress (2026-08-29):
- Removed the retired singular `upload` entry from the Frontend BFF public POST allowlist while preserving canonical anonymous `POST /uploads` and the existing tracking contracts. The customer-facing Frontend `/upload` page was not changed.
- Added allowlist regression coverage proving `POST /uploads` remains public and `POST /upload` is no longer treated as anonymous.
- Verification passed: focused allowlist tests 2/2, full Frontend Node tests 151/151, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check`.
- Commit `972c0f6` from `cleanup/p3-06-public-bff-upload-allowlist` was pushed, fast-forward merged, and pushed to Frontend `main`; merged-main focused verification passed 2/2. The existing build-generated `next-env.d.ts` WIP remained uncommitted and preserved.

Acceptance:
Only the intended canonical anonymous POST contracts remain in the BFF allowlist; the retired singular API path is no longer granted public proxy treatment, and a regression test locks the allowlist behavior without changing the customer-facing Frontend `/upload` page.

### P3-07 — Make Sonar analysis reproducible instead of best-effort IDE-only

Status: BLOCKED  
Area: Quality / Static analysis / CI

Current evidence (2026-08-28):
ESLint/build checks are reproducible, and VS Code has SonarLint installed, but this machine has no `sonar-scanner` CLI and the project has no verified SonarQube/SonarCloud project/quality-gate configuration available to the automated runner.

Blocker:
A SonarQube/SonarCloud target, project identity, and secret/token delivery method must be configured outside source before a real server quality gate can be claimed.

Acceptance:
Provide one documented local/CI analysis path with secrets kept outside Git, explicit source/test exclusions, and a machine-readable quality-gate result that the TODO Runner can distinguish as pass/fail/unavailable. Do not report ESLint or SonarLint as a SonarQube server scan.

### P3-08 — Make Action Center polling visibility-aware and non-overlapping

Status: DONE  
Area: Frontend / Notifications / Performance

Progress (2026-08-29):
- Replaced fixed `setInterval` polling with a small Action Center polling controller that schedules the next 30-second refresh only after the active request settles, so timer/focus/manual refreshes reuse the same in-flight request instead of overlapping.
- Automatic polling clears its timer while `document.visibilityState === 'hidden'` and refetches immediately when the page becomes visible or the window regains focus. Manual refetch remains available even while hidden.
- Each Action Center request carries an `AbortSignal`; unmount stops timers/listeners and aborts the active request without surfacing an abort as an application error.
- Added focused lifecycle tests for non-overlap, hidden pause/visible refresh, hidden manual refetch, and unmount abort/listener cleanup.
- Verification passed before merge: Frontend unit 155/155, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check`. Feature commit `a6e791b` from `fix/p3-08-action-center-polling` was pushed, fast-forward merged, and pushed to Frontend `main`; merged-main unit verification passed 155/155. Existing build-generated `next-env.d.ts` WIP remained uncommitted and preserved.

Acceptance:
Prevent overlapping Action Center fetches, pause/reduce polling while the document is hidden, refetch promptly on focus/visibility return, clean up in-flight work on unmount, and preserve the current initial-load/manual-refetch behavior with focused tests.

### P3-09 — Add an Admin System Health page and menu

Status: DONE  
Area: Frontend + Backend / Operations / Health Check

Dependency:
P2-13 production readiness probes.

Progress (2026-08-29):
- Added protected `GET /health/ready/details` backed by the existing readiness probes. The response is intentionally bounded to overall readiness, check time, and generic `database` / `objectStorage` states; public `/health` and `/health/ready` remain minimal and unchanged.
- Added Backend unit + E2E coverage proving anonymous callers receive `401` for readiness detail, authenticated staff can read it, and no connection strings, credentials, bucket names, tokens, or secret values are returned.
- Added `/home/system-health` plus a `สถานะระบบ` MANAGEMENT menu available to authenticated staff. The page distinguishes healthy, degraded, unready, and unreachable states, shows dependency/last-check state, supports manual refresh, and polls every 60 seconds only while the document is visible with in-flight request deduplication.
- Verification passed before merge: Frontend focused 12/12, full unit 160/160, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check`; Backend focused health 8/8, full unit 151 passed with 15 integration tests skipped by the default suite, E2E 35/35, ESLint, production build, and `git diff --check`.
- Feature branch `feature/p3-09-system-health` was pushed and fast-forward merged to Frontend `main` at `454611e` and Backend `main` at `005880f`; both `HEAD == origin/main` after push. Merged-main focused verification passed Frontend 12/12, Backend health unit 8/8, and protected health E2E 2/2. Existing Frontend `next-env.d.ts` WIP remained uncommitted and preserved.
- Local and remote branch cleanup was attempted in both repositories but blocked by the active destructive-Git protection, so the fully merged branches were preserved without bypassing policy.

Acceptance:
Expose a protected System Health page/menu for authorized staff that summarizes Frontend-to-Backend reachability and the Backend readiness result without exposing connection strings, credentials, bucket names, tokens, or other secrets. Clearly distinguish healthy, degraded/unready, and unreachable states, show the last check time, support manual refresh, and use bounded polling rather than aggressive background requests. The public liveness endpoint stays minimal; dependency detail belongs behind authentication. Add focused Frontend tests for state mapping and Backend tests for the protected readiness detail contract.

### P3-10 — Separate Customer Display naming and standardize feature detail drawers

Status: DONE  
Area: Frontend / Navigation / Customer Display / Shared UI

Progress (2026-08-30):
- Resumed the existing Frontend WIP instead of starting a new TODO. The public counter display moved from the ambiguous `/customer` route to explicit `/customer-display`; the legacy `/customer` route now redirects while preserving the opaque `display` pairing token. Quick Sale and generated pairing links use the new route.
- Renamed the CRM-facing menu/page wording from `ลูกค้า` to `ฐานลูกค้า` to reduce confusion between the customer directory and the separate customer-facing display.
- Added canonical `GlossyDetailDrawer`, based on the Order Detail Drawer shell, and migrated Order, Storage, Production Job Ticket, and Customer detail drawers to compose through it while preserving their business-specific content/actions.
- Added a source-policy regression test preventing feature detail drawers from bypassing the shared shell except for explicitly approved utility drawers.
- Verification passed before merge and again on merged `main`: Frontend Node tests 176/176, ESLint, UTF-8 validation, production build/TypeScript, and `git diff --check`.
- Feature commit `16f7bd2` from `refactor/p3-10-customer-route-shared-drawer` was pushed, fast-forward merged, and pushed to Frontend `main` at `16f7bd2`. Backend was not changed. The build-generated/pre-existing `next-env.d.ts` working-tree change remained uncommitted and preserved.

Acceptance:
Customer CRM and Customer Display have unambiguous route/menu naming; legacy display links remain compatible; feature detail drawers reuse the canonical Order-style shell with responsive behavior and regression coverage; business-specific drawer content remains owned by each feature.

### P3-11 — Make Customer Order history fully pageable by Customer identity

Status: DONE
Area: Frontend + Backend / Customers / Orders / Data access

Completion evidence (2026-09-01):
- Customer detail now accepts validated `orderPage` / `orderLimit` parameters and pages Orders strictly by canonical `customerId`, with deterministic `{ createdAt: -1, _id: -1 }` ordering and bounded default page size 10.
- Response includes `orderPagination { page, limit, total }`; lifetime `summary.orderCount` remains authoritative for the matching Customer history, while related Production/Upload aggregation still scans the full Customer Order set.
- Customer drawer now renders the server page and exposes `TablePagination`; Frontend request/state wiring reloads only the selected Customer identity and preserves walk-in Orders with no Customer relation.
- Authorization regression confirms anonymous Customer detail remains 401 while authenticated staff may request paged history.
- Verification passed: Backend focused CustomersService 5/5, focused Customers E2E 2/2, full unit 211 passed / 15 skipped, full E2E 37/37, ESLint, build; Frontend focused customer tests 4/4, full tests 195/195, ESLint, UTF-8, and production build. Clean Frontend branch was re-verified after separating unrelated layout/icon WIP.
- Backend feature commit `2f9996f` and Frontend clean feature commit `964df4b` were pushed, fast-forward merged, and pushed to each repository `main`. Unrelated Frontend commit `9587eba` (`แก้ layout icon`) was preserved separately on local branch `wip/preserve-layout-icon-20260901` and was not merged with P3-11.

Fresh-scan evidence (2026-09-01):
- `CustomersService.findOne()` still returns only the latest 100 Orders via `.limit(100)` even though `orderCount` and financial summaries can represent a larger lifetime history.
- Customer detail UI further renders only `customer.orders.slice(0, 10)`, so staff cannot reach older sales from the Customer workflow.
- The generic Orders list query currently has no exact `customerId` filter, so there is no alternative identity-safe drill-down to the complete Customer history.
- This is not a duplicate of P2-34: P2-34 fixed related Production/Upload correctness beyond the first 100 Orders and intentionally allowed the recent Order-history list to remain bounded or become paginated later.

Acceptance:
- Provide an authenticated server-paginated Customer Order-history contract keyed by canonical Customer identity; do not rely on name/phone fuzzy matching.
- Customer detail can page through the complete history while keeping the initial payload bounded and responsive.
- Counts, ordering, and pagination metadata represent the full matching history and remain stable under deterministic newest-first ordering.
- Existing historical Order snapshots remain immutable and financial truth stays on Orders/payment facts.
- Add Backend pagination/authorization regression coverage and Frontend query/state coverage; preserve walk-in Orders without a Customer relation.

Do not touch:
Do not auto-merge Customers, rewrite historical Order customer snapshots, or broaden any Customer endpoint to public access.

Verification:
Focused Customer/Order tests, full affected repository tests, ESLint, TypeScript/build, UTF-8 for Frontend, and FE↔BE contract review.

### P3-12 — Add cross-domain E2E coverage for BOM material consumption

Status: DONE
Area: Backend / Production / Inventory / Catalog / Regression safety

Completion evidence (2026-09-01):
- Added `test/production-bom.e2e-spec.ts`, an authenticated HTTP-contract E2E backed by `MongoMemoryReplSet` and the real Inventory, Product, Orders, and Production modules/persistence boundary.
- Success path creates real stock/catalog/order/job state, transitions `file_check → queued → producing`, asserts exact BOM delta (20 → 14 for recipe 2 sheets × quantity 3), one append-only `issue` movement, Order/Production Job references, and full recipe snapshot provenance. Replaying the same `producing` transition remains idempotent and does not consume twice.
- Fail-closed path starts with insufficient stock (5 < required 6), receives 409, leaves on-hand unchanged, records no issue movement, and leaves the Production Job queued.
- The persisted E2E exposed a real boundary bug hidden by plain-object unit mocks: spreading a Mongoose Order cart subdocument dropped `qty`, causing an invalid material quantity. Production now preserves the original subdocument while narrowing the already-validated `productId` type; BOM policy and authority are unchanged.
- Added reproducible `npm run test:mongo:bom`. Verification passed: focused Mongo BOM 2/2, Backend unit 211 passed / 15 skipped, standard E2E 37/37 (Mongo suite intentionally skipped there), ESLint, build, and `git diff --check`.
- Backend feature commit `85a565f` was pushed, fast-forward merged, and pushed to `main`.

Fresh-scan evidence (2026-09-01):
- P2-30 has strong service/unit coverage around recipes, `materialIssueStartedAt`, idempotency, insufficient stock, and movement provenance.
- Current Backend E2E suites do not exercise the complete persisted path from an Order/canonical Product recipe through Production Job line mapping and `queued → producing` into the resulting Inventory movement/history.
- A regression spanning controller/DTO/persistence boundaries could therefore escape the current isolated service tests even though material consumption is an inventory-integrity workflow.

Acceptance:
- Add an isolated E2E path that creates the minimum real catalog/stock/order/job state needed to trigger approved BOM consumption through public authenticated application contracts.
- Assert exact stock delta, append-only `issue` movement, Order/Production Job reference, recipe snapshot/provenance, and retry/idempotency behavior.
- Include at least one fail-closed case such as insufficient stock or incomplete recipe without silently changing stock.
- Keep accounting/COGS semantics out of scope and do not weaken P2-30 server authority.

Do not touch:
Do not redesign BOM policy, introduce destructive inventory migration, or substitute mocks for the persistence boundary the test is intended to protect.

Verification:
Focused new E2E suite plus Backend unit, E2E, ESLint, build, and relevant isolated Mongo/inventory verification when configured.

### P3-13 — Isolate Playwright browser tests from an active developer Next server

Status: DONE
Area: Frontend / Test infrastructure / Reliability

Completion evidence (2026-09-01):
- Frontend Playwright now uses a dedicated `.next-e2e` runtime/output directory through `NEXT_DIST_DIR`, isolated from the normal developer Next runtime, and the generated E2E artifacts are excluded from Git.
- The harness keeps a deterministic dedicated E2E origin, does not enable `reuseExistingServer`, and preserves controlled authentication/PromptPay/production fixtures rather than borrowing an arbitrary user server.
- The isolated browser path was documented and the full Chromium suite passed 10/10 without terminating or restarting the user-owned developer server. Earlier goal verification and the recovered run both completed without the prior shared Next lock collision.
- Feature commit `67cb03a` was pushed during implementation; the verified change was integrated onto Frontend `main` as `6ce9f36` and pushed to `origin/main`.
- Recovered-goal verification on current Frontend `main` passed: Node tests 195/195, browser E2E 10/10, ESLint with zero warnings, UTF-8 validation, production build/TypeScript, and `git diff --check`.
- The unrelated local `.agents/` skill content remains untracked and preserved; no user-owned process or unrelated WIP was reset, cleaned, or discarded.

Fresh-scan evidence (2026-09-01):
- `npm run test:e2e:browser` failed during two consecutive full-project scans because Playwright's configured `webServer` started another Next development server from the same project while a user-owned dev server was already active.
- The 2026-09-01 failure reported `Another next dev server is already running` for PID 23588. Scanner correctly did not kill the developer process.
- Unit tests, ESLint, UTF-8, and production build were already passing, confirming this was a browser-test isolation problem rather than an application build failure.

Acceptance:
- [x] Browser E2E can run while the normal developer Next server for this repository remains active, without killing/restarting the developer process and without sharing a conflicting Next runtime lock/output directory.
- [x] Preserve a deterministic dedicated E2E origin and fail safely if the isolated E2E server itself cannot start.
- [x] Keep authentication/test fixtures compatible and ensure the harness does not accidentally reuse an unrelated existing server.
- [x] Add/document the isolated execution path and verify the browser suite succeeds with a normal dev server simultaneously running.

Do not touch:
Do not terminate user-owned processes, change production runtime behavior, or solve the issue by setting `reuseExistingServer: true` against an unverified arbitrary development server.

Verification:
Run the browser E2E suite with the normal developer server left running, plus Frontend tests, ESLint, UTF-8, production build, and `git diff --check`.

### P3-14 — Keep the internal Artwork POC out of anonymous production access

Status: OPEN  
Area: Frontend / Auth boundary / Deployment hardening  
Risk: Medium  
Owner: Frontend

Fresh-scan evidence (2026-09-01):
- Current Frontend `main` adds the deterministic `/artwork-poc` route in commit range `6ce9f36..4dd350a`.
- `proxy.ts` protects only `/home`, `/dashboard`, `/orders`, `/pos`, `/storage`, `/invoice`, and `/print/invoice`; `/artwork-poc` is absent from both `PROTECTED_PREFIXES` and the proxy matcher.
- `src/app/artwork-poc/page.tsx` has `robots: { index: false, follow: false }` but no admin-session/auth guard. `noindex` reduces search discovery only; it does not prevent direct anonymous access.
- Current `e2e/artwork-poc.spec.ts` verifies rendering/responsiveness but does not assert the intended production authentication/exposure boundary.
- `TODO.md` contains no existing equivalent Artwork POC/public-route hardening item. The Feature Scout's Content Studio proposal is product planning and is not a substitute for this source-verified access-boundary finding.

Dependencies / blockers:
- Reuse the existing Frontend admin-session/proxy boundary or an equally fail-closed production-only route gate. No Backend change is required by the current finding.

Acceptance:
- An unauthenticated production request cannot render `/artwork-poc` directly.
- Authenticated staff access may remain available if the POC is intentionally retained; local deterministic E2E/dev access must use an explicit test/development mechanism rather than weakening the production auth boundary.
- Existing public customer routes and existing protected admin routes keep their current behavior.
- Add regression coverage proving the chosen anonymous-production behavior and the intended authorized/test path.

Do not touch:
Do not redesign the artwork/content-studio UI, promote the POC into a product feature, add Backend APIs, or change unrelated public route policy as part of this hardening task.

Verification:
Focused Artwork/auth route E2E plus Frontend tests, ESLint, UTF-8, production build/TypeScript, `git diff --check`, and task-scoped route/proxy review.
