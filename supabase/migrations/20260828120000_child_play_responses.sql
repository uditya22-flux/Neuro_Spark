-- Child play present-moment enjoyment responses (guardian-supervised sessions).
-- Charter: no scores, streaks, badges, or child notifications.

create table if not exists public.child_play_responses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  guardian_id uuid not null references auth.users(id) on delete cascade,
  sector_id text not null references public.riasec_sectors(id),
  enjoyed boolean not null default true,
  skipped boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists child_play_responses_child_idx
  on public.child_play_responses(child_id, created_at desc);

alter table public.child_play_responses enable row level security;

create policy child_play_responses_guardian on public.child_play_responses
  for all using (guardian_id = auth.uid() and public.child_owned(child_id))
  with check (guardian_id = auth.uid() and public.child_owned(child_id));
