-- Synthetic showcase protection: only anonymous demo sessions may consume the
-- Groq-backed scene generator, and each session has a small rolling quota.
create table if not exists public.synthetic_demo_scene_quota (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null default timezone('utc', now()),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.synthetic_demo_scene_quota enable row level security;
revoke all on table public.synthetic_demo_scene_quota from anon, authenticated;

create or replace function public.consume_synthetic_demo_scene_quota(
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
  if p_user_id is null or p_limit < 1 or p_limit > 100 then
    return false;
  end if;

  insert into public.synthetic_demo_scene_quota (
    user_id,
    window_started_at,
    request_count,
    updated_at
  )
  values (p_user_id, timezone('utc', now()), 1, timezone('utc', now()))
  on conflict (user_id) do update
  set
    window_started_at = case
      when synthetic_demo_scene_quota.window_started_at <= timezone('utc', now()) - interval '1 hour'
        then timezone('utc', now())
      else synthetic_demo_scene_quota.window_started_at
    end,
    request_count = case
      when synthetic_demo_scene_quota.window_started_at <= timezone('utc', now()) - interval '1 hour'
        then 1
      else synthetic_demo_scene_quota.request_count + 1
    end,
    updated_at = timezone('utc', now())
  returning request_count into current_count;

  return current_count <= p_limit;
end;
$$;

revoke all on function public.consume_synthetic_demo_scene_quota(uuid, integer) from public;
grant execute on function public.consume_synthetic_demo_scene_quota(uuid, integer) to service_role;
