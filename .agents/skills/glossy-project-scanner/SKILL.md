---
name: glossy-project-scanner
description: "Use when the user or scheduled Glossy Project Scanner asks to scan, audit, or assess the GlossyDesign workspace for verified gaps, project health, architecture/contract/security/data-integrity/performance/test/code-health/runtime-UX findings, or new backlog candidates. This is a Planner/Auditor workflow: it is read-only against Frontend/Backend application source and must not implement findings."
---

# Glossy Project Scanner

Audit GlossyDesign against current source and Governance V2. Produce evidence and planning work, not implementation.

## Authority and boundaries

- Read the active governance files from the workspace root: `AGENTS.md`, `PROJECT_RULES.md`, `DECISIONS.md`, `ARCHITECTURE.md`, `TODO.md`, and `WORKFLOW.md`.
- Treat current checked-out source as authoritative for current behavior. Archived audits are historical evidence only.
- `GlossyPOS-Frontend` and `GlossyPOS-Backend` are separate Git repositories.
- Never edit Frontend/Backend application source, create implementation commits, merge branches, reset/clean WIP, run destructive commands, or invent product/business policy.
- Scanner findings do not authorize implementation. Implementation belongs to the TODO Runner or an explicit implementation task.

## Start each scan

1. Inspect Frontend and Backend branch, HEAD, and working-tree status without modifying them.
2. Read `docs/reports/project-scanner-state.json` and `docs/reports/project-scanner-latest.md` when present.
3. Check for an active durable implementation/TODO Runner goal before planning writes.
4. Record the current Bangkok business date and the baseline FE/BE SHAs.
5. Choose scan mode:
   - incremental when a recent full scan exists for the current Bangkok calendar day and relevant SHAs changed;
   - full when explicitly requested, when no reliable state exists, or when no full scan has been completed for the current Bangkok calendar day.

Do not use filesystem modified times to decide governance authority.

## Evidence collection

Prefer targeted, low-overhead evidence before broad scans. Use lnwjud workspace context/search, Git, symbols/graphs, diagnostics, changed-file context, tests/coverage context, and browser/runtime evidence when materially useful.

Inspect the areas relevant to the scan:

- architecture and module boundaries;
- Frontend ↔ Backend request/response contracts;
- auth/RBAC and security boundaries;
- financial/data-integrity invariants;
- persistence/schema/index behavior;
- performance and avoidable hot paths;
- tests, coverage gaps, and verification reliability;
- dead, duplicate, stale, or generated code accidentally treated as source;
- deployment/runtime configuration when relevant;
- rendered UX, responsive behavior, console/runtime errors, and critical flows when browser evidence is useful.

Use specialized installed skills only when they materially improve evidence. Do not claim Playwright, Sonar, Knip, jscpd, security scanners, coverage, or another tool ran unless it was actually configured and executed.

## Finding quality gate

A scanner finding is valid only when all are true:

1. It is re-verified against current source or current runtime evidence.
2. It is not merely an archived finding repeated without fresh evidence.
3. `TODO.md` has been searched for an equivalent active item.
4. The finding states concrete evidence and why it matters.
5. It identifies priority/risk and FE/BE/cross-repo ownership.
6. It records dependencies or blockers and explicit do-not-touch boundaries where relevant.
7. It has observable acceptance criteria and required verification.

If an equivalent TODO already exists, update evidence rather than creating a duplicate when governance writes are allowed.

If the correct behavior depends on an unresolved product/business decision, route it to `BLOCKED` / Needs Decision evidence. Do not invent the decision.

## Collision and write rules

Scanner may always update its own planning artifacts under `docs/reports/` when permitted:

- `project-scanner-latest.md`
- `project-scanner-state.json`

If an implementation/TODO Runner durable goal is active, do not concurrently mutate `TODO.md` or `DECISIONS.md`. Record proposed backlog/decision changes in the scanner report for later reconciliation.

When no implementation runner is active, Scanner may update workspace-root planning governance only as allowed by DEC-009. If one of the six governance files changes, follow the root-first governance location rule and reconcile the versioned `GlossyDesign-Governance` mirror before terminal completion when authorized. Never edit the mirror first.

Scanner must never turn a report write into an application-source change or implementation Git commit.

## Report shape

Keep the latest report concise and evidence-first. Include:

- scan timestamp and Bangkok date;
- scan mode: incremental or full;
- Frontend/Backend branch, HEAD, and dirty/clean state;
- implementation-runner collision state;
- surfaces actually inspected and tools actually run;
- verified findings grouped by priority;
- existing TODO matches;
- proposed new TODOs or Needs Decision items;
- deferred checks and why;
- next recommended scan focus.

If nothing new is verified, explicitly report that no new actionable finding was found. Do not manufacture backlog work to make a scheduled scan look productive.

## Stop conditions

Stop and report rather than crossing the Planner boundary when:

- implementation would be required to prove/fix the finding;
- a product/business decision is required;
- destructive access would be required;
- evidence is insufficient or unavailable;
- a concurrent implementation runner makes governance mutation unsafe.

The successful outcome of this skill is trustworthy project evidence and a clean backlog, not a source-code diff.
