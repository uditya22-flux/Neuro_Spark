-- Guardian-stated presentation preferences for the child exploration space.
-- This is not a diagnostic or predictive profile.
create table if not exists public.guardian_exploration_preferences (
  child_id uuid primary key references public.children(id) on delete cascade,
  guardian_id uuid not null references auth.users(id) on delete cascade,
  configuration jsonb not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.guardian_exploration_preferences enable row level security;

create policy guardian_exploration_preferences_read
  on public.guardian_exploration_preferences
  for select
  using (guardian_id = auth.uid() and public.child_owned(child_id));

create policy guardian_exploration_preferences_insert
  on public.guardian_exploration_preferences
  for insert
  with check (guardian_id = auth.uid() and public.child_owned(child_id));

create policy guardian_exploration_preferences_update
  on public.guardian_exploration_preferences
  for update
  using (guardian_id = auth.uid() and public.child_owned(child_id))
  with check (guardian_id = auth.uid() and public.child_owned(child_id));

create index if not exists guardian_exploration_preferences_expiry_idx
  on public.guardian_exploration_preferences(expires_at);
