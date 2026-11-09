# ADR 0001: Firebase Free Tier Architecture with Manual Admin Workflows

**Status:** Accepted  
**Date:** 2026-11-01  
**Deciders:** Product Owner  

## Context

We need a backend for a legal professional networking mobile app with features including real-time chat, admin approvals, elections, and notifications. Firebase offers two pricing tiers:

- **Spark (Free):** Limited to client-side operations, no Cloud Functions, 1GB storage, 50K reads/day, 20K writes/day
- **Blaze (Pay-as-you-go):** Requires Cloud Functions for automated workflows, typical cost $25-100/month for 500-1000 active users

We want to minimize initial costs while building and validating the product with a small user base.

## Decision

We will architect the app to run entirely on Firebase's **free Spark tier** by implementing admin workflows as **manual in-app operations** rather than automated Cloud Functions:

1. **Admin approvals:** Admins use an in-app "pending applicants" screen to manually approve/reject, writing status updates directly to Firestore
2. **Elections:** Users write votes to Firestore; admins manually count results and update roles
3. **Notifications:** In-app only (no FCM push notifications via Cloud Functions)
4. **Broadcasts:** Admins write directly to a broadcasts collection; clients listen via Firestore streams
5. **All business logic:** Runs client-side in the Flutter app, enforced by Firestore Security Rules

## Consequences

### Positive
- **Zero backend costs** during initial development and launch
- Simple architecture with no server-side code to maintain
- Faster initial development (no Cloud Functions to write/deploy)
- Clear upgrade path: Cloud Functions code can be written later and enabled when migrating to Blaze

### Negative
- **Manual admin work:** Admins must perform actions in-app rather than having automated triggers
- **No push notifications:** Users must open the app to see notifications (acceptable trade-off for free tier)
- **Limited automation:** Election results, approval workflows, and broadcast distribution require manual steps
- **Scalability ceiling:** Free tier limits (50K reads/day) mean we'll need to upgrade before reaching ~200-300 daily active users

### Neutral
- Firestore Security Rules become critical for enforcement (would be important regardless, but now carry more weight)
- Client-side business logic makes the app slightly larger but more offline-capable

## When to Revisit

Upgrade to Blaze tier and implement Cloud Functions when:
- Daily active users approach 150-200 (nearing free tier read/write limits)
- Admin manual workload becomes unsustainable (e.g., 20+ approval requests per day)
- Push notifications become a competitive necessity
- Need for automated election counting or other workflows becomes critical

The architecture is designed to make this migration straightforward—Cloud Functions can be added without changing the core data model.
