create extension if not exists pgcrypto;

-- Supabase is the system of record. Firebase is never used as a database.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'guardian' check (role in ('guardian','child')),
  guardian_id uuid references auth.users(id) on delete cascade,
  preferred_name text,
  sensory_control_matrix jsonb not null default '{}'::jsonb,
  generative_ui_parameters jsonb not null default '{}'::jsonb,
  fcm_token text,
  fcm_platform text check (fcm_platform in ('android','ios','web')),
  fcm_token_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((role = 'guardian' and guardian_id is null) or (role = 'child' and guardian_id is not null))
);

create table public.consent_versions (id uuid primary key default gen_random_uuid(), version text unique not null, jurisdiction text not null default 'IN', document_url text not null, active boolean not null default true, created_at timestamptz not null default now());
create table public.parent_verifications (id uuid primary key default gen_random_uuid(), guardian_id uuid not null references auth.users(id) on delete cascade, method text not null check (method in ('email_otp','phone_otp','digilocker')), status text not null check (status in ('pending','verified','failed')), verified_at timestamptz, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now());
create table public.children (id uuid primary key default gen_random_uuid(), guardian_id uuid not null references auth.users(id) on delete cascade, preferred_name text not null, birth_year int not null check (birth_year between 1900 and extract(year from now())::int), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.guardian_consents (id uuid primary key default gen_random_uuid(), guardian_id uuid not null references auth.users(id) on delete cascade, consent_version_id uuid not null references public.consent_versions(id), status text not null default 'pending' check (status in ('pending','active','revoked')), accepted_at timestamptz, revoked_at timestamptz, unique(guardian_id, consent_version_id));
create table public.sessions (id uuid primary key default gen_random_uuid(), child_id uuid not null references public.children(id) on delete cascade, guardian_id uuid not null references auth.users(id) on delete cascade, expires_at timestamptz not null, revoked_at timestamptz, created_at timestamptz not null default now());
create table public.discovery_intakes (id uuid primary key default gen_random_uuid(), child_id uuid not null references public.children(id) on delete cascade, guardian_id uuid not null references auth.users(id) on delete cascade, raw_text text not null, redacted_text text not null, expires_at timestamptz not null, created_at timestamptz not null default now());
create table public.sensory_configurations (id uuid primary key default gen_random_uuid(), child_id uuid not null references public.children(id) on delete cascade, config_version int not null, key text not null, proposed_value jsonb not null, status text not null default 'pending' check (status in ('pending','confirmed','rejected')), reviewed_at timestamptz, active boolean not null default false, unique(child_id, config_version, key));
create table public.child_experience (id uuid primary key default gen_random_uuid(), child_id uuid not null references public.children(id) on delete cascade, payload jsonb not null, created_at timestamptz not null default now());
create table public.adult_exploratory_note (id uuid primary key default gen_random_uuid(), child_id uuid not null references public.children(id) on delete cascade, taxonomy_key text not null, observations jsonb not null, evidence jsonb not null, disclaimer text not null, created_at timestamptz not null default now());
create table public.purge_requests (id uuid primary key default gen_random_uuid(), guardian_id uuid not null references auth.users(id) on delete cascade, child_id uuid references public.children(id) on delete cascade, status text not null default 'requested', requested_at timestamptz not null default now(), completed_at timestamptz);
create table public.audit_log (id uuid primary key default gen_random_uuid(), guardian_id uuid, child_id uuid, actor_id uuid, action text not null, metadata jsonb not null default '{}', created_at timestamptz not null default now());
create table public.trigger_definitions (id uuid primary key default gen_random_uuid(), key text unique not null, enabled boolean not null default true, definition jsonb not null default '{}');
create table public.trigger_instances (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, candidate_action jsonb not null, created_at timestamptz not null default now());
create table public.trigger_cooldowns (user_id uuid primary key references auth.users(id) on delete cascade, until_at timestamptz not null);
create table public.trigger_dispatch_queue (id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade, payload jsonb not null, status text not null default 'queued', created_at timestamptz not null default now(), dispatched_at timestamptz);
create table public.device_tokens (user_id uuid not null references auth.users(id) on delete cascade, fcm_token text not null, platform text not null, updated_at timestamptz not null default now(), primary key(user_id, fcm_token));
create table public.trigger_guardrails (id uuid primary key default gen_random_uuid(), guardian_id uuid not null unique references auth.users(id) on delete cascade, quiet_hours_start time, quiet_hours_end time, daily_ceiling int not null default 0 check (daily_ceiling >= 0), opt_out boolean not null default true, updated_at timestamptz not null default now());
create table public.pending_triggers (id uuid primary key default gen_random_uuid(), guardian_id uuid not null references auth.users(id) on delete cascade, child_id uuid references public.children(id) on delete cascade, title text not null, body text not null, channel text not null check (channel in ('silent','standard')), status text not null default 'queued' check (status in ('queued','sending','sent','failed','cancelled')), attempts int not null default 0, created_at timestamptz not null default now(), dispatched_at timestamptz, last_error text);

create or replace function public.has_verified_guardian() returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.parent_verifications where guardian_id=auth.uid() and status='verified') $$;
create or replace function public.child_owned(target uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.children where id=target and guardian_id=auth.uid()) $$;
create or replace function public.require_confirmed_configuration() returns trigger language plpgsql as $$ begin if new.active and exists(select 1 from public.sensory_configurations where child_id=new.child_id and config_version=new.config_version and status <> 'confirmed') then raise exception 'all sensory items must be confirmed before activation'; end if; return new; end $$;
create trigger sensory_activation_guard before insert or update on public.sensory_configurations for each row when (new.active) execute function public.require_confirmed_configuration();

create or replace function public.request_trigger(p_child_id uuid, p_title text, p_body text, p_channel text default 'silent') returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_guardian uuid;
begin
  select guardian_id into v_guardian from public.children where id = p_child_id;
  if v_guardian is null or (auth.uid() is not null and v_guardian <> auth.uid()) then raise exception 'child not accessible'; end if;
  if p_channel not in ('silent','standard') then raise exception 'invalid channel'; end if;
  insert into public.pending_triggers(guardian_id, child_id, title, body, channel)
  values (v_guardian, p_child_id, left(p_title, 120), left(p_body, 500), p_channel)
  returning id into v_id;
  return v_id;
end $$;

alter table public.consent_versions enable row level security;
create policy consent_versions_read on public.consent_versions for select to authenticated using (active);
alter table public.profiles enable row level security;
create policy profiles_self_read on public.profiles for select using (id=auth.uid() or guardian_id=auth.uid());
create policy profiles_self_update on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
alter table public.parent_verifications enable row level security;
create policy verification_self on public.parent_verifications for select using (guardian_id=auth.uid());
create policy verification_insert on public.parent_verifications for insert with check (guardian_id=auth.uid());
alter table public.children enable row level security;
create policy children_guardian_read on public.children for select using (guardian_id=auth.uid());
create policy children_guardian_insert on public.children for insert with check (guardian_id=auth.uid() and public.has_verified_guardian());
create policy children_guardian_update on public.children for update using (guardian_id=auth.uid()) with check (guardian_id=auth.uid());
alter table public.guardian_consents enable row level security;
create policy consents_self on public.guardian_consents for all using (guardian_id=auth.uid()) with check (guardian_id=auth.uid());
alter table public.sessions enable row level security;
create policy sessions_guardian on public.sessions for all using (guardian_id=auth.uid()) with check (guardian_id=auth.uid() and public.child_owned(child_id));
alter table public.discovery_intakes enable row level security;
create policy intakes_guardian on public.discovery_intakes for all using (guardian_id=auth.uid()) with check (guardian_id=auth.uid() and public.child_owned(child_id));
alter table public.sensory_configurations enable row level security;
create policy sensory_guardian on public.sensory_configurations for all using (public.child_owned(child_id)) with check (public.child_owned(child_id));
alter table public.child_experience enable row level security;
create policy child_experience_guardian on public.child_experience for select using (public.child_owned(child_id));
alter table public.adult_exploratory_note enable row level security;
create policy adult_note_guardian on public.adult_exploratory_note for select using (public.child_owned(child_id));
alter table public.purge_requests enable row level security;
create policy purge_guardian on public.purge_requests for all using (guardian_id=auth.uid()) with check (guardian_id=auth.uid());
alter table public.device_tokens enable row level security;
create policy tokens_self on public.device_tokens for all using (user_id=auth.uid()) with check (user_id=auth.uid());
alter table public.trigger_instances enable row level security;
create policy trigger_self on public.trigger_instances for insert with check (user_id=auth.uid());
alter table public.trigger_dispatch_queue enable row level security;
create policy dispatch_self on public.trigger_dispatch_queue for select using (user_id=auth.uid());

create index children_guardian_idx on public.children(guardian_id);
create index intakes_expiry_idx on public.discovery_intakes(expires_at);
create index dispatch_status_idx on public.trigger_dispatch_queue(status, created_at);
alter table public.trigger_dispatch_queue replica identity full;
alter table public.pending_triggers enable row level security;
create policy pending_trigger_guardian_read on public.pending_triggers for select using (guardian_id=auth.uid());
alter table public.trigger_guardrails enable row level security;
create policy guardrails_self on public.trigger_guardrails for all using (guardian_id=auth.uid()) with check (guardian_id=auth.uid());

create index pending_triggers_status_idx on public.pending_triggers(status, created_at);

grant execute on function public.request_trigger(uuid, text, text, text) to authenticated;

create or replace function public.handle_new_user_profile() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.profiles(id) values (new.id) on conflict (id) do nothing; return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user_profile();
