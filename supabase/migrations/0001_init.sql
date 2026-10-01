-- =====================================================================
-- Circle — Migração 0001 (MVP sem IA)
-- Dono do schema: Claude Code (migrações no repositório). O Lovable NÃO altera schema.
-- Convenção: tabelas de dados públicos = leitura para usuários autenticados;
--            escrita só via service_role (coletores). Dados de cliente = RLS por client_id.
-- =====================================================================
create extension if not exists pgcrypto;
create extension if not exists pg_trgm;
create extension if not exists unaccent;

-- ---------- utilidades ----------
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

-- Normaliza NUP do SEI para NNNNN.NNNNNN/AAAA-DD (aceita com/sem pontuação)
create or replace function public.normalize_nup(raw text) returns text
language sql immutable as $$
  select case when m is null then null
              else m[1] || '.' || m[2] || '/' || m[3] || '-' || m[4] end
  from (select regexp_match(raw, '(\d{5})\.?(\d{6})/?(\d{4})-?(\d{2})') as m) t
$$;

-- ---------- cadastros ----------
create table public.agencies (
  id uuid primary key default gen_random_uuid(),
  sigla text not null unique,
  nome text not null,
  esfera text not null default 'federal' check (esfera in ('federal','estadual','municipal')),
  setor text,
  colegiado text,
  nup_prefixos text[] not null default '{}',
  nivel_voto text not null default 'L0' check (nivel_voto in ('L0','L1','L2')), -- granularidade de voto publicada (docs/04)
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.org_units (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id),
  sigla text not null,
  nome text,
  unique (agency_id, sigla)
);

create table public.people (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id),
  nome text not null,
  nome_normalizado text not null,
  cargo text,
  funcao text not null default 'diretor'
    check (funcao in ('diretor_geral','diretor','diretor_substituto','superintendente','outro')),
  unidade_id uuid references public.org_units(id),
  mandato_inicio date,
  mandato_fim date,
  bio_resumo text,
  bio_url text,
  foto_url text,
  foto_fonte text,
  fonte_url text,
  ativo boolean not null default true,
  updated_at timestamptz not null default now(),
  unique (agency_id, nome_normalizado)
);
create trigger trg_people_touch before update on public.people
  for each row execute function public.touch_updated_at();

-- ---------- rastreabilidade de coleta ----------
create table public.sources (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id),
  codigo text not null unique,               -- ex.: antaq.pautas, antt.pautas
  nome text not null,
  tipo text not null check (tipo in ('calendario','pauta','ata','acordao','dados_abertos','diretoria','dou','sei_publico','email','manual')),
  url_base text,
  metodo text not null check (metodo in ('api','csv','html','pdf','playwright','email','manual')),
  cadencia text,
  ativo boolean not null default true,
  last_ok_at timestamptz,
  last_rows integer
);

create table public.ingestion_runs (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.sources(id),
  iniciado_em timestamptz not null default now(),
  finalizado_em timestamptz,
  status text not null default 'rodando' check (status in ('rodando','ok','alerta','erro')),
  n_encontrados integer default 0,
  n_novos integer default 0,
  n_atualizados integer default 0,
  erro text
);
create index on public.ingestion_runs (source_id, iniciado_em desc);

create table public.raw_documents (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.sources(id),
  url text not null,
  sha256 text not null unique,
  mime text,
  tipo_doc text,                              -- pauta | ata | acordao | resolucao | outro
  storage_path text,
  capturado_em timestamptz not null default now(),
  paginas integer,
  texto_extraido text,
  usou_ocr boolean not null default false,
  parse_status text not null default 'pendente' check (parse_status in ('pendente','ok','parcial','erro')),
  parse_erro text
);
create index on public.raw_documents (source_id, capturado_em desc);

-- ---------- núcleo regulatório ----------
create table public.process_types (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id),
  codigo text not null,
  nome text not null,
  setor text,                                 -- Rodovia, Ferrovia, Porto...
  tema text,                                  -- Tarifa, Reequilíbrio...
  palavras_chave text[] not null default '{}',
  unique (agency_id, codigo)
);

create table public.processes (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id),
  nup text not null,
  nup_normalizado text not null unique,
  tipo_id uuid references public.process_types(id),
  assunto text,
  interessados text[] not null default '{}',
  status text not null default 'desconhecido'
    check (status in ('em_andamento','concluido','arquivado','desconhecido')),
  etapa_atual text,
  unidade_id uuid references public.org_units(id),
  relator_id uuid references public.people(id),
  aberto_em date,
  concluido_em date,
  restrito boolean not null default false,
  origem text not null default 'pauta',
  updated_at timestamptz not null default now()
);
create index on public.processes (agency_id, tipo_id);
create index on public.processes using gin (assunto gin_trgm_ops);
create trigger trg_processes_touch before update on public.processes
  for each row execute function public.touch_updated_at();

create table public.process_events (
  id uuid primary key default gen_random_uuid(),
  process_id uuid not null references public.processes(id) on delete cascade,
  client_id uuid,                             -- null = público; preenchido = visível só ao cliente (import SEI/e-mail)
  ocorrido_em timestamptz not null,
  etapa text not null default 'outros' check (etapa in
    ('autuacao','distribuicao','manifestacao','nota_tecnica','consulta_publica',
     'pauta','deliberacao','decisao','publicacao','recurso','encerramento','outros')),
  titulo text not null,
  descricao text,
  unidade_id uuid references public.org_units(id),
  doc_rotulo text,
  doc_url text,
  raw_document_id uuid references public.raw_documents(id),
  origem text not null check (origem in ('pauta','ata','dados_abertos','dou','sei_import','email','manual')),
  dedupe_hash text not null unique
);
create index on public.process_events (process_id, ocorrido_em desc);

create table public.meetings (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id),
  orgao text not null default 'diretoria',
  tipo text not null default 'ordinaria' check (tipo in ('ordinaria','extraordinaria','audiencia_publica','outra')),
  modalidade text check (modalidade in ('presencial','virtual','eletronica','hibrida')),
  numero integer,
  ano integer,
  inicio timestamptz,
  fim timestamptz,
  tema text,
  status text not null default 'prevista' check (status in ('prevista','confirmada','realizada','cancelada')),
  pauta_doc_id uuid references public.raw_documents(id),
  ata_doc_id uuid references public.raw_documents(id),
  video_url text,
  fonte_url text,
  updated_at timestamptz not null default now(),
  unique (agency_id, orgao, tipo, ano, numero)
);
create index on public.meetings (agency_id, inicio);
create trigger trg_meetings_touch before update on public.meetings
  for each row execute function public.touch_updated_at();

create table public.agenda_items (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references public.meetings(id) on delete cascade,
  process_id uuid references public.processes(id),
  nup text,
  item_ref text not null,                     -- ex.: "3.2", "2.4.10" ou ordem sequencial
  ordem integer,
  bloco text,                                 -- individual | em_bloco
  assunto text,
  relator_id uuid references public.people(id),
  unidade_id uuid references public.org_units(id),
  natureza text not null default 'outros'
    check (natureza in ('pleito','normativo','outorga_concessao','sancionador','administrativo','outros')),
  retirado_de_pauta boolean not null default false,
  resultado_tipo text not null default 'pendente'
    check (resultado_tipo in ('pendente','deferido','indeferido','parcial','nao_conhecido','retirado','outros','nao_aplicavel')),
  resultado_texto text,
  acordao_numero text,
  ata_doc_id uuid references public.raw_documents(id),
  unique (meeting_id, item_ref)
);
create index on public.agenda_items (process_id);

create table public.decisions (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id),
  tipo text not null check (tipo in ('acordao','resolucao','despacho','rdc','ren','portaria','outro')),
  numero text,
  ano integer,
  data date,
  process_id uuid references public.processes(id),
  agenda_item_id uuid references public.agenda_items(id),
  ementa text,
  doc_id uuid references public.raw_documents(id),
  unique (agency_id, tipo, ano, numero)
);

-- Votos individuais (só existe onde a fonte publica; ver docs/04 níveis L0/L1/L2)
create table public.director_votes (
  id uuid primary key default gen_random_uuid(),
  agenda_item_id uuid not null references public.agenda_items(id) on delete cascade,
  person_id uuid not null references public.people(id),
  papel text not null default 'membro' check (papel in ('relator','membro','presidente')),
  voto text not null check (voto in ('deferimento','indeferimento','abstencao','impedido','ausente','outro')),
  acompanhou_relator boolean,
  fonte_doc_id uuid references public.raw_documents(id),
  unique (agenda_item_id, person_id)
);
create index on public.director_votes (person_id);

-- ---------- clientes (multi-tenant) ----------
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.client_members (
  client_id uuid not null references public.clients(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  papel text not null default 'membro' check (papel in ('admin','membro')),
  primary key (client_id, user_id)
);
create table public.client_processes (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  process_id uuid not null references public.processes(id),
  apelido text,
  papel text not null default 'interessado' check (papel in ('parte','interessado','monitor')),
  created_at timestamptz not null default now(),
  unique (client_id, process_id)
);
create table public.client_interests (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  agency_id uuid not null references public.agencies(id),
  keyword text,                               -- null = toda a agência
  created_at timestamptz not null default now()
);
create table public.process_requests (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  nup text not null,
  status text not null default 'pendente' check (status in ('pendente','encontrado','nao_encontrado')),
  created_at timestamptz not null default now()
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete cascade,
  process_id uuid references public.processes(id),
  tipo text not null check (tipo in ('novo_andamento','na_pauta','reuniao_amanha','decisao','status_mudou')),
  titulo text not null,
  corpo text,
  dedupe_key text not null,
  criado_em timestamptz not null default now(),
  enviado_em timestamptz,
  lido_em timestamptz,
  unique (client_id, dedupe_key)
);

-- ---------- RLS ----------
create or replace function public.is_client_member(cid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.client_members cm
                 where cm.client_id = cid and cm.user_id = auth.uid())
$$;

do $$
declare t text;
begin
  -- dados públicos: leitura para autenticados
  foreach t in array array['agencies','org_units','people','process_types','processes',
                            'meetings','agenda_items','decisions','director_votes'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select to authenticated using (true)', t||'_read', t);
  end loop;
  -- infraestrutura de coleta: sem acesso para clientes (somente service_role)
  foreach t in array array['sources','ingestion_runs','raw_documents'] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

alter table public.process_events enable row level security;
create policy process_events_read on public.process_events for select to authenticated
  using (client_id is null or public.is_client_member(client_id));
create policy process_events_insert_client on public.process_events for insert to authenticated
  with check (client_id is not null and public.is_client_member(client_id) and origem in ('sei_import','manual'));

alter table public.clients enable row level security;
create policy clients_read on public.clients for select to authenticated using (public.is_client_member(id));

alter table public.client_members enable row level security;
create policy client_members_read on public.client_members for select to authenticated using (user_id = auth.uid());

alter table public.client_processes enable row level security;
create policy cp_all on public.client_processes for all to authenticated
  using (public.is_client_member(client_id)) with check (public.is_client_member(client_id));

alter table public.client_interests enable row level security;
create policy ci_all on public.client_interests for all to authenticated
  using (public.is_client_member(client_id)) with check (public.is_client_member(client_id));

alter table public.process_requests enable row level security;
create policy pr_all on public.process_requests for all to authenticated
  using (public.is_client_member(client_id)) with check (public.is_client_member(client_id));

alter table public.notifications enable row level security;
create policy notif_read on public.notifications for select to authenticated using (public.is_client_member(client_id));
create policy notif_update on public.notifications for update to authenticated
  using (public.is_client_member(client_id)) with check (public.is_client_member(client_id));

-- ---------- views para o front (security_invoker => RLS é respeitada) ----------
create view public.v_my_processes with (security_invoker = true) as
select cp.client_id, p.id as process_id, p.nup_normalizado as nup, a.sigla as agencia,
       p.assunto, p.status, p.etapa_atual, p.interessados, cp.apelido,
       pt.nome as tipo, pt.setor, pt.tema,
       u.sigla as unidade, rel.nome as relator
from public.client_processes cp
join public.processes p on p.id = cp.process_id
join public.agencies a on a.id = p.agency_id
left join public.process_types pt on pt.id = p.tipo_id
left join public.org_units u on u.id = p.unidade_id
left join public.people rel on rel.id = p.relator_id;

create view public.v_process_timeline with (security_invoker = true) as
select e.process_id, e.id as event_id, e.ocorrido_em, e.etapa, e.titulo, e.descricao,
       u.sigla as unidade, e.doc_rotulo, e.doc_url, e.origem
from public.process_events e
left join public.org_units u on u.id = e.unidade_id;

create view public.v_agenda_all with (security_invoker = true) as
select m.id as meeting_id, ai.id as agenda_item_id, a.id as agency_id, a.sigla as agencia,
       m.orgao, m.tipo as tipo_reuniao, m.numero, m.ano, m.inicio, m.status,
       ai.item_ref, ai.nup, ai.assunto, ai.process_id, ai.retirado_de_pauta,
       ai.resultado_tipo, m.tema, m.fonte_url
from public.meetings m
join public.agencies a on a.id = m.agency_id
left join public.agenda_items ai on ai.meeting_id = m.id;

create view public.v_agenda_client with (security_invoker = true) as
select cp.client_id, v.*, 'processo_monitorado'::text as relevancia
from public.client_processes cp
join public.v_agenda_all v on v.process_id = cp.process_id
union all
select ci.client_id, v.*, 'interesse'::text as relevancia
from public.client_interests ci
join public.v_agenda_all v on v.agency_id = ci.agency_id
where (v.agenda_item_id is not null or v.tipo_reuniao = 'audiencia_publica')
  and (ci.keyword is null or v.assunto ilike '%' || ci.keyword || '%' or v.tema ilike '%' || ci.keyword || '%')
  and not exists (select 1 from public.client_processes cp2
                  where cp2.client_id = ci.client_id and cp2.process_id = v.process_id);

create view public.v_kpis with (security_invoker = true) as
select c.id as client_id,
  (select count(*) from public.client_processes cp where cp.client_id = c.id)::int as processos_monitorados,
  (select count(distinct x.meeting_id) from public.v_agenda_client x
     where x.client_id = c.id and x.inicio >= now() and x.inicio < now() + interval '30 days'
       and x.status <> 'cancelada')::int as reunioes_30d
from public.clients c;

create view public.v_directors with (security_invoker = true) as
select pe.id as person_id, a.sigla as agencia, pe.nome, pe.cargo, pe.funcao, pe.mandato_inicio, pe.mandato_fim,
       pe.bio_resumo, pe.bio_url, pe.foto_url, pe.foto_fonte, pe.fonte_url, pe.ativo
from public.people pe join public.agencies a on a.id = pe.agency_id
where pe.funcao in ('diretor_geral','diretor','diretor_substituto');

-- Histórico geral de votos por diretor (janela de 3 anos; só itens do tipo "pleito" com resultado)
create view public.v_director_stats with (security_invoker = true) as
select dv.person_id,
       count(*)::int as n_processos,
       round(100.0 * count(*) filter (where dv.voto = 'deferimento') / count(*))::int as pct_deferimento,
       round(100.0 * count(*) filter (where dv.voto = 'indeferimento') / count(*))::int as pct_indeferimento,
       round(100.0 * count(*) filter (where dv.voto = 'abstencao') / count(*))::int as pct_abstencao
from public.director_votes dv
join public.agenda_items ai on ai.id = dv.agenda_item_id
join public.meetings m on m.id = ai.meeting_id
where ai.natureza = 'pleito'
  and ai.resultado_tipo in ('deferido','indeferido','parcial')
  and dv.voto in ('deferimento','indeferimento','abstencao')
  and m.inicio >= now() - interval '3 years'
group by dv.person_id;

-- ---------- RPCs (regras estatísticas sem IA; ver docs/04) ----------
create or replace function public.rpc_similar_outcome(p_process_id uuid, p_years int default 3)
returns table (n_casos int, deferidos int, indeferidos int, parciais int,
               pct_deferimento numeric, evidencia text)
language sql stable security invoker set search_path = public as $$
  with alvo as (select agency_id, tipo_id from processes where id = p_process_id and tipo_id is not null),
  base as (
    select ai.resultado_tipo
    from agenda_items ai
    join meetings m on m.id = ai.meeting_id
    join processes p on p.id = ai.process_id
    join alvo on p.agency_id = alvo.agency_id and p.tipo_id = alvo.tipo_id
    where ai.natureza = 'pleito'
      and ai.resultado_tipo in ('deferido','indeferido','parcial')
      and ai.process_id <> p_process_id
      and m.inicio >= now() - make_interval(years => p_years)
  )
  select count(*)::int,
         (count(*) filter (where resultado_tipo = 'deferido'))::int,
         (count(*) filter (where resultado_tipo = 'indeferido'))::int,
         (count(*) filter (where resultado_tipo = 'parcial'))::int,
         case when count(*) = 0 then null
              else round(100.0 * count(*) filter (where resultado_tipo = 'deferido') / count(*), 0) end,
         case when count(*) >= 30 then 'alta' when count(*) >= 10 then 'media' else 'baixa' end
  from base
$$;

create or replace function public.rpc_vote_history(p_process_id uuid, p_years int default 3)
returns table (person_id uuid, nome text, cargo text, n_casos int,
               deferimentos int, indeferimentos int, abstencoes int,
               pct_deferimento numeric, pct_indeferimento numeric, pct_abstencao numeric,
               evidencia text)
language sql stable security invoker set search_path = public as $$
  with alvo as (select agency_id, tipo_id from processes where id = p_process_id and tipo_id is not null),
  base as (
    select dv.person_id, dv.voto
    from director_votes dv
    join agenda_items ai on ai.id = dv.agenda_item_id
    join meetings m on m.id = ai.meeting_id
    join processes p on p.id = ai.process_id
    join alvo on p.agency_id = alvo.agency_id and p.tipo_id = alvo.tipo_id
    where ai.natureza = 'pleito'
      and ai.resultado_tipo in ('deferido','indeferido','parcial')
      and ai.process_id <> p_process_id
      and dv.voto in ('deferimento','indeferimento','abstencao')
      and m.inicio >= now() - make_interval(years => p_years)
  )
  select pe.id, pe.nome, pe.cargo, count(*)::int,
         (count(*) filter (where b.voto = 'deferimento'))::int,
         (count(*) filter (where b.voto = 'indeferimento'))::int,
         (count(*) filter (where b.voto = 'abstencao'))::int,
         round(100.0 * count(*) filter (where b.voto = 'deferimento') / count(*), 0),
         round(100.0 * count(*) filter (where b.voto = 'indeferimento') / count(*), 0),
         round(100.0 * count(*) filter (where b.voto = 'abstencao') / count(*), 0),
         case when count(*) >= 30 then 'alta' when count(*) >= 10 then 'media' else 'baixa' end
  from base b join people pe on pe.id = b.person_id
  group by pe.id, pe.nome, pe.cargo
$$;

revoke all on function public.rpc_similar_outcome(uuid, int) from public;
revoke all on function public.rpc_vote_history(uuid, int) from public;
grant execute on function public.rpc_similar_outcome(uuid, int) to authenticated;
grant execute on function public.rpc_vote_history(uuid, int) to authenticated;

-- ---------- seed mínimo de agências ----------
insert into public.agencies (sigla, nome, esfera, setor, colegiado, nup_prefixos) values
 ('ANEEL','Agência Nacional de Energia Elétrica','federal','Energia','Diretoria Colegiada','{48500}'),
 ('ANATEL','Agência Nacional de Telecomunicações','federal','Telecom','Conselho Diretor','{53500}'),
 ('ANP','Agência Nacional do Petróleo, Gás Natural e Biocombustíveis','federal','Petróleo e Gás','Diretoria Colegiada','{}'),
 ('ANS','Agência Nacional de Saúde Suplementar','federal','Saúde','Diretoria Colegiada','{}'),
 ('ANVISA','Agência Nacional de Vigilância Sanitária','federal','Saúde','Diretoria Colegiada','{25351}'),
 ('ANA','Agência Nacional de Águas e Saneamento Básico','federal','Saneamento','Diretoria Colegiada','{}'),
 ('ANTT','Agência Nacional de Transportes Terrestres','federal','Transportes','Diretoria Colegiada','{50500}'),
 ('ANTAQ','Agência Nacional de Transportes Aquaviários','federal','Portos e Hidrovias','Diretoria Colegiada','{50300}'),
 ('ANAC','Agência Nacional de Aviação Civil','federal','Aviação','Diretoria Colegiada','{}'),
 ('ANCINE','Agência Nacional do Cinema','federal','Audiovisual','Diretoria Colegiada','{}'),
 ('ANM','Agência Nacional de Mineração','federal','Mineração','Diretoria Colegiada','{}'),
 ('ANPD','Agência Nacional de Proteção de Dados','federal','Dados','Conselho Diretor','{00261}'),
 ('ARTESP','Agência de Transporte do Estado de São Paulo','estadual','Transportes','Conselho Diretor','{}');
