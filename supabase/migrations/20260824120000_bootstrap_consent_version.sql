-- Active consent document required before create-child / funnel edge functions run.
insert into public.consent_versions (version, jurisdiction, document_url, active)
values (
  '2026-08-private-beta',
  'IN',
  'https://mindbridge.example/legal/private-beta-consent',
  true
)
on conflict (version) do update
set active = excluded.active,
    document_url = excluded.document_url;

grant all on public.consent_versions to service_role;
grant all on public.parent_verifications to service_role;
grant all on public.guardian_consents to service_role;
grant all on public.children to service_role;
