-- Circle — Migração 0005: cobertura por agência para o front (sem expor sources/ingestion_runs)
create or replace function public.rpc_agency_coverage()
returns table (sigla text, nome text, setor text, esfera text, nivel_voto text, fontes_ativas int, atualizado_em timestamptz)
language sql stable security definer set search_path = public as $$
  select a.sigla, a.nome, a.setor, a.esfera, a.nivel_voto,
         (select count(*) from sources s where s.agency_id = a.id and s.ativo)::int,
         (select max(s.last_ok_at) from sources s where s.agency_id = a.id and s.ativo)
  from agencies a where a.ativo
  order by a.sigla
$$;
revoke all on function public.rpc_agency_coverage() from public, anon;
grant execute on function public.rpc_agency_coverage() to authenticated;
