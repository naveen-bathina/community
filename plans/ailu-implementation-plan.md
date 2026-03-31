# Plan: AILU Unified Platform

> Source PRD: PRD_AILU.md

## Architectural decisions

- **Routes**:
  - `/auth/*` for auth flows (signup/login/recover)
  - `/me/*` for user profile / settings
  - `/pricing/*` for plan catalog and subscription flows
  - `/clients/*` for client account CRM
  - `/cases/*` for case management and docs
  - `/associations/*` for sub-association management
  - `/events/*` and `/forums/*` for community content
  - `/admin/*` for admin dashboards and reports

- **Schema**:
  - Users with roles: `member`, `advocate`, `student`, `admin`, `client_user`
  - `subscription_plans` and `subscriptions` for tiered pricing
  - `clients`, `client_contacts`, `client_contracts`, `invoices`
  - `cases`, `case_documents`, `case_history`, `vakalat_assignments`
  - `sub_associations`, `association_memberships`, `association_roles`
  - `events`, `posts`, `discussion_threads`

- **Key models**:
  - `User`, `Profile`, `Role`
  - `SubscriptionPlan`, `Subscription`, `PaymentTransaction`
  - `Client`, `ClientContact`, `ClientInvoice`
  - `Case`, `CaseDocument`, `CaseLog`, `AdvocateAssignment`
  - `SubAssociation`, `AssociationMembership`, `AssociationRole`

- **Auth / Authorization**:
  - JWT-based API auth for web/mobile clients
  - Role and resource-policy guard (RBAC + resource ownership checks)
  - Association scoping for sub-association operations

- **Integration boundaries**:
  - Payment provider (Stripe/Razorpay) for subscription and invoicing
  - Email service for notifications and reminders
  - Attachments storage for documents (S3 or equivalent)

---

## Phase 1: Basic Member & Advocate onboarding + profile

**User stories**: 1, 2, 3, 16, 6

### What to build

User accounts with signup/login, profile management, role selection, and KYC document attachment. Public catalog of membership tiers with checkout stub.

### Acceptance criteria

- [ ] User can register and login
- [ ] User can update profile and upload KYC documents
- [ ] User can select roles (advocate/student/aspirant)
- [ ] User can view pricing plans
- [ ] Basic RBAC enforced for protected endpoints

---

## Phase 2: Pricing, subscription lifecycle, community content

**User stories**: 4, 5, 7, 8, 9, 10, 11, 13, 14, 18

### What to build

Tiered plan management, subscription checkout/integration, membership status checks. Community features: forums, event listing/booking, announcements.

### Acceptance criteria

- [ ] Admin can create pricing plans
- [ ] Subscription buy/upgrade/downgrade/cancel flows work end-to-end
- [ ] Paid access gating works for premium content/events
- [ ] Forum posts and event RSVPs are CRUD-capable
- [ ] Targeted announcements and district/state filters exist

---

## Phase 3: Client management and billing

**User stories**: 22-31

### What to build

Client CRM module, client contacts, contracts, seat assignment, quotes/invoices, payment tracking and accounting.

### Acceptance criteria

- [ ] Admin can create clients and contacts
- [ ] Contracts and billing periods are tracked
- [ ] Invoices can be generated and paid through provider stub
- [ ] Client usage reports (ROI of seats, revenue, churn)
- [ ] Manual offline payment entry works

---

## Phase 4: Case management and advocate matchmaking

**User stories**: 32-45

### What to build

Case lifecycle management, document library with versioning and history logs, advocate search for vakalat and review requests, deadlines and alerts.

### Acceptance criteria

- [ ] Case creation and status management works
- [ ] Case document upload/download with access controls works
- [ ] Advocate matchmaking by specialization/location/rating available
- [ ] Vakalat assignment workflow and review advocate requests are enabled
- [ ] Case history events tracked and auditable

---

## Phase 5: Sub-association features + admin reporting

**User stories**: 46-55

### What to build

Sub-association creation and member management by advocates, role delegation, shared content and events within associations, KPIs and metrics.

### Acceptance criteria

- [ ] Advocate can create and configure sub-association
- [ ] Members can join by invite/approval
- [ ] Sub-admin assignment and member role changes work
- [ ] Association-scoped events/resources exist
- [ ] Association reports show active membership, event participation

---

## Phase 6: Admin dashboards, analytics, compliance

**User stories**: 15, 21, 29, 45, additional cross-cutting requirements

### What to build

Central admin dashboard for member/client/case metrics, CSV exports, reminder rules, compliance log and audit reporting.

### Acceptance criteria

- [ ] Admin can see key metrics (MRR, churn, client revenue, case volume)
- [ ] CSV export for members and cases works
- [ ] Renewal reminders and status alerts are generated
- [ ] Audit logs for critical actions are queryable

---

## Checkpoint questions

1. Does the phase granularity feel right (too coarse or too fine)?
2. Should any phase be split (e.g., split Case from Client) or merged?
3. Are there mandatory compliance or data privacy constraints to add before development starts?
