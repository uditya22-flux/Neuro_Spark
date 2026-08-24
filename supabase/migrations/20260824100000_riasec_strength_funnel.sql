-- Phase 1: RIASEC 30-sector strength funnel + ISAA profiles
-- Charter: present-moment enjoyment framing only; no diagnostic or employment labels.

-- ---------------------------------------------------------------------------
-- ISAA profiles (linked to existing children — auth.users remains identity)
-- ---------------------------------------------------------------------------
create table if not exists public.child_isaa_profiles (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  guardian_id uuid not null references auth.users(id) on delete cascade,
  social_relationship int not null check (social_relationship between 1 and 5),
  emotional_responsiveness int not null check (emotional_responsiveness between 1 and 5),
  speech_communication int not null check (speech_communication between 1 and 5),
  behavior_patterns int not null check (behavior_patterns between 1 and 5),
  sensory_aspects int not null check (sensory_aspects between 1 and 5),
  cognitive_component int not null check (cognitive_component between 1 and 5),
  sound_triggers jsonb not null default '[]'::jsonb,
  visual_triggers jsonb not null default '[]'::jsonb,
  tactile_preference text not null default 'neutral'
    check (tactile_preference in ('prefers_haptics', 'no_vibrations', 'neutral')),
  recorded_at timestamptz not null default now(),
  unique (child_id)
);

-- ---------------------------------------------------------------------------
-- 30 RIASEC-derived interest sectors (5 sub-sectors × 6 RIASEC types)
-- ---------------------------------------------------------------------------
create table if not exists public.riasec_sectors (
  id text primary key,
  riasec_type text not null check (
    riasec_type in ('realistic', 'investigative', 'artistic', 'social', 'enterprising', 'conventional')
  ),
  sub_sector_index int not null check (sub_sector_index between 1 and 5),
  display_name text not null,
  play_theme text not null,
  active boolean not null default true,
  unique (riasec_type, sub_sector_index)
);

-- JSON templates used by generative AI to build layer tasks (not static questions)
create table if not exists public.riasec_sector_templates (
  id uuid primary key default gen_random_uuid(),
  sector_id text not null references public.riasec_sectors(id) on delete cascade,
  template_version text not null default '2026-08-24',
  template_json jsonb not null,
  golden_rule_ack boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (sector_id, template_version)
);

-- ---------------------------------------------------------------------------
-- 10-layer adaptive funnel sessions (60% engagement filter)
-- ---------------------------------------------------------------------------
create table if not exists public.strength_funnel_sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children(id) on delete cascade,
  guardian_id uuid not null references auth.users(id) on delete cascade,
  isaa_profile_id uuid references public.child_isaa_profiles(id) on delete set null,
  status text not null default 'in_progress'
    check (status in ('in_progress', 'completed', 'abandoned')),
  current_layer int not null default 1 check (current_layer between 1 and 10),
  active_sector_ids text[] not null default '{}',
  modality_constraints jsonb not null default '{}'::jsonb,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  expires_at timestamptz not null default (now() + interval '7 days')
);

create table if not exists public.strength_funnel_layer_runs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.strength_funnel_sessions(id) on delete cascade,
  layer_number int not null check (layer_number between 1 and 10),
  sectors_assessed int not null,
  sectors_advancing int not null,
  filter_ratio numeric(4, 2) not null default 0.60,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (session_id, layer_number)
);

create table if not exists public.strength_funnel_sector_scores (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.strength_funnel_sessions(id) on delete cascade,
  layer_run_id uuid not null references public.strength_funnel_layer_runs(id) on delete cascade,
  sector_id text not null references public.riasec_sectors(id),
  engagement_score numeric(5, 4) not null check (engagement_score between 0 and 1),
  modality_used text not null check (modality_used in ('picture', 'video', 'text', 'haptic')),
  response_payload jsonb not null default '{}'::jsonb,
  latency_ms int,
  created_at timestamptz not null default now(),
  unique (layer_run_id, sector_id)
);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.child_isaa_profiles enable row level security;
create policy child_isaa_guardian on public.child_isaa_profiles
  for all using (public.child_owned(child_id))
  with check (public.child_owned(child_id));

alter table public.riasec_sectors enable row level security;
create policy riasec_sectors_read on public.riasec_sectors
  for select to authenticated using (active);

alter table public.riasec_sector_templates enable row level security;
create policy riasec_templates_read on public.riasec_sector_templates
  for select to authenticated using (active);

alter table public.strength_funnel_sessions enable row level security;
create policy strength_funnel_sessions_guardian on public.strength_funnel_sessions
  for all using (guardian_id = auth.uid() and public.child_owned(child_id))
  with check (guardian_id = auth.uid() and public.child_owned(child_id));

alter table public.strength_funnel_layer_runs enable row level security;
create policy strength_funnel_layer_runs_guardian on public.strength_funnel_layer_runs
  for all using (
    exists (
      select 1 from public.strength_funnel_sessions s
      where s.id = session_id and s.guardian_id = auth.uid()
    )
  );

alter table public.strength_funnel_sector_scores enable row level security;
create policy strength_funnel_sector_scores_guardian on public.strength_funnel_sector_scores
  for all using (
    exists (
      select 1 from public.strength_funnel_sessions s
      where s.id = session_id and s.guardian_id = auth.uid()
    )
  );

create index strength_funnel_sessions_child_idx on public.strength_funnel_sessions(child_id);
create index strength_funnel_scores_session_idx on public.strength_funnel_sector_scores(session_id);

-- ---------------------------------------------------------------------------
-- Seed: 30 RIASEC sectors (childhood play themes — not adult job titles)
-- ---------------------------------------------------------------------------
insert into public.riasec_sectors (id, riasec_type, sub_sector_index, display_name, play_theme) values
  ('r_build_fix', 'realistic', 1, 'Build & Fix', 'building blocks and fixing things'),
  ('r_nature_outdoors', 'realistic', 2, 'Nature Outdoors', 'plants, trails, and outdoor exploring'),
  ('r_sports_movement', 'realistic', 3, 'Sports & Movement', 'running, climbing, and active play'),
  ('r_crafts_making', 'realistic', 4, 'Crafts & Making', 'hands-on making and crafting'),
  ('r_vehicles_machines', 'realistic', 5, 'Vehicles & Machines', 'trains, wheels, and simple machines'),
  ('i_puzzles_logic', 'investigative', 1, 'Puzzles & Logic', 'logic puzzles and figuring things out'),
  ('i_nature_science', 'investigative', 2, 'Nature Science', 'bugs, rocks, and curious observing'),
  ('i_numbers_patterns', 'investigative', 3, 'Numbers & Patterns', 'counting patterns and sequences'),
  ('i_maps_exploring', 'investigative', 4, 'Maps & Exploring', 'maps, mazes, and path finding'),
  ('i_experiments_trying', 'investigative', 5, 'Experiments & Trying', 'mixing, testing, and trying ideas'),
  ('a_drawing_color', 'artistic', 1, 'Drawing & Color', 'drawing, coloring, and visual art'),
  ('a_music_rhythm', 'artistic', 2, 'Music & Rhythm', 'sounds, beats, and rhythm play'),
  ('a_story_imagine', 'artistic', 3, 'Story & Imagine', 'stories, characters, and imagination'),
  ('a_build_design', 'artistic', 4, 'Build & Design', 'designing shapes and creative layouts'),
  ('a_performance_show', 'artistic', 5, 'Performance & Show', 'acting out and playful performance'),
  ('s_helping_caring', 'social', 1, 'Helping & Caring', 'helping others and gentle care play'),
  ('s_teaching_showing', 'social', 2, 'Teaching & Showing', 'showing how something works to a friend'),
  ('s_team_play', 'social', 3, 'Team Play', 'cooperative games and shared goals'),
  ('s_community_events', 'social', 4, 'Community Events', 'festivals, groups, and gatherings'),
  ('s_friend_connections', 'social', 5, 'Friend Connections', 'friendship routines and social play'),
  ('e_leading_groups', 'enterprising', 1, 'Leading Groups', 'leading a small play group activity'),
  ('e_selling_trading', 'enterprising', 2, 'Trading & Swapping', 'swapping cards and playful trading'),
  ('e_planning_events', 'enterprising', 3, 'Planning Events', 'planning a pretend party or outing'),
  ('e_persuading_sharing', 'enterprising', 4, 'Sharing Ideas', 'sharing a fun idea with others'),
  ('e_starting_projects', 'enterprising', 5, 'Starting Projects', 'starting a small creative project'),
  ('c_sorting_organizing', 'conventional', 1, 'Sorting & Organizing', 'sorting objects into groups'),
  ('c_schedules_routines', 'conventional', 2, 'Schedules & Routines', 'daily routines and timetables'),
  ('c_lists_checklists', 'conventional', 3, 'Lists & Checklists', 'checklists and step-by-step lists'),
  ('c_collecting_sets', 'conventional', 4, 'Collecting Sets', 'collecting and completing sets'),
  ('c_patterns_order', 'conventional', 5, 'Patterns & Order', 'patterns, order, and neat arrangements')
on conflict (id) do nothing;

-- Seed: Realistic domain generative template (golden rule enforced in JSON + app validator)
insert into public.riasec_sector_templates (sector_id, template_version, template_json, golden_rule_ack)
values (
  'r_build_fix',
  '2026-08-24',
  '{"template_version":"2026-08-24","sector_id":"r_build_fix","riasec_type":"realistic","display_name":"Build & Fix","framing_rules":{"golden_rule":"Measure present-moment enjoyment only. Never reference future jobs, careers, salaries, or adult work roles.","prompt_tone":"playful_now","forbidden_terms":["career","job","employ","salary","when you grow up","become a","profession","industry"],"required_framing":"Ask whether the child is enjoying this activity right now."},"visual_guidelines":{"style":"simple_stylized_drawing","show_gender_features":false,"show_complex_facial_expressions":false,"focus":"concrete_activity_only","avoid_visual_clutter":true},"sample_generated_task":{"present_moment_prompt":"Is snapping blocks together fun for you right now?","activity_scene":{"activity_label":"Building a small tower","simple_picture_description":"A plain side-view drawing of two hands stacking three blocks. No faces. Neutral colors."},"response_modality":"picture","enjoyment_scale":{"type":"present_moment_likert_visual","min_label":"Not fun right now","max_label":"Really fun right now"}}}'::jsonb,
  true
)
on conflict (sector_id, template_version) do nothing;
