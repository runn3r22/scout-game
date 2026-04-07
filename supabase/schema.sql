-- =====================================================================
-- Scout Game — GP test (S0) schema
-- =====================================================================
-- Apply: paste into Supabase SQL Editor → Run.
-- Idempotent: safe to re-run. Drops nothing.
--
-- 3 tables for the GP test:
--   scout_submissions  — one row per submission attempt (the main log)
--   projects           — one row per unique CA (dedup + accumulated notes)
--   scout_points       — one row per scout (flat point counter)
--
-- Cut from S0 (see docs/future-ideas.md):
--   tier multipliers, daily caps, weekly pool, agent_memory,
--   token_performance, scout_reputation, retroactive upgrade tables
-- =====================================================================

-- Enable uuid generation
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- scout_submissions: every submission attempt the agent processes
-- ---------------------------------------------------------------------
create table if not exists public.scout_submissions (
  id                  uuid primary key default gen_random_uuid(),

  -- when / who / where
  submitted_at        timestamptz not null default now(),
  scout_id            text not null,
  scout_handle        text,
  source_platform     text not null default 'telegram',  -- 'telegram' for S0, 'x' for S1+
  source_chat_id      text,
  source_message_id   text,
  source_message      text,                              -- raw submission text

  -- what was submitted
  ca                  text,                              -- nullable: NO_CA reject
  ticker              text,
  factory             text,                              -- clanker/doppler/flaunch/virtuals/unverified

  -- pipeline state (compaction protection)
  status              text not null default 'pending',   -- pending | evaluating | done | failed
  reject_code         text,                              -- NO_CA / TOO_SHORT / NOT_TRADING / OUT_OF_RANGE / TOO_OLD / NO_LP / DUPLICATE / THESIS_WEAK / etc.

  -- snapshot (Step 3)
  snapshot_json       jsonb,                             -- full GeckoTerminal blob: fdv, liq, vol, holders, age...

  -- scoring (Steps 2 / 5 / 6)
  thesis_score        numeric,                           -- 0-10
  token_score         numeric,                           -- 0-10
  final_score         numeric,                           -- 0-10
  modifiers_json      jsonb,                             -- list of {reason, delta} that adjusted token_score → final_score

  -- decision
  action              text,                              -- REJECT | DB_SAVE | SIGNAL | TRADE
  reasoning           text,                              -- human-readable explanation, for review
  points_awarded      integer not null default 0,        -- flat: 0 / 1 / 5 / 20

  -- timestamps
  evaluated_at        timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index if not exists idx_submissions_scout       on public.scout_submissions (scout_id);
create index if not exists idx_submissions_ca          on public.scout_submissions (ca);
create index if not exists idx_submissions_submitted  on public.scout_submissions (submitted_at desc);
create index if not exists idx_submissions_status      on public.scout_submissions (status);
create index if not exists idx_submissions_action      on public.scout_submissions (action);

-- ---------------------------------------------------------------------
-- projects: one row per unique CA — dedup + accumulated knowledge
-- ---------------------------------------------------------------------
create table if not exists public.projects (
  ca                  text primary key,
  ticker              text,
  factory             text,

  first_seen_at       timestamptz not null default now(),
  first_scout_id      text,
  first_submission_id uuid references public.scout_submissions(id) on delete set null,

  last_seen_at        timestamptz not null default now(),
  submission_count    integer not null default 0,

  latest_action       text,                              -- last final action for this CA
  latest_score        numeric,                           -- last final_score
  latest_evaluated_at timestamptz,

  notes               text,                              -- free-form intel summary, agent appends here on DB_SAVE+
  notes_updated_at    timestamptz,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index if not exists idx_projects_factory on public.projects (factory);
create index if not exists idx_projects_action  on public.projects (latest_action);

-- ---------------------------------------------------------------------
-- scout_points: one row per scout — flat counter for GP test
-- ---------------------------------------------------------------------
create table if not exists public.scout_points (
  scout_id            text primary key,
  scout_handle        text,

  total_points        integer not null default 0,
  submission_count    integer not null default 0,
  accepted_count      integer not null default 0,       -- non-REJECT count
  signal_count        integer not null default 0,       -- SIGNAL or TRADE
  trade_count         integer not null default 0,       -- TRADE only

  first_submission_at timestamptz,
  last_submission_at  timestamptz,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_submissions_updated_at on public.scout_submissions;
create trigger trg_submissions_updated_at
  before update on public.scout_submissions
  for each row execute function public.set_updated_at();

drop trigger if exists trg_projects_updated_at on public.projects;
create trigger trg_projects_updated_at
  before update on public.projects
  for each row execute function public.set_updated_at();

drop trigger if exists trg_scout_points_updated_at on public.scout_points;
create trigger trg_scout_points_updated_at
  before update on public.scout_points
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- RLS: lock everything down. service_role bypasses RLS automatically,
-- so the agent (using SUPABASE_SERVICE_KEY) keeps full access.
-- The publishable/anon key cannot read or write anything.
-- ---------------------------------------------------------------------
alter table public.scout_submissions enable row level security;
alter table public.projects          enable row level security;
alter table public.scout_points      enable row level security;

-- No policies created → only service_role can access. Intentional.

-- ---------------------------------------------------------------------
-- Done.
-- ---------------------------------------------------------------------
