---
name: glossy-feature-scout
description: "Use when exploring new product features, workflow opportunities, business-value improvements, or next-phase ideas for the GlossyDesign POS ecosystem. Inspect current source, capabilities, backlog, and decisions to identify high-value feature candidates without implementing them or silently converting them into executable TODOs."
---

# Glossy Feature Scout

Explore what GlossyDesign should build next. This is a Product/Opportunity workflow, not a defect scanner and not an implementer.

## Role boundary

Use this skill for questions such as:
- what useful feature should Glossy add next;
- what shop workflow is still manual or inefficient;
- what existing data/domain can unlock a higher-value workflow;
- what should follow the current phase after the active backlog is complete;
- what product capability would improve cashier speed, production visibility, repeat business, reliability, or owner control.

Do not use this skill as a substitute for `glossy-project-scanner` when the task is primarily finding bugs, contract defects, security gaps, stale architecture, test gaps, or technical debt.

Do not implement application source. Do not create branches, commits, migrations, or product behavior. Feature discovery does not authorize implementation.

## Grounding

Before proposing features:

1. Read workspace-root `AGENTS.md`, `PROJECT_RULES.md`, `TODO.md`, relevant `DECISIONS.md`, and `ARCHITECTURE.md`.
2. Inspect current Frontend and Backend capabilities that materially affect the opportunity; current source is authoritative.
3. Check active durable implementation goals so partial WIP is not mistaken for a missing feature.
4. Search `TODO.md` and active decisions for an equivalent existing item before proposing a candidate.
5. Treat completed TODO history as evidence of what already exists, not as a reason to reopen old work.

Preserve all Frontend/Backend WIP. Feature Scout is read-only against application source.

## Opportunity lenses

Look for opportunities through business and workflow value rather than code novelty. Useful lenses include:

- cashier speed and error reduction;
- customer intake and repeat-customer experience;
- production planning, due work, quality handoff, and job traceability;
- inventory/material planning and purchasing signals;
- payment/document/reconciliation operations;
- customer communication and self-service;
- staff accountability and operational visibility;
- owner reporting and decision support;
- automation of repeated manual shop work;
- better use of existing Orders, Customers, Production Jobs, Uploads, Inventory, and Catalog data;
- integration opportunities that remove duplicate entry without weakening privacy/security/financial boundaries.

Prefer features that compose with existing domains over features that create a second source of truth.

## Evidence quality

A feature candidate should be grounded in at least one concrete source:

- an existing manual workflow visible in current UI/API/domain boundaries;
- a capability/data set that exists but is not yet connected into a useful workflow;
- an explicit owner/business pain point already documented;
- a verified product limitation in the current application;
- external benchmarking or market evidence when such research is explicitly requested or materially useful and available.

Separate verified current-product evidence from external inspiration. Do not present competitor behavior or assumptions as a Glossy requirement.

## Candidate scoring

Evaluate candidates comparatively using these dimensions rather than generating a long wish list:

- **Business value** — revenue, repeat business, cost/time saved, error/risk reduction.
- **User frequency** — how often cashier/staff/owner/customer would benefit.
- **Readiness** — whether required domains/data/contracts already exist.
- **Complexity** — rough implementation and migration cost.
- **Risk** — financial, privacy, security, operational, schema, or policy risk.
- **Dependency/gate** — decisions, external services, hardware, credentials, or incomplete prerequisite work.

Prefer a small ranked set of strong candidates. Do not manufacture candidates merely to fill a report.

## Candidate states

Classify each useful idea as one of:

- `READY_FOR_DISCUSSION` — product opportunity is grounded and coherent, but owner selection is still required.
- `NEEDS_DECISION` — implementation depends on business/product policy that must be decided first.
- `DEPENDENCY_GATED` — useful, but prerequisite product/domain/infrastructure work is incomplete.
- `DEFER` — valid idea but low current value/readiness compared with better candidates.
- `DUPLICATE` — already represented by an active TODO/decision and should not be proposed again.

Feature Scout does not mark a candidate `OPEN` in `TODO.md` by itself.

## Promotion rule

A feature becomes executable backlog work only after explicit owner/Planner promotion of that candidate or an explicit instruction to add the approved feature to the backlog.

Before promotion:
- unresolved product/business choices go to `NEEDS_DECISION`, not invented defaults;
- financial/auth/privacy/schema/deployment semantics require explicit acceptance boundaries;
- define one bounded first phase rather than turning a large concept into one giant TODO;
- identify dependencies, do-not-touch boundaries, acceptance criteria, and required verification.

After explicit approval, backlog writing should follow Governance V2 root-first rules and must not collide with an active implementation runner.

## Recommended output

For each shortlisted candidate, provide:

- feature name;
- current problem/opportunity;
- evidence from current Glossy capability/workflow;
- expected business/user value;
- dependencies and existing reusable domains;
- complexity and risk;
- decisions required;
- recommended candidate state;
- suggested first implementation phase if approved.

Then rank the shortlist and state why the top candidate is the best next investment now.

A useful Feature Scout result normally contains a few differentiated candidates, not dozens of generic SaaS ideas.

## Interaction with other Glossy skills

- `glossy-project-scanner` finds verified technical/product gaps in what already exists.
- `glossy-feature-scout` discovers and ranks new product opportunities.
- `glossy-todo-runner` implements only approved actionable backlog work.
- Specialized skills such as `glossy-pos-ui` may be used later during implementation, not during product discovery unless needed only to inspect an existing interface.

## Stop conditions

Stop at recommendation/decision evidence when:
- owner product policy is required;
- external account/provider/hardware facts are unknown;
- implementation would be needed to validate the concept;
- a candidate duplicates an existing TODO;
- active WIP makes the apparent opportunity ambiguous.

Success means the owner receives a grounded, prioritized set of product opportunities with clear trade-offs and no accidental implementation commitment.
