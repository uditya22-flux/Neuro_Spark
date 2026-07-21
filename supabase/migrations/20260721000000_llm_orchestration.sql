create table public.global_progression_state (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  current_layer int not null check (current_layer between 2 and 10),
  status text not null default 'in_progress' check (status in ('in_progress', 'layer_complete', 'funnel_complete')),
  active_tasks jsonb not null default '[]'::jsonb, -- list of task IDs for the current layer
  completed_tasks jsonb not null default '[]'::jsonb, -- list of task IDs completed in the current layer
  orchestration_plan jsonb not null default '{}'::jsonb, -- the LLM's plan for this layer
  updated_at timestamptz not null default now(),
  unique(session_id)
);

alter table public.global_progression_state enable row level security;
create policy global_progression_guardian on public.global_progression_state for select using (public.child_owned(child_id));
create index global_progression_child_idx on public.global_progression_state(child_id, session_id);
