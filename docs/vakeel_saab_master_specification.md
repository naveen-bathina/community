# Vakeel Saab App — Master Implementation Specification for AI Coding Agents

**Version:** 2.0.0  
**Target Tech Stack:** Flutter 3.x (Dart), Supabase (PostgreSQL 18, Auth, Realtime, Storage), Firebase Cloud Messaging (FCM), Riverpod (State Management), GoRouter (Navigation).  
**Platform Scope:** Cross-Platform Mobile App (Android/iOS) + Web Admin Dashboard.  

---

## 1. Executive Summary & Architecture Overview
**Vakeel Saab** is a secure, private, and democratic community platform exclusively for legal professionals enrolled under the Advocates Act, 1961. The architecture utilizes a zero-cost serverless Backend-as-a-Service (BaaS) model via Supabase.

```
+-----------------------------------------------------------------------------------+
|                            FLUTTER (DART) CLIENT LAYER                            |
|  Android App  |  iOS App  |  Web Admin Dashboard  |  Responsive GoRouter Routing  |
+-----------------------------------------------------------------------------------+
                                          |
                                 (HTTPS REST & WSS)
                                          v
+-----------------------------------------------------------------------------------+
|                                 SUPABASE PLATFORM                                 |
|  +-----------------------------------------------------------------------------+  |
|  | PostgreSQL 18 Relational DB (Schema, Custom Enums, Unique Constraints)      |  |
|  +-----------------------------------------------------------------------------+  |
|  | Row-Level Security (RLS) Engine with Security Definer Helper Functions      |  |
|  +-----------------------------------------------------------------------------+  |
|  | Supabase Auth (Phone OTP via Firebase / MSG91)                              |  |
|  +-----------------------------------------------------------------------------+  |
|  | Supabase Storage Buckets (`avatars`, `bar_ids`, `post_attachments`)           |  |
|  +-----------------------------------------------------------------------------+  |
|  | Realtime Subscriptions (Wall feeds, Notifications, Elections)               |  |
|  +-----------------------------------------------------------------------------+  |
|  | Edge Functions (Deno / TypeScript Webhooks for FCM Push Dispatch)           |  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Complete PostgreSQL Database Schema & RLS Policies

Execute the following DDL script in your Supabase SQL Editor:

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 1. ENUM DEFINITIONS
CREATE TYPE user_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE request_status AS ENUM ('pending', 'accepted', 'rejected');
CREATE TYPE report_target_type AS ENUM ('post', 'comment', 'user');
CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'dismissed', 'action_taken');
CREATE TYPE election_status AS ENUM ('upcoming', 'nominations_open', 'voting_open', 'closed');

-- 2. USERS TABLE
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    state_bar_association VARCHAR(150) NOT NULL,
    enrollment_number VARCHAR(100) NOT NULL UNIQUE,
    place_of_practice VARCHAR(150) NOT NULL,
    courts_of_practice TEXT[] DEFAULT '{}',
    bio TEXT,
    avatar_url TEXT,
    status user_status DEFAULT 'pending',
    is_verified BOOLEAN DEFAULT FALSE, -- Tier 2 Verified Advocate Flag
    bar_id_card_url TEXT,
    is_admin BOOLEAN DEFAULT FALSE,
    phone_visibility BOOLEAN DEFAULT FALSE,
    terms_accepted BOOLEAN DEFAULT FALSE,
    terms_accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_trgm_search ON public.users USING gin (
    (first_name || ' ' || last_name || ' ' || enrollment_number || ' ' || place_of_practice) gin_trgm_ops
);

-- 3. COMMUNITY WALL POSTS
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_url TEXT,
    is_election_poll BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);

-- 4. LIKES TABLE
CREATE TABLE public.likes (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

-- 5. COMMENTS TABLE
CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_comments_post_id ON public.comments(post_id);

-- 6. CONTACT ACCESS REQUESTS
CREATE TABLE public.contact_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status request_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_contact_request UNIQUE (requester_id, target_user_id)
);

-- 7. REPORT & MODERATION SYSTEM
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    target_type report_target_type NOT NULL,
    target_id UUID NOT NULL,
    reason TEXT NOT NULL,
    status report_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. ANNOUNCEMENTS / BROADCAST CHANNEL
CREATE TABLE public.broadcasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    attachment_url TEXT,
    priority VARCHAR(20) DEFAULT 'normal', -- 'normal', 'urgent', 'strike_notice'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. ELECTIONS & VOTING POLLS
CREATE TABLE public.elections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status election_status DEFAULT 'upcoming',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.nominations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    candidate_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    position_name VARCHAR(100) NOT NULL,
    manifesto TEXT,
    status request_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_candidate_position UNIQUE (election_id, candidate_id, position_name)
);

CREATE TABLE public.votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    position_name VARCHAR(100) NOT NULL,
    voter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    candidate_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_vote_per_position UNIQUE (election_id, position_name, voter_id)
);

-- 10. NOTIFICATIONS TABLE
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. ROW LEVEL SECURITY (RLS) & HELPER FUNCTIONS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.elections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nominations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_approved_user(auth_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE auth_user_id = auth_id AND status = 'approved'
  );
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_verified_tier2_advocate(auth_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE auth_user_id = auth_id AND status = 'approved' AND is_verified = TRUE
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Post RLS
CREATE POLICY "Approved users can read posts" ON public.posts FOR SELECT USING (public.is_approved_user(auth.uid()));
CREATE POLICY "Approved users can create posts" ON public.posts FOR INSERT WITH CHECK (public.is_approved_user(auth.uid()));

-- Vote RLS (Strict Tier 2 Enforcement)
CREATE POLICY "Tier 2 Advocates can cast vote" ON public.votes FOR INSERT WITH CHECK (public.is_verified_tier2_advocate(auth.uid()));
```

---

## 3. Modular Feature Requirements

### Module A: Authentication & Joining Form
*   **Phone OTP:** Supabase phone authentication (`signInWithOtp`).
*   **Joining Form:** Captures Name, DOB (>21 years), State Bar Council dropdown, Enrollment Number (unique), Place of Practice, Courts multi-select chips, Bar ID Card upload (front/back), and mandatory **Terms of Service & BCI Ethics** checkbox.
*   **Dual-Tier Verification:**
    *   *Tier 1 (Approved Member):* Basic app access.
    *   *Tier 2 (Verified Advocate):* Admin verified via Bar ID image review. Unlocks gold/blue badge and election voting rights.

### Module B: Community Wall & Social Interactions
*   Paginated feed sorted descending by creation time.
*   Optimistic UI updates for likes and comments.
*   Overflow 3-dot menu on posts and comments enabling the **Report & Moderation System** (`reports` table).

### Module C: Directory & Phone Privacy
*   Debounced global search (`pg_trgm`) by name, enrollment number, or practice city.
*   Masked phone numbers (`+91 XXXXX XXXXX`) by default.
*   `contact_requests` workflow where users request access and target advocates accept/reject to reveal contact details.

### Module D: Democratic Elections & Voting Polls
*   Lifecycle: `upcoming` -> `nominations_open` -> `voting_open` -> `closed`.
*   Tier 2 advocates submit nominations and cast secure anonymous votes.
*   Database unique constraint (`unique_vote_per_position`) blocks double voting at the SQL level.

### Module E: Admin Web Dashboard
*   Responsive master-detail split-pane layout for web browsers.
*   **Pending Joins Queue:** Side-by-side inspection of advocate details and zoomable Bar ID card image preview with 1-click approval or rejection.
*   **Moderation Hub:** Review flagged items and remove violating content.
*   **Broadcasts Center:** Push official announcements and court strike notices with priority flags.

---

## 4. UI/UX Design System & Theming

*   **Color Palette:**
    *   Primary Judicial Navy: `#0A192F`
    *   Secondary Brass Gold: `#D4AF37`
    *   Neutral Background: `#F8FAFC`
    *   Success Green: `#10B981` | Warning Amber: `#F59E0B` | Danger Rose: `#EF4444`
*   **Typography:** Google Fonts `Plus Jakarta Sans` across all weights.
*   **Feedback System:** Centralized `UIFeedback` utility for floating snackbars (Success, Error, Warning).

---

## 5. Suggested Flutter Folder Structure
```
vakeel_saab_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/        # Theme colors, asset paths, Bar Councils list
│   │   ├── router/           # GoRouter route map (Mobile + Web paths)
│   │   ├── services/         # Supabase client wrapper & FCM handlers
│   │   └── utils/            # Validators, UIFeedback utility
│   ├── features/
│   │   ├── auth/             # OTP & Joining Form Screen
│   │   ├── wall/             # Feed Screen, Post Card, Comments, Report Sheet
│   │   ├── directory/        # Search, Profile View, Contact Requests
│   │   ├── elections/        # Nominations & Voting Poll Card
│   │   ├── broadcasts/       # Announcements Channel Tab
│   │   ├── profile/          # Edit Profile & Bar ID Upload
│   │   └── admin/            # Web Dashboard (Pending Joins, Moderation, Elections)
│   └── shared/
│       └── widgets/          # Verified Badge Chip, Custom Buttons
```

---
*Give this master specification to your coding agent to initiate full-stack development of the Vakeel Saab App.*