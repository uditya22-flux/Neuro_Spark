-- Engine 2.a + 2.b production persistence.
-- All task content is bounded, versioned, and scoped to a guardian-owned child.

create table public.vertical_task_bank (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  session_id uuid,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  layer_number int not null check (layer_number between 1 and 10),
  source_type text not null check (source_type in ('curated', 'predicted', 'created')),
  difficulty_tier text not null check (difficulty_tier in ('baseline', 'progressive', 'advanced')),
  item_payload jsonb not null,
  content_hash text not null,
  rule_version text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index vertical_task_bank_lookup_idx
  on public.vertical_task_bank(child_id, session_id, vertical_id, layer_number, active);
create unique index vertical_task_bank_session_hash_idx
  on public.vertical_task_bank(session_id, vertical_id, layer_number, content_hash)
  where session_id is not null;

create table public.layer1_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  guardian_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'in_progress' check (status in ('in_progress', 'complete')),
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  expires_at timestamptz not null default (now() + interval '30 days')
);

alter table public.vertical_task_bank
  add constraint vertical_task_bank_session_child_fk
  foreign key (session_id) references public.layer1_sessions(id) on delete cascade;

create index layer1_sessions_child_idx on public.layer1_sessions(child_id, created_at desc);

create table public.sublayer_telemetry (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  task_id uuid not null references public.vertical_task_bank(id) on delete cascade,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  source_type text not null check (source_type in ('curated', 'predicted', 'created')),
  accuracy numeric not null check (accuracy between 0 and 1),
  latency_ms int not null check (latency_ms >= 0),
  recovery numeric not null check (recovery between 0 and 1),
  engagement numeric not null check (engagement between 0 and 1),
  speed numeric not null check (speed between 0 and 1),
  source_confidence numeric not null check (source_confidence between 0 and 1),
  isolation_score numeric not null check (isolation_score between 0 and 1),
  telemetry_reference text not null,
  expires_at timestamptz not null default (now() + interval '90 days'),
  created_at timestamptz not null default now()
);

create index sublayer_telemetry_session_idx on public.sublayer_telemetry(session_id, vertical_id, created_at);

create table public.stage2_handoffs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  isolation_score numeric not null check (isolation_score between 0 and 1),
  accuracy numeric not null check (accuracy between 0 and 1),
  recovery numeric not null check (recovery between 0 and 1),
  engagement numeric not null check (engagement between 0 and 1),
  speed numeric not null check (speed between 0 and 1),
  telemetry_reference text not null,
  created_at timestamptz not null default now(),
  unique(session_id, vertical_id)
);

create table public.layer_progression_state (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  current_layer int not null check (current_layer between 2 and 10),
  path_type text not null check (path_type in ('accelerated', 'standard', 'supported')),
  path_layers jsonb not null,
  completed_layers jsonb not null default '[]'::jsonb,
  status text not null default 'in_progress' check (status in ('in_progress', 'layer_complete', 'funnel_complete')),
  support_level int not null default 0 check (support_level between 0 and 5),
  current_task_id uuid references public.vertical_task_bank(id) on delete set null,
  updated_at timestamptz not null default now(),
  unique(session_id, vertical_id)
);

create index layer_progression_child_idx on public.layer_progression_state(child_id, session_id);

create table public.layer_task_execution (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.vertical_task_bank(id) on delete cascade,
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  layer_number int not null check (layer_number between 2 and 10),
  source_type text not null check (source_type in ('curated', 'predicted', 'created')),
  modality text not null check (modality in ('visual', 'audio', 'animated', 'interactive')),
  support_level int not null check (support_level between 0 and 5),
  accuracy numeric not null check (accuracy between 0 and 1),
  latency_ms int not null check (latency_ms >= 0),
  recovery numeric not null check (recovery between 0 and 1),
  engagement numeric not null check (engagement between 0 and 1),
  retry_count int not null default 0 check (retry_count >= 0),
  hint_usage int not null default 0 check (hint_usage >= 0),
  answer_changes int not null default 0 check (answer_changes >= 0),
  skipped boolean not null default false,
  metric_values jsonb not null default '{}'::jsonb,
  response jsonb not null default '{}'::jsonb,
  expires_at timestamptz not null default (now() + interval '90 days'),
  created_at timestamptz not null default now()
);

create index layer_task_execution_session_idx on public.layer_task_execution(session_id, vertical_id, layer_number, created_at);

create table public.support_ladder_log (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  task_id uuid not null references public.vertical_task_bank(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  support_level int not null check (support_level between 0 and 5),
  trigger_reason text not null,
  outcome text not null check (outcome in ('resolved', 'escalated_further', 'de_escalated', 'abandoned')),
  created_at timestamptz not null default now()
);

create table public.consistency_window (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  window_index int not null check (window_index >= 0),
  accuracy_stability_score numeric not null check (accuracy_stability_score between 0 and 1),
  fatigue_score numeric not null check (fatigue_score between 0 and 1),
  created_at timestamptz not null default now(),
  unique(session_id, vertical_id, window_index)
);

create table public.deepening_profiles (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  vertical_id text not null check (vertical_id in ('calendar_genius', 'constellation_mapper')),
  profile jsonb not null,
  telemetry_reference text not null,
  created_at timestamptz not null default now(),
  unique(session_id, vertical_id)
);

-- RLS is guardian-scoped. Edge Functions use service-role writes only after
-- ownership checks; child payloads never read these tables directly.
alter table public.layer1_sessions enable row level security;
alter table public.vertical_task_bank enable row level security;
alter table public.sublayer_telemetry enable row level security;
alter table public.stage2_handoffs enable row level security;
alter table public.layer_progression_state enable row level security;
alter table public.layer_task_execution enable row level security;
alter table public.support_ladder_log enable row level security;
alter table public.consistency_window enable row level security;
alter table public.deepening_profiles enable row level security;

create policy layer1_sessions_guardian on public.layer1_sessions for select using (guardian_id = auth.uid());
create policy task_bank_guardian on public.vertical_task_bank for select using (public.child_owned(child_id));
create policy sublayer_guardian on public.sublayer_telemetry for select using (public.child_owned(child_id));
create policy handoff_guardian on public.stage2_handoffs for select using (public.child_owned(child_id));
create policy progression_guardian on public.layer_progression_state for select using (public.child_owned(child_id));
create policy execution_guardian on public.layer_task_execution for select using (public.child_owned(child_id));
create policy support_guardian on public.support_ladder_log for select using (public.child_owned(child_id));
create policy consistency_guardian on public.consistency_window for select using (public.child_owned(child_id));
create policy profiles_guardian on public.deepening_profiles for select using (public.child_owned(child_id));

create index stage2_handoffs_child_idx on public.stage2_handoffs(child_id, vertical_id, created_at desc);
create index deepening_profiles_child_idx on public.deepening_profiles(child_id, vertical_id, created_at desc);
