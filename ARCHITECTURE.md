# GlossyDesign — Current Architecture

Governance: V2  
Last verified: 2026-08-31 (Asia/Bangkok)  
Frontend main: `2d36e586f50eb2aa12cf43978727cc989b1a2834`  
Backend main: `94a82b8178014b0f55696c3545e978d52556b4a7`

This document is a source snapshot, not a target plan. `TODO.md` is the sole active execution backlog and `DECISIONS.md` owns durable product/architecture decisions.

## 1. Repository and governance topology

The workspace contains independent application repositories:
- `GlossyPOS-Frontend` — Next.js App Router / TypeScript / MUI.
- `GlossyPOS-Backend` — NestJS / TypeScript / Mongoose / MongoDB.

Governance V2 is cross-repository. The six governance files are `AGENTS.md`, `ARCHITECTURE.md`, `DECISIONS.md`, `PROJECT_RULES.md`, `TODO.md`, and `WORKFLOW.md`. The workspace-root copies remain the runtime working set used by the approved TODO Runner; P2-09 versions them in the dedicated `GlossyDesign-Governance` repository and uses drift checks rather than creating a parent Git repository around the nested application histories.

## 2. Runtime topology

```text
Browser / cashier / customer device
        |
        | Next.js pages + same-origin /api/*
        v
GlossyPOS-Frontend
  |- /api/admin/session      signed HTTP-only frontend session broker
  `- /api/backend/[...path]  BFF/proxy; attaches backend bearer identity
        |
        v
GlossyPOS-Backend
  |- ThrottlerGuard + AuthGuard
  |- ValidationPipe / controllers / services
  |- MongoDB via Mongoose
  |- private AWS S3 upload storage
  |- LINE integration
  `- SSE / persisted customer-display session state
```

Anonymous routes are intentionally narrow. Authenticated application traffic normally goes through the Frontend BFF so backend bearer credentials remain server-side.

## 3. Frontend route inventory

Current App Router output includes:

Public/customer-facing:
- `/`, `/landing`, `/login`
- `/customer`, `/customer-display`
- `/upload`, `/upload/line`
- `/track`
- `/privacy-policy`, `/terms`

Protected/admin/cashier:
- `/home`
- `/home/quick-sale`
- `/home/posseller`
- `/home/orders`
- `/home/saleListPage` (legacy Orders alias)
- `/home/customers`
- `/home/production`
- `/home/storage`
- `/home/stock`
- `/home/settings/quick-menu`
- `/home/staff`
- `/home/system-health`
- `/home/invoice/[orderId]`
- `/print/invoice/[orderId]`

Major frontend ownership:
- Quick Seller — primary cashier workflow.
- Configured POS — catalog-driven detailed sale workflow.
- Orders — payment, cancellation, invoice, tracking-access and historical sale actions.
- Customers — reusable customer profiles while Orders retain immutable sale/document snapshots.
- Production Board — operational job list/stage handling.
- Storage/Uploads — public intake plus authenticated file management.
- Stock — inventory item/movement operations.
- Customer Display — same-machine and paired-device checkout display.
- Dashboard / Action Center — operational drill-downs and alerts.

## 4. Backend module inventory

`AppModule` currently registers:
- `AuthModule`
- `UploadsModule`
- `OrdersModule`
- `ProductModule`
- `QuickProductModule`
- `DashboardModule`
- `NotificationsModule`
- `InventoryModule`
- `ProductionModule`
- `CustomersModule`
- `CustomerDisplayModule`
- `LineModule`
- `HealthController` / `HealthService`

Global guards are `ThrottlerGuard` and `AuthGuard`.

Primary persisted domains include Orders/payment facts, Product/Variant, QuickProduct shortcuts, Uploads, Users/Auth sessions/Audit events, Notifications, Inventory, Production Jobs, Customers and Customer Display sessions.

## 5. Catalog and cashier ownership

DEC-011 is implemented incrementally:
- `Product` / Variant is the canonical long-term sellable catalog identity.
- `QuickProduct` remains the Quick Seller presentation/shortcut record and keeps its own stable shortcut `_id`, `code`, and `typeCode`.
- A QuickProduct may map explicitly to canonical `productId` + `variantId`.
- Quick Sale order lines carry `quickProductId` separately from canonical `productId`/`variantId`; backend pricing resolves the shortcut first and follows the canonical mapping when present.
- Legacy/unmapped QuickProducts remain readable during migration.
- Custom/ad-hoc lines and authorized per-sale price overrides remain explicit exceptions and do not rewrite shared catalog prices.

## 6. Orders and financial truth

Order creation and payment behavior is backend-authoritative:
- Order creation supports request idempotency.
- Pricing resolves catalog/custom identity at the backend boundary.
- Money is handled with satang-safe shared calculations.
- Added payments use atomic/idempotent acceptance and append payment facts.
- Financial statuses are derived from payment facts rather than generic PATCH writes.
- Tax-invoice conversion and number allocation are transaction-safe.
- Normal cashier production no longer hard-deletes Orders; `POST /orders/:id/cancel` records audited cancellation/refund facts.
- Reporting includes receipt/refund adjustment facts.
- Protected tracking-access issuance creates an opaque capability for customer documents.

Representative Orders routes include create/list/summary/export, status update, tracking access, tax-invoice conversion, cancellation and payment append.

## 7. Customers, production and inventory

Customers:
- Saved Customer identity is optional; walk-in sales remain valid.
- Orders may link `customerId` while preserving denormalized historical billing/contact snapshots.
- Customer detail derives order/outstanding/job/upload context from authoritative server queries.

Production:
- Backend owns Production Jobs with list/detail/create/update/stage APIs; Frontend exposes executable creation, operational filtering, Job detail, and stage progression.
- Stage transitions are server-owned and audited. Order-line ownership may be explicit through `orderLineIndexes` when one Order is split across multiple Production Jobs.
- Entering `producing` is the material-consumption boundary: the Job locks its material-issue plan before the first movement, resolves Product/Variant recipes, and issues Inventory idempotently. Public Tracking readiness aggregation follows DEC-014 while final delivery remains an explicit Order-level handoff.

Inventory:
- Stock items and append-only movements are separate from Product/Variant catalog identity.
- Product/Variant recipes reference canonical Stock Items with explicit unit conversion where required. Automatic Production issues retain immutable Order/Job and recipe-snapshot provenance; retry keys prevent double consumption.
- Manual `waste` remains a distinct privileged movement fact rather than being folded into automatic recipe consumption.

## 8. Upload and customer-display architecture

Uploads:
- public upload intake is throttled and bounded;
- files are stored privately in S3 with Mongo metadata;
- authenticated storage views use signed access and structured workflow metadata;
- intake can link to Orders without making customer/private APIs public.

Customer Display:
- same-machine `localStorage`/`BroadcastChannel` behavior is preserved;
- paired devices use persisted scoped `CustomerDisplaySession` records and opaque capabilities;
- publisher ownership is authenticated;
- public display projections strip unnecessary PII;
- rotate/revoke lifecycle exists for pairings;
- reconnect/state delivery is scoped per display session.

## 9. Tracking and public boundaries

Public Tracking uses exact minimal contracts and opaque capability support. Public responses intentionally avoid exposing full customer/contact/cart/financial detail. Customer, Production, Inventory and staff-management APIs remain authenticated.

## 10. Governance drift rule

After any merged FE/BE change that materially changes architecture, update the recorded main SHAs and affected sections here. The dedicated Governance repository provides a lightweight drift script that reports:
- whether the workspace-root six governance files match their versioned copies; and
- whether recorded Frontend/Backend main SHAs match the checked-out application repositories.

A drift report is evidence only; it does not create a second execution queue and must never mutate `TODO.md` automatically.
