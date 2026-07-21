-- Engine 2.b: independent per-vertical funnels, auditable route changes, and
-- complete support-ladder / Engine 3 handoff persistence.

do $$
declare
  target_table text;
  constraint_name text;
  verticals constant text := '''calendar_genius'', ''constellation_mapper'', ''discovery'', ''visual_pattern_explorer'', ''sequence_navigator'', ''spatial_builder'', ''memory_weaver'', ''language_patterner'', ''number_navigator'', ''logic_lens''';
begin
  foreach target_table in array array[
    'vertical_task_bank',
    'sublayer_telemetry',
    'stage2_handoffs',
    'layer_progression_state',
    'layer_task_execution',
    'support_ladder_log',
    'consistency_window',
    'deepening_profiles'
  ] loop
    for constraint_name in
      select conname
      from pg_constraint
      where conrelid = ('public.' || target_table)::regclass
        and contype = 'c'
        and pg_get_constraintdef(oid) like '%vertical_id%'
    loop
      execute format('alter table public.%I drop constraint %I', target_table, constraint_name);
    end loop;
    execute format(
      'alter table public.%I add constraint %I check (vertical_id in (%s))',
      target_table,
      target_table || '_vertical_id_check',
      verticals
    );
  end loop;
end $$;

alter table public.layer_progression_state
  add column if not exists path_history jsonb not null default '[]'::jsonb;

alter table public.layer_task_execution
  add column if not exists execution_index int not null default 1 check (execution_index >= 1),
  add column if not exists presentation_metadata jsonb not null default '{}'::jsonb;

create index if not exists layer_execution_attempt_lookup_idx
  on public.layer_task_execution(session_id, task_id, execution_index);

create table public.stage3_handoffs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.layer1_sessions(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  vertical_id text not null check (vertical_id in (
    'calendar_genius', 'constellation_mapper', 'discovery',
    'visual_pattern_explorer', 'sequence_navigator', 'spatial_builder',
    'memory_weaver', 'language_patterner', 'number_navigator', 'logic_lens'
  )),
  deepening_profile jsonb not null,
  telemetry_reference text not null,
  created_at timestamptz not null default now(),
  unique(session_id, vertical_id)
);

alter table public.stage3_handoffs enable row level security;
create policy stage3_handoff_guardian on public.stage3_handoffs
  for select using (public.child_owned(child_id));
create index stage3_handoffs_child_idx
  on public.stage3_handoffs(child_id, vertical_id, created_at desc);
