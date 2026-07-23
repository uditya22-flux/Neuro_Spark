-- Engine 2: 10-Sector Wide-to-Narrow Cognitive Elimination Funnel Migration
-- Adds sector taxonomy support, track affinity aggregates, elimination trail, and decider tracking.

do $$
declare
  target_table text;
  constraint_name text;
  domain_list constant text := '''calendar_genius'', ''constellation_mapper'', ''discovery'', ''visual_pattern_explorer'', ''sequence_navigator'', ''spatial_builder'', ''memory_weaver'', ''language_patterner'', ''number_navigator'', ''logic_lens'', ''pattern_recognition'', ''spatial_reasoning'', ''sequencing_ordering'', ''working_memory'', ''numeric_reasoning'', ''categorization'', ''visual_anomaly_detection'', ''auditory_processing'', ''verbal_language'', ''motor_precision''';
begin
  foreach target_table in array array[
    'vertical_task_bank',
    'sublayer_telemetry',
    'stage2_handoffs',
    'layer_progression_state',
    'layer_task_execution',
    'support_ladder_log',
    'consistency_window',
    'deepening_profiles',
    'stage3_handoffs'
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
      domain_list
    );
  end loop;
end $$;

alter table public.layer_progression_state
  add column if not exists active_sectors jsonb not null default '[]'::jsonb,
  add column if not exists sector_scores jsonb not null default '{}'::jsonb,
  add column if not exists track_affinity jsonb not null default '{}'::jsonb,
  add column if not exists elimination_trail jsonb not null default '[]'::jsonb,
  add column if not exists winning_track text check (winning_track in ('calendar_genius', 'constellation_mapper')),
  add column if not exists decider_required boolean not null default false;

create index if not exists layer_progression_funnel_lookup_idx
  on public.layer_progression_state(session_id, child_id, status);
