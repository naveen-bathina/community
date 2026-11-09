# Domain Context: Legal Professional Network

## Overview

A mobile platform connecting legal professionals for networking, case referrals, and community coordination. Membership is controlled through admin approval to maintain professional standards.

## Glossary

### Member
A legal professional with an **approved** account. Members have full platform access: they can view other profiles, send messages, participate in group chat, vote in elections, and be searched by others.

*Not a Member:* An applicant whose registration is still pending, or a rejected applicant.

### Applicant
Someone who has authenticated (via phone OTP or Google Sign-In) and submitted their professional profile, but has not yet been approved by an admin. Applicants can only view a "pending approval" screen—they cannot access member features.

### Profile
The professional identity of a Member, containing:
- Contact: name, photo, email, phone
- Legal credentials: bar admissions (jurisdiction, bar number, year admitted), law school
- Professional details: practice areas, firm/organization affiliation, years of experience, location (city/state)
- Optional: bio, availability status, achievements, CLEs, publications

Profiles are visible to all approved Members. Applicant profiles are only visible to Admins during the approval process.

### Admin
A Member with elevated privileges who can:
- Approve or reject Applicants
- Remove Members from the platform
- Moderate the Group Chat (delete messages, mute or ban Members)
- Send Broadcasts
- View audit logs of admin actions

Admins are either **Founding Admins** (the first 3-5 approved Members) or **Elected Admins** (chosen through Elections).

### Founding Admin
One of the first 3-5 Members to join the platform, automatically granted admin privileges to bootstrap community governance. Founding Admins serve until the first Election completes.

### Election
A democratic process for selecting Admins, occurring annually after the first Election. An Election has three phases:
1. **Nomination Period** (1 week): Members nominate themselves or others for admin roles
2. **Voting Period** (2 weeks): Members cast votes for nominees
3. **Results**: Top 3-5 vote-getters become the next Admins

The **first Election** triggers when the community reaches 20-30 approved Members OR after 3 months, whichever comes first.

### Conversation
A private 1-1 chat between two Members. Any approved Member can start a Conversation with any other approved Member. Conversations support text, images, file attachments (up to 5MB), and links.

### Group Chat
A single community-wide chat visible to all approved Members. Supports the same message types as Conversations. Admins can delete messages, pin important messages, and mute or ban Members from participating.

### Broadcast
A platform-wide announcement sent by an Admin. Broadcasts are visible to all approved Members and appear in the notification feed. Only Admins can create Broadcasts—regular Members cannot request or suggest them.

### Message
Content sent within a Conversation or Group Chat. Messages can contain:
- Text (with emoji)
- Image attachments
- File attachments (PDF, DOC, DOCX—max 5MB per file)
- Links (with preview generation)

Messages cannot be edited after sending. Admins can delete any message in Group Chat; users can only delete their own messages in Conversations.

### Notification
An in-app alert triggered by platform events:
- New message in a Conversation
- New message in Group Chat
- New Broadcast
- Registration status change (for Applicants: approved/rejected)
- Election events (nomination period opens, voting period opens, results announced)

Notifications appear in an in-app feed with a badge counter. No push notifications—users must open the app to see them.

### Practice Area
A legal specialization or field of law (e.g., Family Law, Immigration Law, Corporate Law, Criminal Defense). Members list their Practice Areas on their Profile, and other Members use Practice Areas as a primary filter when searching for referrals.

### Bar Admission
Proof that a Member is licensed to practice law in a specific jurisdiction. Includes:
- Jurisdiction (state/province/country)
- Bar number (license identifier)
- Year admitted

Members can have multiple Bar Admissions. This information is used during Applicant approval to verify professional credentials.

### Availability Status
A flag on a Member's Profile indicating whether they are currently accepting referrals or new clients. Examples: "Accepting Referrals", "Not Taking New Clients", "Available for Consultation".

### Referral
The act of recommending another Member to handle a case or legal matter outside one's own expertise. Referrals are facilitated through search/filtering by Practice Area and Availability Status, followed by direct contact via Conversation.

*Note:* Referrals are not tracked as formal objects in the system—they happen through search discovery and subsequent messaging.

### Approval
The decision by an Admin to grant an Applicant full Member status. Once approved, the Applicant becomes a Member and gains access to all platform features.

### Rejection
The decision by an Admin to deny an Applicant's registration. Rejected Applicants receive a notification (optionally with a reason) and cannot access Member features. They remain in the system with "rejected" status.

### Moderation Action
An action taken by an Admin to enforce community standards:
- Deleting a Message from Group Chat
- Muting a Member from Group Chat (temporary ban: 24 hours or 7 days)
- Banning a Member entirely (removes platform access)
- Pinning a Message to the top of Group Chat

All Moderation Actions are logged in an audit trail visible to Admins.

### Audit Log
A record of significant admin actions (approvals, rejections, moderation, Member removal). Used for transparency and accountability. Visible only to Admins.

## Context Boundaries

This system models **community governance and professional networking**, not legal case management. We do not track:
- Cases or legal matters
- Formal referral agreements or fees
- Client information
- Billing or payments
- Document collaboration or version control

Members use external systems for case management—this platform is purely for networking, coordination, and community communication.
