-- ============================================================================
-- Legal Unity Network: Supabase Schema, Hardened RLS Policies & Optimized Indexes
-- Project Ref: lpuxvdwuwyybzwubfcfz
-- ============================================================================

-- 1. Create non-exposed private schema for SECURITY DEFINER helpers and triggers
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated, service_role;

-- 2. Core Tables (lowercase snake_case identifiers per Postgres best practices)

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  phone text,
  first_name text,
  last_name text,
  name text not null default '',
  date_of_birth date,
  gender text check (gender is null or gender in ('Male', 'Female', 'Other')),
  state_bar_association text,
  enrollment_number text,
  photo_url text,
  rejection_reason text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'banned')),
  role text not null default 'member'
    check (role in ('member', 'admin', 'founding_admin')),
  bar_admissions jsonb not null default '[]'::jsonb,
  law_school text,
  practice_areas text[] not null default '{}'::text[],
  firm_organization text,
  years_of_experience integer check (years_of_experience is null or years_of_experience >= 0),
  city text,
  state text,
  bio text,
  availability_status text
    check (availability_status is null or availability_status in (
      'accepting_referrals',
      'not_taking_clients',
      'available_for_consultation'
    )),
  achievements text,
  cles text,
  publications text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  participants uuid[] not null check (cardinality(participants) >= 2),
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 5000),
  attachment_url text,
  attachment_type text check (attachment_type is null or attachment_type in ('image', 'document', 'link')),
  created_at timestamptz not null default now()
);

create table if not exists public.group_chat_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 5000),
  attachment_url text,
  attachment_type text check (attachment_type is null or attachment_type in ('image', 'document', 'link')),
  is_pinned boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.broadcasts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  content text not null check (char_length(content) between 1 and 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.elections (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  nomination_open boolean not null default false,
  voting_open boolean not null default false,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.nominations (
  id uuid primary key default gen_random_uuid(),
  election_id uuid not null references public.elections(id) on delete cascade,
  nominee_id uuid not null references public.profiles(id) on delete cascade,
  nominated_by uuid not null references public.profiles(id) on delete cascade,
  statement text,
  created_at timestamptz not null default now(),
  unique (election_id, nominee_id)
);

create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  election_id uuid not null references public.elections(id) on delete cascade,
  voter_id uuid not null references public.profiles(id) on delete cascade,
  nominee_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (election_id, voter_id)
);

create table if not exists public.admin_actions (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.profiles(id) on delete restrict,
  target_user_id uuid references public.profiles(id) on delete set null,
  action_type text not null,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- 3. Private Helper Functions for Non-Recursive, Cached RLS Checks
-- ============================================================================

create or replace function private.is_approved_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and status = 'approved'
  );
$$;

revoke execute on function private.is_approved_member() from public, anon;
grant execute on function private.is_approved_member() to authenticated;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and status = 'approved'
      and role in ('admin', 'founding_admin')
  );
$$;

revoke execute on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated;

create or replace function private.is_conversation_participant(conv_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.conversations
    where id = $1
      and (select auth.uid()) = any(participants)
  );
$$;

revoke execute on function private.is_conversation_participant(uuid) from public, anon;
grant execute on function private.is_conversation_participant(uuid) to authenticated;

-- Trigger to auto-create a pending member profile when a new auth.users row is created
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, phone, name, status, role)
  values (
    new.id,
    coalesce(new.email, ''),
    new.phone,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    'pending',
    'member'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke execute on function private.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- Trigger to enforce that non-admins cannot alter status or role on public.profiles
create or replace function private.prevent_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (new.status is distinct from old.status or new.role is distinct from old.role) then
    if not (select private.is_admin()) and current_user not in ('postgres', 'service_role') then
      raise exception 'Only admins can modify user status or role';
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function private.prevent_privilege_escalation() from public, anon, authenticated;

drop trigger if exists trg_profiles_prevent_privilege_escalation on public.profiles;
create trigger trg_profiles_prevent_privilege_escalation
  before update on public.profiles
  for each row execute function private.prevent_privilege_escalation();

-- ============================================================================
-- 4. Enable Row-Level Security (RLS) on All Exposed Tables
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.group_chat_messages enable row level security;
alter table public.broadcasts enable row level security;
alter table public.elections enable row level security;
alter table public.nominations enable row level security;
alter table public.votes enable row level security;
alter table public.admin_actions enable row level security;
alter table public.notifications enable row level security;

-- ============================================================================
-- 5. RLS Policies (Using `TO authenticated` and `(select ...)` InitPlan caching)
-- ============================================================================

-- PROFILES
create policy "profiles_select_policy" on public.profiles
  for select
  to authenticated
  using (
    id = (select auth.uid())
    or (status = 'approved' and (select private.is_approved_member()))
    or (select private.is_admin())
  );

create policy "profiles_insert_self_pending" on public.profiles
  for insert
  to authenticated
  with check (
    id = (select auth.uid())
    and status = 'pending'
    and role = 'member'
  );

create policy "profiles_update_self_or_admin" on public.profiles
  for update
  to authenticated
  using (
    id = (select auth.uid())
    or (select private.is_admin())
  )
  with check (
    id = (select auth.uid())
    or (select private.is_admin())
  );

create policy "profiles_delete_admin_only" on public.profiles
  for delete
  to authenticated
  using ((select private.is_admin()));

-- CONVERSATIONS
create policy "conversations_select_participant" on public.conversations
  for select
  to authenticated
  using (
    (select private.is_approved_member())
    and (select auth.uid()) = any(participants)
  );

create policy "conversations_insert_participant" on public.conversations
  for insert
  to authenticated
  with check (
    (select private.is_approved_member())
    and (select auth.uid()) = any(participants)
  );

create policy "conversations_update_participant" on public.conversations
  for update
  to authenticated
  using (
    (select private.is_approved_member())
    and (select auth.uid()) = any(participants)
  )
  with check (
    (select private.is_approved_member())
    and (select auth.uid()) = any(participants)
  );

-- MESSAGES (1-1)
create policy "messages_select_participant" on public.messages
  for select
  to authenticated
  using (
    (select private.is_approved_member())
    and (select private.is_conversation_participant(conversation_id))
  );

create policy "messages_insert_sender" on public.messages
  for insert
  to authenticated
  with check (
    (select private.is_approved_member())
    and sender_id = (select auth.uid())
    and (select private.is_conversation_participant(conversation_id))
  );

create policy "messages_delete_sender" on public.messages
  for delete
  to authenticated
  using (sender_id = (select auth.uid()));

-- GROUP CHAT MESSAGES
create policy "group_chat_select_approved" on public.group_chat_messages
  for select
  to authenticated
  using ((select private.is_approved_member()));

create policy "group_chat_insert_approved" on public.group_chat_messages
  for insert
  to authenticated
  with check (
    (select private.is_approved_member())
    and sender_id = (select auth.uid())
  );

create policy "group_chat_update_admin_pin" on public.group_chat_messages
  for update
  to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

create policy "group_chat_delete_sender_or_admin" on public.group_chat_messages
  for delete
  to authenticated
  using (
    sender_id = (select auth.uid())
    or (select private.is_admin())
  );

-- BROADCASTS
create policy "broadcasts_select_approved" on public.broadcasts
  for select
  to authenticated
  using ((select private.is_approved_member()));

create policy "broadcasts_insert_admin" on public.broadcasts
  for insert
  to authenticated
  with check (
    (select private.is_admin())
    and author_id = (select auth.uid())
  );

create policy "broadcasts_update_admin" on public.broadcasts
  for update
  to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

create policy "broadcasts_delete_admin" on public.broadcasts
  for delete
  to authenticated
  using ((select private.is_admin()));

-- ELECTIONS
create policy "elections_select_approved" on public.elections
  for select
  to authenticated
  using ((select private.is_approved_member()));

create policy "elections_write_admin" on public.elections
  for all
  to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- NOMINATIONS
create policy "nominations_select_approved" on public.nominations
  for select
  to authenticated
  using ((select private.is_approved_member()));

create policy "nominations_insert_open" on public.nominations
  for insert
  to authenticated
  with check (
    (select private.is_approved_member())
    and nominated_by = (select auth.uid())
    and exists (
      select 1 from public.elections e
      where e.id = election_id and e.nomination_open = true
    )
  );

create policy "nominations_modify_admin" on public.nominations
  for all
  to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- VOTES
create policy "votes_select_own_or_admin" on public.votes
  for select
  to authenticated
  using (
    voter_id = (select auth.uid())
    or (select private.is_admin())
  );

create policy "votes_insert_open" on public.votes
  for insert
  to authenticated
  with check (
    (select private.is_approved_member())
    and voter_id = (select auth.uid())
    and exists (
      select 1 from public.elections e
      where e.id = election_id and e.voting_open = true
    )
  );

-- ADMIN ACTIONS (Immutable Audit Log)
create policy "admin_actions_select_admin" on public.admin_actions
  for select
  to authenticated
  using ((select private.is_admin()));

create policy "admin_actions_insert_admin" on public.admin_actions
  for insert
  to authenticated
  with check (
    (select private.is_admin())
    and admin_id = (select auth.uid())
  );

-- NOTIFICATIONS
create policy "notifications_select_own" on public.notifications
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "notifications_update_own" on public.notifications
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "notifications_delete_own" on public.notifications
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- ============================================================================
-- 6. Optimized Postgres Indexes (FKs, Partial Indexes, GIN, Composite Pagination)
-- ============================================================================

-- Profiles: Partial indexes for directory search & admin approval queue
create index if not exists profiles_approved_directory_idx
  on public.profiles (state, city, availability_status)
  where status = 'approved';

create index if not exists profiles_pending_applicants_idx
  on public.profiles (created_at asc)
  where status = 'pending';

create index if not exists profiles_admin_role_idx
  on public.profiles (id)
  where status = 'approved' and role in ('admin', 'founding_admin');

-- Profiles: GIN index for array containment queries on practice_areas (e.g. practice_areas @> ARRAY['Family Law'])
create index if not exists profiles_practice_areas_gin_idx
  on public.profiles using gin (practice_areas)
  where status = 'approved';

-- Conversations: GIN index for participant lookups + composite sort
create index if not exists conversations_participants_gin_idx
  on public.conversations using gin (participants);

create index if not exists conversations_last_message_at_idx
  on public.conversations (last_message_at desc);

-- Messages: Composite FK + pagination index and sender FK index
create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at desc);

create index if not exists messages_sender_id_idx
  on public.messages (sender_id);

-- Group Chat Messages: Pagination index, sender FK index, and partial index for pinned messages
create index if not exists group_chat_created_idx
  on public.group_chat_messages (created_at desc);

create index if not exists group_chat_sender_id_idx
  on public.group_chat_messages (sender_id);

create index if not exists group_chat_pinned_idx
  on public.group_chat_messages (created_at desc)
  where is_pinned = true;

-- Broadcasts: Author FK and feed ordering
create index if not exists broadcasts_author_id_idx
  on public.broadcasts (author_id);

create index if not exists broadcasts_created_idx
  on public.broadcasts (created_at desc);

-- Nominations & Votes: FK indexes
create index if not exists nominations_election_id_idx
  on public.nominations (election_id);

create index if not exists nominations_nominee_id_idx
  on public.nominations (nominee_id);

create index if not exists nominations_nominated_by_idx
  on public.nominations (nominated_by);

create index if not exists votes_election_nominee_idx
  on public.votes (election_id, nominee_id);

create index if not exists votes_voter_id_idx
  on public.votes (voter_id);

-- Admin Actions: FK indexes and chronological audit log index
create index if not exists admin_actions_admin_id_idx
  on public.admin_actions (admin_id, created_at desc);

create index if not exists admin_actions_target_user_id_idx
  on public.admin_actions (target_user_id);

-- Notifications: Composite FK + pagination index and partial index for unread badge count
create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

create index if not exists notifications_unread_user_idx
  on public.notifications (user_id, created_at desc)
  where is_read = false;

-- Community Wall Posts table, RLS policies, and indexes
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  author_name text not null,
  author_role text not null default 'Verified Member',
  content text not null,
  category text not null default 'General',
  liked_by jsonb not null default '[]'::jsonb,
  comments jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.posts enable row level security;

create policy "posts_select_all_authenticated"
  on public.posts for select
  to authenticated
  using (true);

create policy "posts_insert_approved"
  on public.posts for insert
  to authenticated
  with check ((select private.is_approved_member()) and author_id = (select auth.uid()));

create policy "posts_update_approved"
  on public.posts for update
  to authenticated
  using ((select private.is_approved_member()));

create policy "posts_delete_author_or_admin"
  on public.posts for delete
  to authenticated
  using (author_id = (select auth.uid()) or (select private.is_admin()));

create index if not exists posts_created_at_idx
  on public.posts (created_at desc);

create index if not exists posts_author_id_idx
  on public.posts (author_id);
