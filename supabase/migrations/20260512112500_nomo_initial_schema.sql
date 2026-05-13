-- Nomo initial Supabase schema.
-- This migration mirrors the schema applied to project pwifgddolctqghygwxwj on 2026-05-12.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  user_id text not null unique,
  display_name text not null,
  character_key text not null default 'icon_smile',
  avatar_url text,
  is_plus boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_user_id_format check (user_id ~ '^[a-zA-Z0-9_]{3,24}$'),
  constraint profiles_display_name_length check (char_length(display_name) between 1 and 40)
);

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.profiles(id) on delete cascade,
  to_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friend_requests_no_self check (from_user_id <> to_user_id)
);

create unique index if not exists friend_requests_unique_pending
  on public.friend_requests (least(from_user_id, to_user_id), greatest(from_user_id, to_user_id))
  where status = 'pending';

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references public.profiles(id) on delete cascade,
  user_b_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint friendships_no_self check (user_a_id <> user_b_id),
  constraint friendships_ordered check (user_a_id < user_b_id),
  unique (user_a_id, user_b_id)
);

create table if not exists public.daily_statuses (
  user_id uuid not null references public.profiles(id) on delete cascade,
  status_date date not null default current_date,
  status text not null check (status in ('unselected', 'want_drink', 'busy')) default 'unselected',
  updated_at timestamptz not null default now(),
  primary key (user_id, status_date)
);

create table if not exists public.drink_logs (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  drank_at timestamptz not null default now(),
  place_name text,
  place_lat double precision,
  place_lng double precision,
  memo text,
  photo_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.drink_log_friends (
  drink_log_id uuid not null references public.drink_logs(id) on delete cascade,
  friend_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (drink_log_id, friend_user_id)
);

-- Functions, triggers, policies, and storage bucket are applied in the live project.
-- Keep future changes in new migrations once Supabase CLI is installed/linked locally.
