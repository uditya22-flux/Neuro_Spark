-- Keep the synthetic cloud showcase and its opaque paired-device code alive
-- for one demo day. The table's existing maximum-lifetime check already caps
-- every row at 24 hours from creation.

alter table public.synthetic_engine2_demo_sessions
  alter column expires_at
  set default (timezone('utc', now()) + interval '24 hours');

-- Extend non-expired fictional sessions created under the prior three-hour
-- default. Expired rows stay expired and are never revived.
update public.synthetic_engine2_demo_sessions
set
  expires_at = created_at + interval '24 hours',
  updated_at = timezone('utc', now())
where status in ('in_progress', 'complete')
  and expires_at > timezone('utc', now())
  and expires_at < created_at + interval '24 hours';
