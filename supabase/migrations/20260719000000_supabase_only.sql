create extension if not exists pgcrypto;

create table if not exists public.consent_versions (
  id uuid primary key default gen_random_uuid(),
  version text not null unique,
  jurisdiction text not null default 'IN',
  document_url text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.parent_verifications (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null,
  method text not null check (method in ('email_otp', 'phone_otp', 'digilocker')),
  status text not null check (status in ('pending', 'verified', 'failed')),
  verified_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (guardian_id, method)
);

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null,
  preferred_name text not null,
  birth_year int not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.child_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  token_hash text not null unique,
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  revoke_reason text
);

create table if not exists public.discovery_intakes (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null,
  child_id uuid not null references public.children(id) on delete cascade,
  encrypted_raw_text text not null,
  redacted_text text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

create table if not exists public.sensory_configurations (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  config_version int not null,
  key text not null,
  proposed_value jsonb not null,
  status text not null default 'PENDING' check (status in ('PENDING', 'CONFIRMED', 'REJECTED')),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (child_id, config_version, key)
);

create table if not exists public.adult_exploratory_notes (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  track text not null,
  observations jsonb not null,
  evidence jsonb not null,
  disclaimer text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.child_experience (
  id uuid primary key default gen_random_uuid(),
  child_session_id uuid not null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.vertical_task_bank (
  id uuid primary key default gen_random_uuid(),
  track text not null,
  bank_key text not null,
  item jsonb not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (bank_key)
);

create table if not exists public.layer_progression_state (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  session_id uuid not null,
  layer int not null,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (child_id, session_id, layer)
);

create table if not exists public.layer_task_execution (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  session_id uuid not null,
  layer int not null,
  payload jsonb not null,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.support_ladder_log (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  session_id uuid not null,
  transition text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.consistency_window (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  window_key text not null,
  state jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.sandbox_session (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  seed text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create table if not exists public.sandbox_attempt (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sandbox_session(id) on delete cascade,
  user_id uuid not null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.difficulty_state (
  user_id uuid primary key,
  streak int not null default 0,
  difficulty jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.trigger_definitions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  rule jsonb not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.trigger_instances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  candidate_action jsonb not null,
  status text not null check (status in ('approved', 'rejected')),
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists public.trigger_dispatch_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  payload jsonb not null,
  channel text not null check (channel in ('realtime', 'fcm')),
  status text not null default 'pending' check (status in ('pending', 'sent', 'failed')),
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  fcm_token text not null unique,
  platform text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.purge_requests (
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null,
  child_id uuid,
  status text not null default 'REQUESTED' check (status in ('REQUESTED', 'PROCESSING', 'COMPLETED', 'FAILED')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  failure_reason text
);

create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  record_id uuid,
  action text not null,
  actor_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.write_audit_log()
returns trigger
language plpgsql
as $$
begin
  insert into public.audit_log (table_name, record_id, action, actor_id, payload)
  values (
    tg_table_name,
    coalesce((to_jsonb(new) ->> 'id')::uuid, (to_jsonb(old) ->> 'id')::uuid),
    tg_op,
    coalesce((to_jsonb(new) ->> 'guardian_id')::uuid, (to_jsonb(old) ->> 'guardian_id')::uuid, (to_jsonb(new) ->> 'user_id')::uuid, (to_jsonb(old) ->> 'user_id')::uuid),
    jsonb_build_object('new', to_jsonb(new), 'old', to_jsonb(old))
  );
  return coalesce(new, old);
end;
$$;

create or replace function public.guardian_owns_child(target_child_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.children c
    where c.id = target_child_id and c.guardian_id = auth.uid()
  );
$$;

alter table public.consent_versions enable row level security;
alter table public.parent_verifications enable row level security;
alter table public.children enable row level security;
alter table public.child_sessions enable row level security;
alter table public.discovery_intakes enable row level security;
alter table public.sensory_configurations enable row level security;
alter table public.adult_exploratory_notes enable row level security;
alter table public.child_experience enable row level security;
alter table public.vertical_task_bank enable row level security;
alter table public.layer_progression_state enable row level security;
alter table public.layer_task_execution enable row level security;
alter table public.support_ladder_log enable row level security;
alter table public.consistency_window enable row level security;
alter table public.sandbox_session enable row level security;
alter table public.sandbox_attempt enable row level security;
alter table public.difficulty_state enable row level security;
alter table public.trigger_definitions enable row level security;
alter table public.trigger_instances enable row level security;
alter table public.trigger_dispatch_queue enable row level security;
alter table public.device_tokens enable row level security;
alter table public.purge_requests enable row level security;
alter table public.audit_log enable row level security;

create policy consent_versions_read on public.consent_versions for select using (true);

create policy parent_verifications_manage on public.parent_verifications
for all using (guardian_id = auth.uid()) with check (guardian_id = auth.uid());

create policy children_manage on public.children
for all using (guardian_id = auth.uid()) with check (guardian_id = auth.uid());

create policy child_sessions_manage on public.child_sessions
for all using (exists (select 1 from public.children c where c.id = public.child_sessions.child_id and c.guardian_id = auth.uid()))
with check (exists (select 1 from public.children c where c.id = public.child_sessions.child_id and c.guardian_id = auth.uid()));

create policy discovery_intakes_manage on public.discovery_intakes
for all using (guardian_id = auth.uid()) with check (guardian_id = auth.uid());

create policy sensory_configurations_manage on public.sensory_configurations
for all using (public.guardian_owns_child(child_id)) with check (public.guardian_owns_child(child_id));

create policy adult_notes_manage on public.adult_exploratory_notes
for all using (public.guardian_owns_child(child_id)) with check (public.guardian_owns_child(child_id));

create policy child_experience_child_session on public.child_experience
for all using (((auth.jwt() ->> 'child_session_id'))::uuid = child_session_id)
with check (((auth.jwt() ->> 'child_session_id'))::uuid = child_session_id);

create policy vertical_task_bank_read on public.vertical_task_bank
for select using (true);

create policy layer_progression_state_manage on public.layer_progression_state
for all using (public.guardian_owns_child(child_id)) with check (public.guardian_owns_child(child_id));

create policy layer_task_execution_manage on public.layer_task_execution
for all using (public.guardian_owns_child(child_id)) with check (public.guardian_owns_child(child_id));

create policy support_ladder_log_manage on public.support_ladder_log
for all using (public.guardian_owns_child(child_id)) with check (public.guardian_owns_child(child_id));

create policy consistency_window_manage on public.consistency_window
for all using (public.guardian_owns_child(child_id)) with check (public.guardian_owns_child(child_id));

create policy sandbox_session_manage on public.sandbox_session
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy sandbox_attempt_manage on public.sandbox_attempt
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy difficulty_state_manage on public.difficulty_state
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy trigger_definitions_read on public.trigger_definitions
for select using (true);

create policy trigger_instances_manage on public.trigger_instances
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy trigger_dispatch_queue_manage on public.trigger_dispatch_queue
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy device_tokens_manage on public.device_tokens
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy purge_requests_manage on public.purge_requests
for all using (guardian_id = auth.uid()) with check (guardian_id = auth.uid());

create policy audit_log_service_only on public.audit_log
for all using (false) with check (false);

create trigger audit_children after insert or update or delete on public.children for each row execute function public.write_audit_log();
create trigger audit_parent_verifications after insert or update or delete on public.parent_verifications for each row execute function public.write_audit_log();
create trigger audit_intakes after insert or update or delete on public.discovery_intakes for each row execute function public.write_audit_log();
create trigger audit_adult_notes after insert or update or delete on public.adult_exploratory_notes for each row execute function public.write_audit_log();

insert into public.consent_versions (version, jurisdiction, document_url, active)
values ('v1', 'IN', 'https://example.invalid/consent/v1', true)
on conflict (version) do nothing;

insert into public.vertical_task_bank (track, bank_key, item)
values ('CALENDAR_GENIUS', 'sample', '{"title":"Sample task","prompt":"Warm, bounded, child-safe"}'::jsonb)
on conflict do nothing;