# Vakeel Saab App — Test-Driven Development (TDD) Master Test Suite

**Objective:** This document provides the complete set of unit, widget, integration, and database Row-Level Security (RLS) test cases required for a strict Test-Driven Development (TDD) workflow. Developers and AI coding agents must write and execute these failing tests *before* writing any implementation code.

---

## Module 1: Authentication & Onboarding

### 1.1 Phone OTP Authentication
* **Test ID:** `TDD-AUTH-01`
  * **Test Type:** Unit Test
  * **Description:** Validate 10-digit mobile number input formatting.
  * **Given:** User enters `"9876543210"`.
  * **When:** Phone validator runs.
  * **Then:** Returns `null` (valid).
* **Test ID:** `TDD-AUTH-02`
  * **Test Type:** Unit Test
  * **Description:** Reject invalid phone numbers.
  * **Given:** User enters `"12345"` or `"ABC1234567"`.
  * **When:** Phone validator runs.
  * **Then:** Returns error message `"Enter a valid 10-digit mobile number"`.

### 1.2 Joining Form Validators & BCI Compliance
* **Test ID:** `TDD-AUTH-03`
  * **Test Type:** Unit/Widget Test
  * **Description:** Enforce advocate age restriction ($\ge 21$ years).
  * **Given:** Date of birth selected results in age 20 years.
  * **When:** Form validation is triggered.
  * **Then:** Validation fails with message `"Advocate must be at least 21 years old"`.
* **Test ID:** `TDD-AUTH-04`
  * **Test Type:** Integration Test
  * **Description:** Block duplicate enrollment number registration at database layer.
  * **Given:** An advocate with enrollment number `"UP/1234/2020"` already exists in `public.users`.
  * **When:** A new registration attempt is made with the same enrollment number.
  * **Then:** Supabase raises a unique constraint violation error, caught by UI and displayed as an error banner.
* **Test ID:** `TDD-AUTH-05`
  * **Test Type:** Widget Test
  * **Description:** Terms of Service & BCI Ethics checkbox enforcement.
  * **Given:** Joining form fields are completely filled, but terms checkbox is `false`.
  * **When:** User taps the "Submit Application" button.
  * **Then:** Button remains disabled and form submission is prevented.

---

## Module 2: Dual-Tier Verification & Admin Review

### 2.1 Verification State Routing
* **Test ID:** `TDD-VER-01`
  * **Test Type:** Widget/Router Test
  * **Description:** Route pending users to the waiting screen.
  * **Given:** Logged-in user has `status = 'pending'`.
  * **When:** App router evaluates session and user profile status.
  * **Then:** User is redirected to `PendingApprovalScreen` and blocked from accessing the Community Wall.
* **Test ID:** `TDD-VER-02`
  * **Test Type:** Database/Integration Test
  * **Description:** Admin approval workflow transition.
  * **Given:** Admin updates a user's status from `'pending'` to `'approved'`.
  * **When:** Database trigger or API call commits.
  * **Then:** `status` updates to `'approved'`, and an FCM notification record is inserted into `public.notifications`.

### 2.2 Tier 2 Verification Badge
* **Test ID:** `TDD-VER-03`
  * **Test Type:** Widget Test
  * **Description:** Render Gold/Blue badge for verified advocates.
  * **Given:** User object has `is_verified = true`.
  * **When:** User profile widget renders.
  * **Then:** Verified checkmark badge (`#D4AF37`) is visible alongside the advocate's name.

---

## Module 3: Community Wall, Social & Moderation

### 3.1 Post Creation & Optimistic Feed Updates
* **Test ID:** `TDD-WALL-01`
  * **Test Type:** Widget Test
  * **Description:** Create text and media post.
  * **Given:** Approved user enters valid post content and attaches an image.
  * **When:** User taps "Post".
  * **Then:** Post appears instantly at index 0 of the feed (optimistic update) while syncing with Supabase `posts` table.
* **Test ID:** `TDD-WALL-02`
  * **Test Type:** Security RLS Test
  * **Description:** Restrict post creation to approved members only.
  * **Given:** User with `status = 'pending'` executes `INSERT INTO public.posts`.
  * **When:** RLS policy `Approved users can create posts` evaluates.
  * **Then:** Supabase blocks execution with PostgreSQL error code `42501` (Permission Denied).

### 3.2 Report & Moderation System
* **Test ID:** `TDD-MOD-01`
  * **Test Type:** Integration Test
  * **Description:** Flagging inappropriate content.
  * **Given:** User taps 3-dot overflow menu on a post and selects "Report for Unprofessional Conduct".
  * **When:** Report submission completes.
  * **Then:** A row is successfully inserted into `public.reports` with `target_type = 'post'` and `status = 'pending'`.

---

## Module 4: Directory, Search & Privacy Phone Requests

### 4.1 Trigram Full-Text Search
* **Test ID:** `TDD-DIR-01`
  * **Test Type:** Database Query Test
  * **Description:** Debounced global search using trigram index (`pg_trgm`).
  * **Given:** Database contains advocates named "Rajesh Sharma" and "Ramesh Verma".
  * **When:** Query searches for `"Rajesh"`.
  * **Then:** `idx_users_trgm_search` returns matching records sorted by relevance without full table scan.

### 4.2 Phone Number Privacy & Access Request Flow
* **Test ID:** `TDD-PRIV-01`
  * **Test Type:** Widget Test
  * **Description:** Default phone masking in directory view.
  * **Given:** User views a peer advocate's profile where `phone_visibility = false` and no accepted request exists.
  * **Then:** Phone number is rendered as `+91 XXXXX XXXXX`.
* **Test ID:** `TDD-PRIV-02`
  * **Test Type:** Integration Test
  * **Description:** Contact access request workflow.
  * **Given:** User A requests phone access for User B.
  * **When:** User B accepts the request in settings.
  * **Then:** `contact_requests.status` updates to `'accepted'`, and User A's UI dynamically unmasks User B's raw phone number.

---

## Module 5: Democratic Elections & Voting Integrity

### 5.1 Election Lifecycle & Tier 2 Restrictions
* **Test ID:** `TDD-ELC-01`
  * **Test Type:** Security RLS Test
  * **Description:** Enforce Tier 2 verification for casting votes.
  * **Given:** User is an approved Tier 1 member (`is_verified = false`) attempting an `INSERT` into `public.votes`.
  * **When:** RLS policy `Tier 2 Advocates can cast vote` evaluates.
  * **Then:** Database rejects the insert query.
* **Test ID:** `TDD-ELC-02`
  * **Test Type:** Database Constraint Test
  * **Description:** Anti-double voting constraint enforcement.
  * **Given:** User has already cast a vote for `position_name = 'President'` in `election_id = 'uuid-123'`.
  * **When:** User attempts to insert a second vote for the same position in the same election.
  * **Then:** PostgreSQL composite unique constraint `unique_vote_per_position` raises a unique violation error.

---

## Module 6: Broadcast Channels & Push Notifications

### 6.1 Broadcast Priority Handling
* **Test ID:** `TDD-BRD-01`
  * **Test Type:** Integration Test
  * **Description:** Admin broadcast dispatch with priority flag.
  * **Given:** Admin creates a broadcast with `priority = 'strike_notice'`.
  * **When:** Broadcast row is committed to `public.broadcasts`.
  * **Then:** Supabase webhooks trigger FCM edge function to dispatch high-priority push notifications to all approved user device tokens.