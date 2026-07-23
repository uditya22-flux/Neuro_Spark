-- Builder-only synthetic cloud demo for Engine 2.
--
-- This schema deliberately has no child, guardian, profile, intake-text, or
-- production telemetry foreign keys.  Its only owner is an anonymous Supabase
-- Auth user and every row is short lived.  Clients have no direct table
-- access; the Edge Function validates the small, allowlisted payload before
-- writing through the service role.

create table if not exists public.synthetic_engine2_demo_sessions (
  id uuid primary key default gen_random_uuid(),
  anonymous_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'in_progress'
    check (status in ('in_progress', 'complete', 'expired')),
  current_layer smallint not null default 1 check (current_layer between 1 and 10),
  active_sectors jsonb not null default '[]'::jsonb
    check (jsonb_typeof(active_sectors) = 'array'),
  pending_sectors jsonb not null default '[]'::jsonb
    check (jsonb_typeof(pending_sectors) = 'array'),
  visual_preferences jsonb not null default '{}'::jsonb
    check (jsonb_typeof(visual_preferences) = 'object'),
  final_sector text,
  final_sandbox text check (final_sandbox in ('calendar', 'constellation', 'exploring')),
  expires_at timestamptz not null default (timezone('utc', now()) + interval '3 hours'),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check ((status <> 'complete') or final_sector is not null),
  check (expires_at <= created_at + interval '24 hours')
);

create unique index if not exists synthetic_engine2_one_live_session_per_user_idx
  on public.synthetic_engine2_demo_sessions (anonymous_user_id)
  where status = 'in_progress';
create index if not exists synthetic_engine2_session_expiry_idx
  on public.synthetic_engine2_demo_sessions (expires_at);

create table if not exists public.synthetic_engine2_demo_tasks (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.synthetic_engine2_demo_sessions(id) on delete cascade,
  anonymous_user_id uuid not null references auth.users(id) on delete cascade,
  layer smallint not null check (layer between 1 and 10),
  sequence_index smallint not null check (sequence_index between 1 and 30),
  sector text not null check (sector in (
    'ordering', 'durationMatching', 'beforeAfter', 'routeFollowing',
    'rotationMatching', 'distanceJudgement', 'repeatingPattern',
    'patternCompletion', 'visualGrouping', 'attributeSorting',
    'quantityMatching', 'oneToOneMatching', 'shapeMatching',
    'objectPermanence', 'visualSearch', 'detailComparison', 'workingRecall',
    'instructionFollowing', 'causeAndEffect', 'toolUse', 'dragPrecision',
    'tapPrecision', 'bilateralCoordination', 'turnTaking', 'rhythmMatching',
    'soundVisualMatching', 'perspectiveTaking', 'flexibleSwitching',
    'constructionPlanning', 'errorRepair'
  )),
  -- A layer is generated in one constrained OpenAI request. Only one row is
  -- issued to Flutter at a time; the rest remain server-side and queued.
  status text not null default 'queued' check (status in ('queued', 'issued', 'completed')),
  source text not null check (source in ('openai', 'fallback')),
  task_payload jsonb not null check (jsonb_typeof(task_payload) = 'object'),
  issued_at timestamptz not null default timezone('utc', now()),
  completed_at timestamptz,
  unique(session_id, layer, sector),
  unique(session_id, layer, sequence_index)
);

create index if not exists synthetic_engine2_task_active_idx
  on public.synthetic_engine2_demo_tasks (session_id, status, issued_at);
create unique index if not exists synthetic_engine2_one_issued_task_per_session_idx
  on public.synthetic_engine2_demo_tasks (session_id)
  where status = 'issued';

-- Each anonymous builder selection is retained separately from the final
-- per-task aggregate. This is fictional demo telemetry only; no response text
-- or personal identifier is accepted or stored.
create table if not exists public.synthetic_engine2_demo_attempts (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.synthetic_engine2_demo_sessions(id) on delete cascade,
  task_id uuid not null references public.synthetic_engine2_demo_tasks(id) on delete cascade,
  anonymous_user_id uuid not null references auth.users(id) on delete cascade,
  layer smallint not null check (layer between 1 and 10),
  sector text not null check (sector in (
    'ordering', 'durationMatching', 'beforeAfter', 'routeFollowing',
    'rotationMatching', 'distanceJudgement', 'repeatingPattern',
    'patternCompletion', 'visualGrouping', 'attributeSorting',
    'quantityMatching', 'oneToOneMatching', 'shapeMatching',
    'objectPermanence', 'visualSearch', 'detailComparison', 'workingRecall',
    'instructionFollowing', 'causeAndEffect', 'toolUse', 'dragPrecision',
    'tapPrecision', 'bilateralCoordination', 'turnTaking', 'rhythmMatching',
    'soundVisualMatching', 'perspectiveTaking', 'flexibleSwitching',
    'constructionPlanning', 'errorRepair'
  )),
  option_id text not null check (option_id in ('option_a', 'option_b', 'option_c', 'option_d', 'option_e')),
  correct boolean not null,
  latency_ms integer not null check (latency_ms between 0 and 600000),
  misclicks integer not null check (misclicks between 0 and 50),
  recovered_errors integer not null check (recovered_errors between 0 and 50),
  interactions integer not null check (interactions between 1 and 100),
  support_level smallint not null check (support_level between 0 and 3),
  created_at timestamptz not null default timezone('utc', now()),
  check (recovered_errors <= misclicks)
);

create index if not exists synthetic_engine2_attempt_task_idx
  on public.synthetic_engine2_demo_attempts (task_id, created_at);

create table if not exists public.synthetic_engine2_demo_events (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.synthetic_engine2_demo_sessions(id) on delete cascade,
  task_id uuid not null unique references public.synthetic_engine2_demo_tasks(id) on delete cascade,
  anonymous_user_id uuid not null references auth.users(id) on delete cascade,
  layer smallint not null check (layer between 1 and 10),
  sector text not null check (sector in (
    'ordering', 'durationMatching', 'beforeAfter', 'routeFollowing',
    'rotationMatching', 'distanceJudgement', 'repeatingPattern',
    'patternCompletion', 'visualGrouping', 'attributeSorting',
    'quantityMatching', 'oneToOneMatching', 'shapeMatching',
    'objectPermanence', 'visualSearch', 'detailComparison', 'workingRecall',
    'instructionFollowing', 'causeAndEffect', 'toolUse', 'dragPrecision',
    'tapPrecision', 'bilateralCoordination', 'turnTaking', 'rhythmMatching',
    'soundVisualMatching', 'perspectiveTaking', 'flexibleSwitching',
    'constructionPlanning', 'errorRepair'
  )),
  correct boolean not null,
  latency_ms integer not null check (latency_ms between 0 and 600000),
  misclicks integer not null check (misclicks between 0 and 50),
  recovered_errors integer not null check (recovered_errors between 0 and 50),
  interactions integer not null check (interactions between 1 and 100),
  support_level smallint not null check (support_level between 0 and 3),
  accuracy numeric(6,5) not null check (accuracy between 0 and 1),
  recovery numeric(6,5) not null check (recovery between 0 and 1),
  engagement numeric(6,5) not null check (engagement between 0 and 1),
  speed numeric(6,5) not null check (speed between 0 and 1),
  isolation_score numeric(6,5) not null check (isolation_score between 0 and 1),
  created_at timestamptz not null default timezone('utc', now()),
  check (recovered_errors <= misclicks)
);

create index if not exists synthetic_engine2_event_layer_idx
  on public.synthetic_engine2_demo_events (session_id, layer, sector);

-- A rolling quota makes the anonymous, server-side OpenAI path bounded while
-- still allowing a complete 30 -> 1 showcase (76 task requests) in one hour.
create table if not exists public.synthetic_engine2_demo_quota (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null default timezone('utc', now()),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.consume_synthetic_engine2_demo_quota(
  p_user_id uuid,
  p_limit integer
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_count integer;
begin
  if p_user_id is null or p_limit < 76 or p_limit > 200 then
    return false;
  end if;

  insert into public.synthetic_engine2_demo_quota (
    user_id,
    window_started_at,
    request_count,
    updated_at
  )
  values (p_user_id, timezone('utc', now()), 1, timezone('utc', now()))
  on conflict (user_id) do update
  set
    window_started_at = case
      when synthetic_engine2_demo_quota.window_started_at <= timezone('utc', now()) - interval '1 hour'
        then timezone('utc', now())
      else synthetic_engine2_demo_quota.window_started_at
    end,
    request_count = case
      when synthetic_engine2_demo_quota.window_started_at <= timezone('utc', now()) - interval '1 hour'
        then 1
      else synthetic_engine2_demo_quota.request_count + 1
    end,
    updated_at = timezone('utc', now())
  returning request_count into current_count;

  return current_count <= p_limit;
end;
$$;

-- This can be called from a scheduled job or deployment housekeeping.  The
-- cascade removes tasks and fictional telemetry with their short-lived session.
create or replace function public.purge_expired_synthetic_engine2_demo_sessions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer;
begin
  delete from public.synthetic_engine2_demo_sessions
  where expires_at <= timezone('utc', now());
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

alter table public.synthetic_engine2_demo_sessions enable row level security;
alter table public.synthetic_engine2_demo_tasks enable row level security;
alter table public.synthetic_engine2_demo_attempts enable row level security;
alter table public.synthetic_engine2_demo_events enable row level security;
alter table public.synthetic_engine2_demo_quota enable row level security;

revoke all on table public.synthetic_engine2_demo_sessions from anon, authenticated;
revoke all on table public.synthetic_engine2_demo_tasks from anon, authenticated;
revoke all on table public.synthetic_engine2_demo_attempts from anon, authenticated;
revoke all on table public.synthetic_engine2_demo_events from anon, authenticated;
revoke all on table public.synthetic_engine2_demo_quota from anon, authenticated;
revoke all on function public.consume_synthetic_engine2_demo_quota(uuid, integer) from public;
revoke all on function public.purge_expired_synthetic_engine2_demo_sessions() from public;
grant execute on function public.consume_synthetic_engine2_demo_quota(uuid, integer) to service_role;
grant execute on function public.purge_expired_synthetic_engine2_demo_sessions() to service_role;
