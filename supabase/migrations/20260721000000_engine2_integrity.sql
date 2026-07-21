-- Engine 2.a/2.b integrity hardening.
-- Responses are bounded to their task/session and can be retried safely when
-- the client supplies the same response_id.

alter table public.sublayer_telemetry
  add column response_id uuid not null default gen_random_uuid();

create unique index sublayer_telemetry_task_once_idx
  on public.sublayer_telemetry(session_id, task_id);
create unique index sublayer_telemetry_response_idx
  on public.sublayer_telemetry(session_id, response_id);

create unique index vertical_task_bank_active_layer_idx
  on public.vertical_task_bank(session_id, vertical_id, layer_number)
  where session_id is not null and active;

alter table public.layer_task_execution
  add column response_id uuid not null default gen_random_uuid();

create unique index layer_task_execution_response_idx
  on public.layer_task_execution(session_id, response_id);
