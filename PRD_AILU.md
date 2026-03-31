# AILU MVP: Unified Community + Client + Case + Sub-association Management Platform

## Problem Statement

AILU needs a single unified platform to manage a large distributed legal community (advocates, aspirants, students), practice clients, legal cases, and sub-associations. Existing workflows are manual, fragmented (WhatsApp/email/spreadsheets), and lack consistent onboarding, trust, and monetization operations.

Without it:

- community interactions are unstructured,
- membership/subscription management is error-prone,
- client engagement and service delivery are difficult to scale,
- case tracking and advocate matchmaking are brittle,
- local advocate-led chapters cannot self-govern efficiently.

## Solution

Build AILU as an integrated web platform with:

- member profiles & role access
- tiered pricing/subscriptions
- client accounts + billing
- case management + documents/history + vakalat matching + review advocates
- sub-association creation/management by advocates
- event/forum content + mentorship
- analytics and operations dashboards

## User Stories

1. As an aspirant, I want to sign up with one profile, so I can join quickly.
2. As an advocate, I want premium tier access, so I can get exclusive mentorship.
3. As a student, I want to browse workshops, so I can plan learning.
4. As an admin, I want to configure pricing plans with trials/discounts, so I can optimize conversion.
5. As an admin, I want role-based groups (member/moderator/organizer), so governance is clear.
6. As a member, I want subscription self-service, so I can manage costs.
7. As an admin, I want revenue/churn by plan, so I can optimize pricing.
8. As a member, I want forums to network.
9. As an admin, I want segmented announcements by tier.
10. As a member, I want event booking.
11. As an organizer, I want to create paid capacity-limited events.
12. As a student, I want mentorship discovery.
13. As an admin, I want event reminders.
14. As a member, I want district/state filters for local chapters.
15. As an admin, I want CSV exports of members.
16. As a member, I want KYC docs upload.
17. As an admin, I want content categories.
18. As a member, I want saved resources.
19. As an admin, I want manual offline payments.
20. As a member, I want payment history.
21. As an admin, I want auto renewal logic.
22. As an admin, I want client accounts (firms/corporate).
23. As an admin, I want client contacts/roles.
24. As an admin, I want client quote/invoice tracking.
25. As a client, I want seat assignments to teams.
26. As an admin, I want client tiered enterprise pricing.
27. As a client, I want usage ROI reports.
28. As an admin, I want client renewal reminders.
29. As an admin, I want cohort mentorship requests from clients.
30. As support agent, I want client dispute threads.
31. As a client, I want transferable membership credits.
32. As a client, I want case intake+tracking.
33. As advocate, I want case status updates.
34. As a client, I want case document upload.
35. As admin, I want best advocate search for vakalat.
36. As client, I want second-opinion advocate review.
37. As client, I want full case history.
38. As advocate, I want workload + backup advocate suggestions.
39. As admin, I want bookmark advocates for fast assignment.
40. As client, I want case-to-invoice linkage.
41. As advocate, I want milestone document sign-off.
42. As client, I want appearance reminders.
43. As client, I want advocate performance history.
44. As client, I want short-term review engagements.
45. As admin, I want case status reports for audit.
46. As advocate, I want sub-association creation.
47. As lead, I want invite members.
48. As member, I want join requests.
49. As leader, I want sub-admin delegation.
50. As member, I want shared case resources in group.
51. As leader, I want association event pricing.
52. As leader, I want membership removal.
53. As sub-admin, I want role control.
54. As leader, I want association KPIs.
55. As member, I want join multiple associations.

## Implementation Decisions

- Modular product in layers:
  - Auth/profile module
  - Role/permissions module
  - Pricing/subscription module
  - Client CRM + billing module
  - Case management module
  - Advocate discovery + vakalat workflow module
  - Sub-Association module
  - Event/Forum module
  - Document/database with audit trail
  - Analytics dashboard module
- DB domain model:
  - Users, Roles, Profiles, PricingPlans, Subscriptions
  - Clients, ClientContacts, Contracts, Invoices
  - Cases, CaseDocuments, CaseHistory
  - Advocates, VakalatAssignments, ReviewRequests
  - SubAssociations, AssociationMemberships, AssociationRoles
  - Events, Posts, DiscussionThreads
- Payment infra (Stripe/Razorpay + webhooks)
- Permissions: owner/advocate/client/admin tiers, plus association-level admins
- Workflow states:
  - case (intake->active->review->closed)
  - subscription (trial->active->past_due->canceled)
  - association (pending/active/inactive)
- Search/matching:
  - advocate by specialty/location/rating/availability
- Notifications:
  - email/push for deadlines/status changes/new assignments
- India-specific rules for GST and compliance.

## Testing Decisions

- Behavior tests: signup, client onboarding, case lifecycle, advocacy matching, association member flows.
- Unit tests for pricing rules, matches, role checks.
- API contract tests for payment integration and notifications.
- E2E tests for critical end-to-end path.
- Data validation tests for reporting metrics.
- Prior art: existing community SaaS + legal tech workflow test patterns.

## Out of Scope

- Native mobile app
- Enterprise SSO (initial)
- Full e-filing integration
- Predictive legal outcomes ML
- Real-time chat/VoIP
- Complete CRM pipeline/ERP integration (phase 2)

## Further Notes

- MVP focus:
  - member/client/case core + subscriptions + association governance
- Phase 2:
  - localization, PWA, mobile notifications, advanced integrations.
- While repo currently minimal, this PRD drives design into a structured roadmap.
