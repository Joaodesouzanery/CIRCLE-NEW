-- =====================================================================
-- Circle — Migração 0002: qualidade dos dados, operação e notificações
-- Pré-requisito: 0001. Testada em Postgres 16 com stub do schema auth.
-- =====================================================================

-- ---------- 1. Ajustes de modelo descobertos na pesquisa ----------
-- Pauta != o que foi deliberado: itens podem ser votados extrapauta, adiados, ter pedido de vista.
alter table public.agenda_items
  add column if not exists situacao text not null default 'pauta'
    check (situacao in ('pauta','deliberado','adiado','pedido_vista','retirado','extrapauta')),
  add column if not exists unanime boolean,          -- ata registra "por unanimidade"
  add column if not exists created_at timestamptz not null default now();

alter table public.process_events
  add column if not exists criado_em timestamptz not null default now();   -- momento da ingestão (≠ ocorrido_em)

alter table public.director_votes
  add column if not exists observacao text;          -- ex.: "aderiu ao voto do Diretor X", "voto enviado por escrito"

-- Confirmados na pesquisa de out/2026: ANP 48610, ANS 33910
update public.agencies set nup_prefixos = '{48610}' where sigla = 'ANP' and nup_prefixos = '{}';
update public.agencies set nup_prefixos = '{33910}' where sigla = 'ANS' and nup_prefixos = '{}';

-- ---------- 2. Proveniência e verificação de completude ----------
alter table public.raw_documents
  add column if not exists parser_version text,
  add column if not exists parse_confidence numeric check (parse_confidence is null or (parse_confidence between 0 and 1)),
  add column if not exists esperado_n integer,       -- ex.: nº de acórdãos que a ata diz ter aprovado (ANTAQ: "nºs 440 a 471 e 473 a 475")
  add column if not exists extraido_n integer;       -- quantos o parser realmente extraiu

alter table public.sources
  add column if not exists sla_horas integer not null default 48;   -- atraso máximo aceitável desde a última coleta OK

create table if not exists public.data_quality_issues (
  id uuid primary key default gen_random_uuid(),
  source_id uuid references public.sources(id),
  raw_document_id uuid references public.raw_documents(id),
  severidade text not null check (severidade in ('baixa','media','alta')),
  tipo text not null,                                -- ex.: parser_falhou, contagem_divergente, campo_ausente, layout_mudou
  detalhe text,
  criado_em timestamptz not null default now(),
  resolvido_em timestamptz,
  resolvido_por text
);
create index if not exists data_quality_issues_open on public.data_quality_issues (source_id) where resolvido_em is null;
alter table public.data_quality_issues enable row level security;   -- sem policy: só service_role

-- ---------- 3. Administração da plataforma ----------
create table if not exists public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.platform_admins enable row level security;

create or replace function public.is_platform_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.platform_admins pa where pa.user_id = auth.uid())
$$;

-- Contatos para alertas por e-mail (e-mail não fica em auth.users acessível ao N8N)
create table if not exists public.client_contacts (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  email text not null,
  ativo boolean not null default true,
  unique (client_id, email)
);
alter table public.client_contacts enable row level security;
create policy client_contacts_all on public.client_contacts for all to authenticated
  using (public.is_client_member(client_id)) with check (public.is_client_member(client_id));

-- ---------- 4. Saúde das coletas e anomalias (somente service_role / admins) ----------
create or replace view public.v_ingestion_health as
select s.id as source_id, s.codigo, a.sigla as agencia, s.ativo, s.sla_horas,
       s.last_ok_at, s.last_rows,
       lr.status as ultimo_status, lr.iniciado_em as ultimo_run, lr.n_encontrados, lr.erro,
       round((extract(epoch from (now() - s.last_ok_at)) / 3600.0)::numeric, 1) as horas_desde_ok,
       (s.ativo and (s.last_ok_at is null or now() - s.last_ok_at > make_interval(hours => s.sla_horas))) as atrasada,
       (select count(*) from public.data_quality_issues d
         where d.source_id = s.id and d.resolvido_em is null)::int as issues_abertos
from public.sources s
join public.agencies a on a.id = s.agency_id
left join lateral (select * from public.ingestion_runs r
                   where r.source_id = s.id order by r.iniciado_em desc limit 1) lr on true;

create or replace view public.v_dq_anomalias as
-- 1) NUP com prefixo incompatível com a agência da reunião
select 'nup_prefixo_incompativel'::text as regra, 'media'::text as severidade, ai.id::text as ref,
       (a.sigla || ' ' || ai.nup)::text as detalhe
from public.agenda_items ai
join public.meetings m on m.id = ai.meeting_id
join public.agencies a on a.id = m.agency_id
where ai.nup is not null and cardinality(a.nup_prefixos) > 0 and left(ai.nup, 5) <> all (a.nup_prefixos)
union all
-- 2) item de reunião antiga ainda "pendente" (resultado não capturado)
select 'resultado_nao_capturado', 'media', ai.id::text, (a.sigla || ' ' || coalesce(m.numero::text,'?') || '/' || coalesce(m.ano::text,'') || ' item ' || ai.item_ref)
from public.agenda_items ai
join public.meetings m on m.id = ai.meeting_id
join public.agencies a on a.id = m.agency_id
where m.inicio < now() - interval '30 days' and ai.resultado_tipo = 'pendente'
  and ai.situacao in ('pauta','deliberado') and not ai.retirado_de_pauta
union all
-- 3) reunião realizada sem ata há mais de 15 dias
select 'realizada_sem_ata', 'media', m.id::text, (a.sigla || ' ' || coalesce(m.numero::text,'?') || '/' || coalesce(m.ano::text,''))
from public.meetings m join public.agencies a on a.id = m.agency_id
where m.status = 'realizada' and m.ata_doc_id is null and m.inicio < now() - interval '15 days'
union all
-- 4) contagem extraída diferente da esperada (ex.: acórdãos da ata)
select 'contagem_divergente', 'alta', rd.id::text, ('esperado=' || rd.esperado_n || ' extraido=' || coalesce(rd.extraido_n::text,'null') || ' ' || rd.url)
from public.raw_documents rd
where rd.esperado_n is not null and rd.extraido_n is distinct from rd.esperado_n
union all
-- 5) linha sem proveniência (nenhum documento de origem)
select 'sem_proveniencia', 'alta', ai.id::text, ('item ' || ai.item_ref || ' meeting ' || ai.meeting_id)
from public.agenda_items ai join public.meetings m on m.id = ai.meeting_id
where m.pauta_doc_id is null and m.ata_doc_id is null and ai.ata_doc_id is null
union all
-- 6) resultado preenchido sem ata/acórdão de origem
select 'resultado_sem_fonte', 'alta', ai.id::text, ('item ' || ai.item_ref || ' resultado=' || ai.resultado_tipo)
from public.agenda_items ai join public.meetings m on m.id = ai.meeting_id
where ai.resultado_tipo not in ('pendente','nao_aplicavel','retirado') and ai.ata_doc_id is null and m.ata_doc_id is null
union all
-- 7) agência L2 com pleito decidido e menos de 3 votos registrados (quórum mínimo)
select 'votos_incompletos', 'media', ai.id::text, (a.sigla || ' item ' || ai.item_ref || ' votos=' || count(dv.id))
from public.agenda_items ai
join public.meetings m on m.id = ai.meeting_id
join public.agencies a on a.id = m.agency_id
left join public.director_votes dv on dv.agenda_item_id = ai.id
where a.nivel_voto = 'L2' and ai.natureza = 'pleito' and ai.resultado_tipo in ('deferido','indeferido','parcial')
group by ai.id, a.sigla, ai.item_ref
having count(dv.id) < 3
union all
-- 8) voto em item ainda pendente
select 'voto_sem_resultado', 'baixa', dv.id::text, ('item ' || ai.item_ref)
from public.director_votes dv join public.agenda_items ai on ai.id = dv.agenda_item_id
where ai.resultado_tipo = 'pendente' and ai.created_at < now() - interval '7 days';

-- Acesso: views operacionais só para service_role; admins pela RPC abaixo.
revoke all on public.v_ingestion_health from public, anon, authenticated;
revoke all on public.v_dq_anomalias from public, anon, authenticated;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant select on public.v_ingestion_health, public.v_dq_anomalias to service_role;
  end if;
end $$;

create or replace function public.rpc_admin_health() returns setof public.v_ingestion_health
language sql stable security definer set search_path = public as $$
  select * from public.v_ingestion_health where public.is_platform_admin()
$$;
create or replace function public.rpc_admin_dq() returns setof public.v_dq_anomalias
language sql stable security definer set search_path = public as $$
  select * from public.v_dq_anomalias where public.is_platform_admin()
$$;
revoke all on function public.rpc_admin_health() from public;
revoke all on function public.rpc_admin_dq() from public;
grant execute on function public.rpc_admin_health() to authenticated;
grant execute on function public.rpc_admin_dq() to authenticated;

-- ---------- 5. Notificações: geração (SQL) e fila de envio (consumida pelo N8N) ----------
create or replace function public.fn_generate_notifications() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer := 0; r integer;
begin
  -- processo monitorado entrou numa pauta futura (ou de ontem em diante)
  insert into notifications (client_id, process_id, tipo, titulo, corpo, dedupe_key)
  select cp.client_id, p.id, 'na_pauta',
         'Processo ' || p.nup_normalizado || ' na pauta da ' || a.sigla,
         'Reunião ' || coalesce(m.numero::text,'?') || '/' || coalesce(m.ano::text,'') ||
           coalesce(' em ' || to_char(m.inicio at time zone 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'), '') ||
           ' — item ' || ai.item_ref || '. ' || coalesce(ai.assunto,''),
         'pauta:' || ai.id
  from agenda_items ai
  join meetings m on m.id = ai.meeting_id
  join agencies a on a.id = m.agency_id
  join processes p on p.id = ai.process_id
  join client_processes cp on cp.process_id = p.id
  where m.status in ('prevista','confirmada') and not ai.retirado_de_pauta
    and (m.inicio is null or m.inicio >= now() - interval '1 day')
  on conflict (client_id, dedupe_key) do nothing;
  get diagnostics r = row_count; n := n + r;

  -- reunião amanhã (fuso de Brasília)
  insert into notifications (client_id, process_id, tipo, titulo, corpo, dedupe_key)
  select cp.client_id, p.id, 'reuniao_amanha',
         'Amanhã: reunião da ' || a.sigla || ' com o processo ' || p.nup_normalizado,
         'Reunião ' || coalesce(m.numero::text,'?') || '/' || coalesce(m.ano::text,'') || ' às ' ||
           to_char(m.inicio at time zone 'America/Sao_Paulo','HH24:MI') || ' — item ' || ai.item_ref || '.',
         'amanha:' || m.id || ':' || to_char(m.inicio at time zone 'America/Sao_Paulo','YYYYMMDD') || ':' || p.id
  from agenda_items ai
  join meetings m on m.id = ai.meeting_id
  join agencies a on a.id = m.agency_id
  join processes p on p.id = ai.process_id
  join client_processes cp on cp.process_id = p.id
  where m.status in ('prevista','confirmada') and m.inicio is not null
    and (m.inicio at time zone 'America/Sao_Paulo')::date = (now() at time zone 'America/Sao_Paulo')::date + 1
  on conflict (client_id, dedupe_key) do nothing;
  get diagnostics r = row_count; n := n + r;

  -- novo andamento público (usa o momento da ingestão para não notificar backfill antigo)
  insert into notifications (client_id, process_id, tipo, titulo, corpo, dedupe_key)
  select cp.client_id, p.id, 'novo_andamento',
         'Novo andamento no processo ' || p.nup_normalizado,
         e.titulo || coalesce(' — ' || e.descricao, ''),
         'evento:' || e.id
  from process_events e
  join processes p on p.id = e.process_id
  join client_processes cp on cp.process_id = p.id
  where e.client_id is null and e.criado_em >= now() - interval '2 days'
  on conflict (client_id, dedupe_key) do nothing;
  get diagnostics r = row_count; n := n + r;

  -- decisão publicada (reuniões dos últimos 7 dias)
  insert into notifications (client_id, process_id, tipo, titulo, corpo, dedupe_key)
  select cp.client_id, p.id, 'decisao',
         'Decisão no processo ' || p.nup_normalizado || ' (' || a.sigla || ')',
         'Resultado: ' || ai.resultado_tipo || coalesce(' — ' || ai.resultado_texto, '') ||
           coalesce(' — Acórdão/decisão ' || ai.acordao_numero, ''),
         'decisao:' || ai.id
  from agenda_items ai
  join meetings m on m.id = ai.meeting_id
  join agencies a on a.id = m.agency_id
  join processes p on p.id = ai.process_id
  join client_processes cp on cp.process_id = p.id
  where ai.resultado_tipo in ('deferido','indeferido','parcial','nao_conhecido')
    and m.inicio >= now() - interval '7 days'
  on conflict (client_id, dedupe_key) do nothing;
  get diagnostics r = row_count; n := n + r;

  return n;
end $$;
revoke all on function public.fn_generate_notifications() from public, anon, authenticated;

create or replace function public.rpc_pending_notifications(p_limit integer default 200)
returns table (notification_id uuid, client_id uuid, client_nome text, tipo text, titulo text,
               corpo text, criado_em timestamptz, emails text[])
language sql stable security definer set search_path = public as $$
  select n.id, n.client_id, c.nome, n.tipo, n.titulo, n.corpo, n.criado_em,
         coalesce((select array_agg(cc.email) from client_contacts cc
                   where cc.client_id = n.client_id and cc.ativo), '{}'::text[])
  from notifications n join clients c on c.id = n.client_id
  where n.enviado_em is null and c.ativo
  order by n.criado_em
  limit p_limit
$$;

create or replace function public.rpc_mark_notifications_sent(p_ids uuid[]) returns integer
language plpgsql security definer set search_path = public as $$
declare r integer;
begin
  update notifications set enviado_em = now() where id = any (p_ids) and enviado_em is null;
  get diagnostics r = row_count; return r;
end $$;

revoke all on function public.rpc_pending_notifications(integer) from public, anon, authenticated;
revoke all on function public.rpc_mark_notifications_sent(uuid[]) from public, anon, authenticated;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.rpc_pending_notifications(integer) to service_role;
    grant execute on function public.rpc_mark_notifications_sent(uuid[]) to service_role;
    grant execute on function public.fn_generate_notifications() to service_role;
  end if;
end $$;

-- Agendamento (só se pg_cron estiver habilitado — no Supabase: Database > Extensions > pg_cron).
-- Gera notificações 3x/dia útil (08:00, 12:00, 17:00 BRT = 11:00, 15:00, 20:00 UTC).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('iris_gen_notifications', '0 11,15,20 * * 1-5', 'select public.fn_generate_notifications()');
  end if;
end $$;

-- ---------- 6. Endurecimento: anon não executa RPCs ----------
revoke all on function public.rpc_similar_outcome(uuid, int) from anon;
revoke all on function public.rpc_vote_history(uuid, int) from anon;
revoke all on function public.rpc_admin_health() from anon;
revoke all on function public.rpc_admin_dq() from anon;

-- ---------- 7. Resultado provisório e auditoria por amostragem ----------
-- Ex. real (ANS): "Extrato de ata ... este texto pode ser alterado em função da aprovação da minuta de Ata".
-- Pautas também são republicadas (ANVISA). Resultado só é "definitivo" depois da ata aprovada.
alter table public.agenda_items
  add column if not exists resultado_provisorio boolean not null default false;

-- Amostra aleatória de itens recentes com os links de origem, para conferência humana semanal (N8N → planilha).
create or replace function public.rpc_audit_sample(p_n integer default 20, p_dias integer default 14)
returns table (agenda_item_id uuid, agencia text, reuniao text, data_reuniao date, item_ref text, nup text,
               assunto text, relator text, resultado_tipo text, resultado_provisorio boolean,
               url_pauta text, url_ata text)
language sql stable security definer set search_path = public as $$
  select ai.id, a.sigla,
         coalesce(m.numero::text,'?') || '/' || coalesce(m.ano::text,''),
         (m.inicio at time zone 'America/Sao_Paulo')::date,
         ai.item_ref, ai.nup, ai.assunto, rel.nome, ai.resultado_tipo, ai.resultado_provisorio,
         dp.url, da.url
  from agenda_items ai
  join meetings m on m.id = ai.meeting_id
  join agencies a on a.id = m.agency_id
  left join people rel on rel.id = ai.relator_id
  left join raw_documents dp on dp.id = m.pauta_doc_id
  left join raw_documents da on da.id = coalesce(ai.ata_doc_id, m.ata_doc_id)
  where ai.created_at >= now() - make_interval(days => p_dias)
  order by random()
  limit p_n
$$;
revoke all on function public.rpc_audit_sample(integer, integer) from public, anon, authenticated;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    grant execute on function public.rpc_audit_sample(integer, integer) to service_role;
  end if;
end $$;
