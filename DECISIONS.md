# GlossyDesign Decisions

ADR-lite decision log for durable product and technical choices. Temporary tasks belong in `TODO.md`, not here.

Last reviewed: 2026-09-01 (Asia/Bangkok)

## Active decisions

### DEC-001 — Backend owns financial truth

Status: Active  
Date: 2026-08-27

Decision:
- Backend resolves authoritative catalog/custom prices according to role.
- Backend calculates subtotal, discount, VAT, grand total, paid amount, remaining amount, and financial status.
- Monetary invariants preserve satang precision.

Reason:
Financial correctness must not depend on a modifiable browser payload.

Impact:
Frontend may calculate previews, but persisted financial facts must reconcile to backend results.

### DEC-002 — VAT policy

Status: Active  
Date: 2026-08-27

Decision:
- Product prices are VAT-exclusive.
- VAT rate is 7%.
- Regular receipts do not add VAT.
- Tax invoices add 7% VAT to the discounted VAT-exclusive base.

Impact:
POS, Quick Seller, backend pricing, invoice rendering, reporting, and reconciliation must use the same policy.

### DEC-003 — Business time and backdated sale semantics

Status: Active  
Date: 2026-08-29

Decision:
- Business timezone is `Asia/Bangkok`.
- `createdAt` remains the actual creation/audit timestamp.
- Backdated sales store the historical business date in `saleDate`.
- All authenticated roles (`staff`, `manager`, `admin`) may create a backdated sale.
- A backdated sale may be at most 30 Bangkok calendar days before the current business date; future dates and dates outside that window are rejected.
- `backdatedReason` is mandatory whenever `saleDate` is earlier than the current Bangkok business date.
- Order numbers are generated at actual issuance time and are not rewritten to match a historical sale date.
- Reporting uses `saleDate` as the business-date dimension while audit/history preserves actual `createdAt` time.
- Frontend surfaces an explicit backdated-sale badge/indicator instead of changing the Order number format.

Impact:
P2-01 may implement this policy without a further role/window/reason decision. Order numbering remains monotonic and current-time issued while revenue/reporting can be attributed to the historical business date.

### DEC-004 — Financial history is auditable

Status: Active  
Date: 2026-08-27

Decision:
Normal cashier workflows must not silently rewrite or hard-delete historical financial facts. Corrections should use explicit auditable commands such as cancel/void/refund/reversal once the domain is defined.

Impact:
The current hard-delete order endpoint conflicts with this decision and is tracked in `TODO.md`.

### DEC-005 — Risk-based Git policy

Status: Active  
Date: 2026-08-27

Decision:
- Small isolated low-risk changes may be committed/pushed directly to `main` only when explicitly requested and verified.
- High-risk payment/security/schema/deployment/cross-repo work should use a branch and review/PR flow.
- Shared-history force pushes are never routine workflow.

Reason:
The project is small enough for fast low-risk fixes but financial/systemic work needs a review boundary.

### DEC-006 — Planner / Implementer separation

Status: Active  
Date: 2026-08-27

Decision:
Use a high-reasoning Planner/Reviewer to analyze architecture, risk, task boundaries, and final diffs. Use Codex/coding agents as bounded Implementers; lower-cost models are acceptable for well-specified tasks.

Impact:
Implementation agents should not independently redefine project architecture or business policy.

### DEC-007 — Customer Display supports same-machine and paired-device operation

Status: Active  
Date: 2026-08-29

Decision:
- Customer Display must support both a second display on the same POS machine and a separately paired tablet/phone/computer.
- Checkout state should synchronize in real time.
- Each cashier counter/display pair has its own session or pairing identity so one counter cannot accidentally display another counter's active sale.
- The customer-facing surface may show the current checkout's items, quantities, prices, discounts, total, deposit/paid amount, remaining amount, payment method, configured PromptPay QR/profile, payment state, and completion/thank-you state.
- Internal notes, staff-only controls, unrelated Orders, secrets, and unnecessary customer PII are not part of the display contract.
- The implementation must fail safely across reconnects and multi-device use; the precise transport may be chosen during P2-07 as long as the server remains the cross-device synchronization boundary.

Impact:
P2-07 is no longer blocked on topology choice and may implement/test a paired real-time contract while preserving same-machine support.

### DEC-008 — Governance V2 TODO Runner behavior

Status: Active  
Date: 2026-08-29

Decision:
- Workspace-root `TODO.md` remains the sole active execution backlog/source of truth for Governance V2.
- The automated TODO Runner is enabled on an hourly cadence.
- It may move ordinary safe work through `OPEN → IN_PROGRESS → DONE` after required verification and durable Git evidence.
- Unchanged `REVIEW` work is skipped.
- If no safe actionable task exists, the runner reports `NO_ACTIONABLE_TASK` and does not repeat implementation/full verification merely because the schedule fired.
- Decision-gated, blocked, destructive, unusual high-risk financial/security, or other approval-required work remains gated; the runner may continue to the next safe task.
- New safe TODOs may be selected automatically according to priority and WIP/collision rules.
- Merged task branches may be cleaned up only when Git policy permits; destructive protections are never bypassed.

Impact:
The runner may be re-enabled hourly. Legacy Frontend Codex/GitHub TODO automation disposition is now resolved by DEC-012: it must not remain an independent competing execution queue.

### DEC-009 — Project Scanner is read-only against application source

Status: Active  
Date: 2026-08-30

Decision:
- `Glossy Project Scanner` runs every 6 hours as a Planner/Gap Scanner separate from the implementation TODO Runner.
- Scanner may read Frontend/Backend source, Git state, architecture, tests, diagnostics, dependency graphs, coverage context, browser/runtime evidence, active decisions, and the current backlog.
- Scanner must not edit Frontend/Backend application source, create implementation commits, merge branches, reset/clean WIP, run destructive commands, or silently redefine product/business policy.
- Scanner classifies verified findings across architecture/contracts, security, data integrity, FE↔BE mismatch, performance, tests/coverage, dead/duplicate/stale code, and runtime/UX issues.
- Before creating a new TODO, Scanner must re-verify the finding against current source and search the active backlog for an existing equivalent item. Duplicate findings update evidence rather than creating duplicate TODOs.
- Policy/product questions become `BLOCKED` / Needs Decision evidence instead of executable behavior.
- Scanner uses incremental scans when Frontend/Backend SHAs have changed since the last scan and performs a full-project scan at least once per Bangkok calendar day.
- Scanner records scan state and the latest report under `docs/reports/`.
- If a Continuous TODO Runner durable goal is active, Scanner may still inspect source but must not mutate `TODO.md` or `DECISIONS.md`; it records proposed findings in the scanner report/state for later reconciliation to avoid backlog write collisions.
- When no implementation runner is active, Scanner may update workspace-root governance planning and add source-verified TODOs with evidence, priority/risk, ownership, dependencies/blockers, do-not-touch boundaries, acceptance criteria, and required verification.

Impact:
Project discovery and implementation are independent workers. `TODO.md` remains the sole execution backlog, while scanner reports are planning evidence until safely reconciled into that backlog.

## Owner decisions — 2026-08-31

### DEC-010 — Governance V2 lives in a dedicated repository

Owner decision:
- create/use a dedicated `GlossyDesign-Governance` Git repository for the workspace-root governance files;
- keep workspace-root `TODO.md` as the sole active execution backlog/source of truth under DEC-008;
- do not convert the parent workspace into a Git repository that absorbs or rewrites the existing Frontend/Backend repository histories.

Impact:
Governance ownership is explicit and versionable without making either application repository the accidental owner of cross-repo policy.

### DEC-011 — Product/Variant is the long-term canonical catalog; Quick Seller is a presentation/shortcut layer

Owner decision:
- `Product` / variant identity is the long-term canonical catalog lifecycle;
- Quick Seller remains the primary cashier workflow and may map presentation/service-family choices to canonical Product/Variant identities;
- highly specific custom/ad-hoc line items and per-sale custom prices remain supported and do not mutate shared catalog prices;
- migrate incrementally and non-destructively; existing QuickProduct identifiers and historical Orders remain readable until an explicit reviewed migration removes legacy dependencies.

Impact:
BOM/material-recipe ownership may target the canonical Product/Variant model. P2-08 and P2-30 are no longer blocked by catalog-ownership ambiguity.

### DEC-012 — Legacy Frontend Codex TODO automation is retired as an execution queue

Owner decision:
- Governance V2 workspace-root `TODO.md` is the only execution queue;
- legacy Frontend Codex/GitHub TODO automation must be disabled or migrated so it cannot independently select/complete work;
- legacy scripts/history may be retained temporarily for reference, but they must not act as a second source of truth.

Impact:
P2-09 may proceed with one versioned Governance V2 ownership model and removal/disablement of competing queue behavior.

### DEC-013 — Cancellation uses append-only refund facts; production hard delete is removed

Owner decision:
- normal production workflows have no physical Order hard delete, including privileged cashier/admin flows;
- use one Cancel flow initially; do not introduce a separate Void semantic unless a later business requirement justifies it;
- every cancellation requires actor, timestamp, and reason and retains the original Order number/history;
- if money was received, cancellation records an append-only Refund fact for the amount actually returned, including method, actor, time, and reason; original payment facts are never deleted or rewritten;
- payment/balance/reporting projections must show both money received and money refunded and derive the cancelled financial result from those authoritative facts;
- partial refund/deposit-return complexity is deferred: the initial supported correction is full cancellation/refund of the applicable received amount;
- issued tax documents are never silently edited/deleted and must use the approved corrective-document/cancellation path.

Impact:
P1-02 is actionable. Implementations must preserve satang precision, idempotency, auditability, and concurrency safety.

### DEC-014 — Production Jobs drive readiness aggregation; delivery remains an explicit Order handoff

Owner decision:
- Production Job progress contributes to public Order Tracking rather than remaining an unrelated customer-milestone preview;
- if any Production Job has begun active work, the Order may project `in_progress` according to the approved aggregation implementation;
- an Order with multiple Production Jobs becomes `ready` only when every non-cancelled required Production Job is at the approved ready-or-later state; one sibling Job cannot make the whole Order ready prematurely;
- `completed` / `delivered` remains an explicit Order-level customer handoff performed by staff and is not automatically produced merely because all Production Jobs finished internal work;
- Orders intentionally having no Production Job continue to use the existing Order workflow/tracking path;
- financial status remains independent from production/tracking aggregation.

Impact:
P1-13 is actionable. The implementation must be deterministic, retry/concurrency safe, multi-job aware, and preserve existing tracking privacy/token contracts.

### DEC-015 — Scheduled automation uses separate bootstrap, continuation, scanner, and scout boundaries

Status: Active
Date: 2026-09-01

Owner decision:
- ChatGPT Scheduled Tasks are the recurring bootstrap layer for Glossy automation: TODO Runner hourly, Project Scanner every 6 hours, and Feature Scout once per Bangkok calendar day;
- every recurring bootstrap checks for an overlapping active durable goal before starting work and must no-op rather than create a competing worker;
- unfinished lnwjud durable work continues through `lnwjud-scheduled-continuation` using exactly one confirmed one-time cloud successor; recurring bootstrap schedules do not replace that continuation;
- Windows Task Scheduler, cron, shell timers, or a second local recurring agent queue are not used for these workflows;
- Project Scanner remains a technical Planner under DEC-009 and may produce source-verified technical backlog evidence according to its collision rules;
- Feature Scout is a Product/Opportunity Planner only: it may rank `READY_FOR_DISCUSSION`, `NEEDS_DECISION`, `DEPENDENCY_GATED`, `DEFER`, and `DUPLICATE` candidates, but it must not directly promote product ideas into executable `OPEN` TODOs;
- explicit owner/Planner approval is required before a Feature Scout candidate becomes executable backlog work;
- `NO_ACTIONABLE_TASK`, no new verified scanner finding, or no materially new scout opportunity are healthy outcomes and must not cause agents to manufacture work.

Impact:
The automation loop may run continuously without merging Planner and Implementer authority. Recovery of unfinished work is handled by one-time cloud continuation, while recurring schedules only bootstrap independent cycles and collision-check first.

### DEC-016 — Cashier shift opening/closing and drawer reconciliation are out of scope

Status: Active
Date: 2026-09-01

Owner decision:
- do not implement cashier shift opening/closing, opening float, drawer cash-in/out, closing cash count, or shift discrepancy reconciliation at this time;
- do not add a Shift model, API, menu, migration, or new financial projection merely because the capability is common in POS products;
- existing Order/payment/refund facts remain the authoritative financial evidence;
- reopening this product area requires a new explicit owner decision/TODO.

Impact:
P2-31 is closed by product-scope decision with no Frontend/Backend application-source change required.

### DEC-017 — Quick Seller V2 is a parallel pilot and cannot replace V1 implicitly

Status: Active
Date: 2026-09-01

Owner decision:
- current production Quick Seller `/home/quick-sale` and current settings `/home/settings/quick-menu` remain available and unchanged while V2 is designed, implemented, and piloted;
- V2 should be introduced as a separate `ขายด่วน V2` / experimental route, proposed at `/home/quick-sale-v2`, with separate V2 configuration proposed at `/home/settings/quick-sale-v2`;
- V2 adds a presentation/configuration layer over the existing canonical Product/Variant and Order/payment contracts rather than creating a second catalog/financial truth;
- V2-specific layout/mapping state must not mutate or disable V1, and pilot rollback must be possible by hiding/disabling the V2 entry without restoring Order/catalog data;
- this decision approves the side-by-side architecture only. Final mockup/interaction approval is still required before P2-38 implementation, and replacing/retiring V1 requires a later explicit cutover decision.

Impact:
P2-38 remains review/owner-gated planning work, but its migration boundary is now fixed: build beside V1 first, prove parity, and treat any future cutover as a separate decision.

### DEC-018 — Quick Seller V2 implementation may start functional-first before final visual polish

Status: Active
Date: 2026-09-01

Owner decision:
- the final P2-38 implementation gate is approved now; implementation may begin without waiting for a pixel-final mockup because the owner will refine UI styling after a usable V2 exists;
- preserve DEC-017 completely: V1 remains available and unchanged as the production fallback, V2 stays on separate routes/configuration, and no implicit cutover is authorized;
- start with a functional document-service-family pilot and explicit deterministic mapping into the existing canonical Product/Variant/QuickProduct and Order contracts;
- reuse the existing authoritative checkout/payment/PromptPay/customer/VAT/backdate/tracking/cancellation/refund behavior rather than creating V2-specific financial truth;
- missing/disabled mappings must fail closed, and V2 configuration must remain isolated so unfinished V2 setup cannot alter V1;
- visual refinement, broader service-family expansion, and any V1 retirement/cutover remain follow-up work/decisions after the functional pilot is verified.

Impact:
P2-38 is no longer blocked on mockup approval and may move to `IN_PROGRESS`. The implementation should optimize first for correct functional separation, deterministic mapping, and checkout parity; UI polish may follow without reopening the architecture decision.

### DEC-019 — Tax invoice book and sequence continue across months from September 2026

Status: Active
Date: 2026-09-01

Owner decision:
- August 2026 / Buddhist year 2569 (`invoicePeriod = 202608`) remains an isolated legacy monthly tax-invoice counter period;
- September 2026 (`202609`) starts the continuing tax-invoice sequence at Book `001`, Invoice `001` and is the permanent counter scope for tax invoices whose `invoicePeriod` is `202609` or later;
- crossing a month or year boundary from September 2026 onward must not reset `bookNo` or `invoiceSequence`;
- each book contains 100 invoice numbers: total sequence 100 is Book `001` / Invoice `100`, total sequence 101 is Book `002` / Invoice `001`;
- `invoicePeriod` and the period segment in the full `invoiceNumber` continue to reflect the Order's authoritative `saleDate` in `Asia/Bangkok`, while only the book/sequence counter is continuous;
- already issued tax invoice identities are immutable and are never renumbered by this policy change.

Impact:
Runtime allocation, conversion transactions, reconciliation, and tax-invoice backfill tooling must resolve all periods from `202609` onward to the shared `202609` counter while retaining the actual invoice period on each Order. The existing September counter is reused, so no counter migration is required when this policy is deployed before a later monthly counter has issued numbers.

### DEC-020 — Quotation numbering is monthly, issued on first Send, and revision-stable

Status: Active
Date: 2026-09-01

Owner decision:
- Quotation is a separate document domain and must not reuse Order, receipt, or tax-invoice numbering;
- the issued Quotation number format is `QT-YYYYMM-0001` using the `Asia/Bangkok` business period;
- the sequence resets each calendar month and is zero-padded to four digits;
- Draft Quotations do not receive a real document number;
- the Backend atomically allocates `quotationNumber` only on the first successful `DRAFT -> SENT` transition;
- revisions retain the original `quotationNumber` and increment `revision` instead of allocating a new document number;
- this policy does not create Quotation records for historical Orders and does not alter existing Order or tax-invoice identities.

Impact:
Quotation Phase 1 may implement a dedicated concurrency-safe quotation counter keyed by Bangkok `YYYYMM`, immutable issued snapshots/revisions, and independent print/conversion flows without reusing tax-invoice book/sequence logic.

## Needs Decision

The previously tracked ND-001, ND-003, ND-005, ND-006, and ND-007 are resolved by DEC-010 through DEC-014 above. P2-31 is resolved by DEC-016. P2-38 final implementation approval is resolved by DEC-018; replacing/retiring Quick Seller V1 remains a separate future owner decision.
