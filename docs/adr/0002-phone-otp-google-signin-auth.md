# ADR 0002: Phone OTP and Google Sign-In Instead of Email/Password

**Status:** Accepted  
**Date:** 2026-11-01  
**Deciders:** Product Owner  

## Context

We need to choose authentication methods for a mobile-first legal professional networking app. Traditional options include:

- **Email/Password:** Universal but requires password management, reset flows, and increases user friction
- **Phone OTP:** Mobile-native, passwordless, tied to device, requires SMS verification
- **Google Sign-In:** One-tap authentication, leverages existing professional Google accounts, no password management
- **Multiple providers:** More choice but increased implementation and testing complexity

Our users are legal professionals using mobile devices, likely with professional Google accounts (Gmail/Google Workspace).

## Decision

We will use **Phone OTP as the primary authentication method** and **Google Sign-In as an alternative**, eliminating email/password authentication entirely.

**Authentication flow:**
1. User chooses Phone OTP or Google Sign-In
2. Phone OTP: Enter phone number → receive SMS code → verify
3. Google Sign-In: One-tap sign-in with Google account
4. New users complete professional profile form after authentication
5. Profile status set to "pending" until admin approval

## Consequences

### Positive
- **Passwordless experience:** No password creation, storage, or reset flows needed
- **Mobile-optimized:** Phone OTP is native to mobile UX; autofill makes it seamless
- **Professional accounts:** Google Sign-In leverages existing professional email addresses
- **Reduced support burden:** No "forgot password" tickets
- **Security:** No password database to breach; phone and Google both have strong security
- **Simpler codebase:** Two auth methods instead of three

### Negative
- **Phone number required:** Users without phone access (rare for professionals) cannot use OTP
- **SMS costs:** Firebase Phone Auth has per-verification costs on Blaze tier (free tier: 10K verifications/month)
- **Google dependency:** Users without Google accounts (rare but possible) have only one option (Phone OTP)
- **International SMS:** OTP may have reliability issues in some countries

### Neutral
- Email still collected during profile creation (for contact purposes, not authentication)
- Users can switch between phone and Google auth methods if needed (link multiple providers)

## Alternatives Considered

**Email/Password:**
- Rejected: Higher friction, password management overhead, less mobile-friendly

**Phone OTP only:**
- Rejected: Wanted fallback option for users who prefer not to share phone numbers

**All three methods (Phone + Google + Email/Password):**
- Rejected: Added complexity without significant benefit; passwordless is the future

## When to Revisit

Reconsider this decision if:
- SMS costs become prohibitive (though 10K free verifications/month covers initial growth)
- User feedback strongly requests email/password option
- International SMS reliability causes significant signup drop-off
- Apple Sign-In becomes necessary for App Store requirements (can add as third option)

## Implementation Notes

- Firebase Phone Auth requires app verification for production (reCAPTCHA on web, automatic on native)
- Both methods map to Firebase Auth UIDs, so user profiles work identically regardless of auth method
- Security Rules enforce authentication requirement: `request.auth != null`
