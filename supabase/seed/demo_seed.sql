-- Circle — SEED DE DEMONSTRAÇÃO (somente STAGING). Tudo fictício e marcado:
--   agências 'DEMO-A'/'DEMO-B', NUPs 99999.*, pessoas '[DEMO] Diretor A/B/C', cliente '[DEMO] CS Infra', URLs demo.invalid.
-- Remover tudo: supabase/seed/demo_cleanup.sql. Requer os 2 usuários já criados no Auth.
-- Consistência: 40 pleitos "semelhantes" (28 deferidos, 10 indeferidos, 2 parciais) + 20 de outro tipo (recurso);
-- cada diretor vota em <= 40 casos semelhantes e o resultado de cada item respeita a maioria dos votos.
do $$
declare
  cid uuid := '99999999-0000-0000-0000-000000000001';
  ag_a uuid; ag_b uuid; src_a uuid; src_b uuid; u_admin uuid; u_user uuid;
  pt_rev uuid; pt_rec uuid; pt_arr uuid; ou_a uuid; ou_b uuid;
  dirs uuid[]; p0 uuid; p1 uuid; p2 uuid; pid uuid;
  m int; g int; res text; mid uuid; adoc uuid; pdoc uuid; iid uuid; v text; i int;
begin
  select id into u_admin from auth.users where email = 'joaodsouzanery@gmail.com';
  select id into u_user  from auth.users where email = 'joaoneryflu@gmail.com';
  if exists (select 1 from agencies where sigla = 'DEMO-A') then raise exception 'Seed demo já aplicado (rode demo_cleanup.sql antes)'; end if;

  insert into agencies(sigla, nome, esfera, setor, colegiado, nup_prefixos, nivel_voto) values
    ('DEMO-A','[DEMO] Agência de Demonstração A','federal','Transportes','Diretoria Colegiada','{99999}','L2'),
    ('DEMO-B','[DEMO] Agência de Demonstração B','federal','Portos e Hidrovias','Diretoria Colegiada','{99999}','L1');
  select id into ag_a from agencies where sigla = 'DEMO-A';
  select id into ag_b from agencies where sigla = 'DEMO-B';

  insert into sources(agency_id, codigo, nome, tipo, metodo, last_ok_at, last_rows) values
    (ag_a,'demo.pautas_a','[DEMO] Pautas A','pauta','manual', now(), 60),
    (ag_b,'demo.pautas_b','[DEMO] Pautas B','pauta','manual', now(), 1);
  select id into src_a from sources where codigo = 'demo.pautas_a';
  select id into src_b from sources where codigo = 'demo.pautas_b';

  insert into org_units(agency_id, sigla, nome) values (ag_a,'SUROD-DEMO','[DEMO] Superintendência de Rodovias'), (ag_b,'SUPORT-DEMO','[DEMO] Superintendência de Portos');
  select id into ou_a from org_units where agency_id = ag_a; select id into ou_b from org_units where agency_id = ag_b;

  insert into people(agency_id, nome, nome_normalizado, cargo, funcao, mandato_inicio, mandato_fim, bio_resumo) values
    (ag_a,'[DEMO] Diretor A','demo diretor a','Diretor-Geral - DEMO-A','diretor_geral','2023-01-10','2027-01-09','[DEMO] Biografia fictícia, apenas para demonstrar o layout. Não representa pessoa real.'),
    (ag_a,'[DEMO] Diretor B','demo diretor b','Diretor - DEMO-A','diretor','2022-03-01','2026-12-31','[DEMO] Biografia fictícia, apenas para demonstrar o layout. Não representa pessoa real.'),
    (ag_a,'[DEMO] Diretor C','demo diretor c','Diretor - DEMO-A','diretor','2024-02-15','2028-02-14','[DEMO] Biografia fictícia, apenas para demonstrar o layout. Não representa pessoa real.');
  select array_agg(id order by nome) into dirs from people where agency_id = ag_a;  -- [A, B, C]

  insert into process_types(agency_id, codigo, nome, setor, tema) values
    (ag_a,'REV_TARIFA','Revisão de tarifa','Rodovia','Tarifa'),
    (ag_a,'RECURSO','Recurso administrativo','Rodovia','Recurso'),
    (ag_b,'ARRENDAMENTO','Arrendamento portuário','Porto','Arrendamento');
  select id into pt_rev from process_types where agency_id = ag_a and codigo = 'REV_TARIFA';
  select id into pt_rec from process_types where agency_id = ag_a and codigo = 'RECURSO';
  select id into pt_arr from process_types where agency_id = ag_b and codigo = 'ARRENDAMENTO';

  -- processos monitorados
  insert into processes(agency_id,nup,nup_normalizado,tipo_id,assunto,interessados,status,etapa_atual,unidade_id,relator_id,aberto_em,origem) values
    (ag_a,'99999.123456/2024-78','99999.123456/2024-78',pt_rev,'[DEMO] Concessão Rodoviária – Revisão de Tarifa','{"[DEMO] CS Infra"}','em_andamento','deliberacao',ou_a,dirs[2], current_date-47,'pauta'),
    (ag_a,'99999.987654/2024-11','99999.987654/2024-11',pt_rev,'[DEMO] Reequilíbrio Contratual','{"[DEMO] CS Infra"}','em_andamento','manifestacao',ou_a,dirs[3], current_date-90,'pauta'),
    (ag_b,'99999.555000/2025-33','99999.555000/2025-33',pt_arr,'[DEMO] Arrendamento Portuário','{"[DEMO] CS Infra"}','em_andamento','nota_tecnica',ou_b,null, current_date-60,'pauta');
  select id into p0 from processes where nup_normalizado = '99999.123456/2024-78';
  select id into p1 from processes where nup_normalizado = '99999.987654/2024-11';
  select id into p2 from processes where nup_normalizado = '99999.555000/2025-33';

  -- histórico: 15 reuniões realizadas (com pauta e ata), 60 pleitos decididos (1-40 revisão de tarifa; 41-60 recurso)
  for m in 1..15 loop
    insert into raw_documents(source_id,url,sha256,mime,tipo_doc,parse_status,parser_version) values
      (src_a,'https://demo.invalid/pauta/'||m,'demo-pauta-'||m,'application/pdf','pauta','ok','demo') returning id into pdoc;
    insert into raw_documents(source_id,url,sha256,mime,tipo_doc,parse_status,parser_version) values
      (src_a,'https://demo.invalid/ata/'||m,'demo-ata-'||m,'application/pdf','ata','ok','demo') returning id into adoc;
    insert into meetings(agency_id,orgao,tipo,numero,ano,inicio,status,pauta_doc_id,ata_doc_id,fonte_url,modalidade)
      values (ag_a,'diretoria','ordinaria',m, extract(year from now() - (16-m)*interval '20 days')::int, now() - (16-m)*interval '20 days','realizada',pdoc,adoc,'https://demo.invalid/pauta/'||m,'presencial');
  end loop;

  for g in 1..60 loop
    if g <= 40 then
      res := case when g % 4 = 0 then 'indeferido' when g in (5,25) then 'parcial' else 'deferido' end;
    else
      res := case when g % 3 = 0 then 'indeferido' else 'deferido' end;
    end if;
    insert into processes(agency_id,nup,nup_normalizado,tipo_id,assunto,interessados,status,etapa_atual,unidade_id,origem)
      values (ag_a,'99999.'||lpad((100000+g)::text,6,'0')||'/2025-'||lpad(g::text,2,'0'),'99999.'||lpad((100000+g)::text,6,'0')||'/2025-'||lpad(g::text,2,'0'),
              case when g<=40 then pt_rev else pt_rec end,'[DEMO] Processo histórico '||g,'{"[DEMO] Empresa"}','concluido','encerramento',ou_a,'pauta')
      returning id into pid;
    select id, ata_doc_id into mid, adoc from meetings where agency_id = ag_a and numero = (g-1)/4 + 1;
    insert into agenda_items(meeting_id,process_id,nup,item_ref,natureza,assunto,relator_id,unidade_id,resultado_tipo,situacao,acordao_numero)
      values (mid,pid,(select nup from processes where id=pid),'1.'||((g-1)%4+1),'pleito','[DEMO] Processo histórico '||g,dirs[g%3+1],ou_a,res,'deliberado','DEMO '||g||'/2026')
      returning id into iid;
    for i in 1..3 loop
      v := null;
      if g <= 40 then
        if i = 1 then v := case when g in (13,26) then 'abstencao' when res = 'indeferido' then 'indeferimento' else 'deferimento' end;
        elsif i = 2 then if g not in (1,2) then v := case when res = 'indeferido' and g % 8 <> 0 then 'indeferimento' else 'deferimento' end; end if;
        else if g not in (10,20,30) then v := case when res = 'indeferido' then 'indeferimento' when g % 3 = 0 then 'indeferimento' else 'deferimento' end; end if;
        end if;
      else
        v := case when res = 'indeferido' then 'indeferimento'
                  when i = 3 and g % 2 = 0 then 'indeferimento' else 'deferimento' end;
      end if;
      if v is not null then
        insert into director_votes(agenda_item_id,person_id,papel,voto,fonte_doc_id)
          values (iid, dirs[i], case when i = g%3+1 then 'relator' else 'membro' end, v, adoc);
      end if;
    end loop;
  end loop;

  -- reuniões futuras (todas com pauta demo) e itens
  insert into raw_documents(source_id,url,sha256,mime,tipo_doc,parse_status,parser_version)
    select src_a,'https://demo.invalid/pauta/'||n,'demo-pauta-'||n,'application/pdf','pauta','ok','demo' from generate_series(16,20) n;
  insert into raw_documents(source_id,url,sha256,mime,tipo_doc,parse_status,parser_version)
    values (src_b,'https://demo.invalid/pauta-b/1','demo-pauta-b-1','application/pdf','pauta','ok','demo');

  insert into meetings(agency_id,orgao,tipo,numero,ano,inicio,status,pauta_doc_id,fonte_url,tema,modalidade)
  select ag_a,'diretoria','ordinaria',16,extract(year from now()+interval '4 days')::int,date_trunc('day',now())+interval '4 days 13 hours','confirmada',(select id from raw_documents where sha256='demo-pauta-16'),'https://demo.invalid/pauta/16',null,'presencial'
  union all select ag_a,'diretoria','ordinaria',17,extract(year from now()+interval '18 days')::int,date_trunc('day',now())+interval '18 days 13 hours','prevista',(select id from raw_documents where sha256='demo-pauta-17'),'https://demo.invalid/pauta/17',null,'presencial'
  union all select ag_b,'diretoria','ordinaria',1,extract(year from now()+interval '20 days')::int,date_trunc('day',now())+interval '20 days 13 hours','prevista',(select id from raw_documents where sha256='demo-pauta-b-1'),'https://demo.invalid/pauta-b/1',null,'virtual'
  union all select ag_a,'audiência pública','audiencia_publica',19,extract(year from now()+interval '27 days')::int,date_trunc('day',now())+interval '27 days 13 hours','prevista',(select id from raw_documents where sha256='demo-pauta-19'),'https://demo.invalid/pauta/19','[DEMO] Modernização de Concessões Rodoviárias','virtual'
  union all select ag_a,'diretoria','ordinaria',20,extract(year from now()+interval '34 days')::int,date_trunc('day',now())+interval '34 days 13 hours','prevista',(select id from raw_documents where sha256='demo-pauta-20'),'https://demo.invalid/pauta/20',null,'presencial';

  insert into agenda_items(meeting_id,process_id,nup,item_ref,natureza,assunto,relator_id,unidade_id)
  select m.id, p0,'99999.123456/2024-78','3.2','pleito','[DEMO] Revisão de Tarifa',dirs[2],ou_a from meetings m where m.agency_id=ag_a and m.numero=16
  union all select m.id, p1,'99999.987654/2024-11','1.4','pleito','[DEMO] Reequilíbrio Contratual',dirs[3],ou_a from meetings m where m.agency_id=ag_a and m.numero=17
  union all select m.id, p2,'99999.555000/2025-33','2.1','pleito','[DEMO] Arrendamento Portuário',null,ou_b from meetings m where m.agency_id=ag_b and m.numero=1
  union all select m.id, null,null,'4.3','administrativo','[DEMO] Revisão Ordinária',null,ou_a from meetings m where m.agency_id=ag_a and m.numero=20;

  -- andamentos do processo principal (os de SEI são "importados", visíveis só ao cliente)
  insert into process_events(process_id,client_id,ocorrido_em,etapa,titulo,descricao,unidade_id,doc_rotulo,doc_url,raw_document_id,origem,dedupe_hash)
  select p0,null::uuid, now()-interval '47 days','autuacao','Autuação','[DEMO] Processo autuado na agência',ou_a,'Processo inicial','https://demo.invalid/proc/inicial',null::uuid,'dados_abertos','demo-ev-1'
  union all select p0,null, now()-interval '42 days','distribuicao','Distribuição','[DEMO] Processo distribuído ao [DEMO] Diretor B',ou_a,'Despacho','https://demo.invalid/proc/despacho',null,'dados_abertos','demo-ev-2'
  union all select p0,cid, now()-interval '26 days','manifestacao','Manifestação','[DEMO] Manifestação da área técnica',ou_a,'Parecer técnico','https://demo.invalid/proc/parecer',null,'sei_import','demo-ev-3'
  union all select p0,cid, now()-interval '19 days','nota_tecnica','Nota técnica','[DEMO] Nota Técnica SEI 234/2026/SUROD-DEMO',ou_a,'NT 234/2026','https://demo.invalid/proc/nt',null,'sei_import','demo-ev-4'
  union all select p0,null, now()-interval '3 days','deliberacao','Deliberação','[DEMO] Incluído na pauta da Reunião de Diretoria nº 16',ou_a,'Pauta RD nº 16','https://demo.invalid/pauta/16',(select id from raw_documents where sha256='demo-pauta-16'),'pauta','demo-ev-5';

  -- cliente de demonstração
  insert into clients(id, nome) values (cid, '[DEMO] CS Infra');
  insert into client_processes(client_id, process_id, apelido) values (cid,p0,'[DEMO] Revisão de tarifa'),(cid,p1,'[DEMO] Reequilíbrio'),(cid,p2,'[DEMO] Arrendamento');
  insert into client_interests(client_id, agency_id) values (cid, ag_a), (cid, ag_b);
  if u_admin is not null then
    insert into client_members(client_id,user_id,papel) values (cid,u_admin,'admin');
    insert into platform_admins(user_id) values (u_admin) on conflict do nothing;
  end if;
  if u_user is not null then insert into client_members(client_id,user_id,papel) values (cid,u_user,'membro'); end if;
  -- (sem client_contacts de propósito: o demo não deve disparar e-mails)
end $$;
