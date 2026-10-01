-- =====================================================================
-- IRIS / Circle — Teste de RLS, permissões, RPCs estatísticas e notificações
-- Como rodar: cole TODO este arquivo no SQL Editor do Supabase (ou use execute_sql do MCP / psql).
-- Tudo roda dentro de UM bloco e, no fim, lança uma exceção DE PROPÓSITO para REVERTER os dados de teste.
--   SUCESSO  => erro com a mensagem:  OK_TODOS_OS_TESTES (transação revertida de propósito)
--   FALHA    => erro com a mensagem:  FALHA: <o que falhou>
-- Não deixa nenhum dado no banco. Requer as migrações 0001 e 0002 (e 0003, se existir) aplicadas.
-- Se o INSERT em auth.users falhar no seu projeto, crie 3 usuários de teste pelo painel Auth e troque os UUIDs abaixo.
-- =====================================================================
do $$
declare
  ua   uuid := '00000000-0000-0000-0000-00000000000a';   -- usuário do cliente A
  ub   uuid := '00000000-0000-0000-0000-00000000000b';   -- usuário do cliente B
  uadm uuid := '00000000-0000-0000-0000-0000000000ff';   -- admin da plataforma
  ca   uuid := 'aaaaaaaa-0000-0000-0000-000000000001';
  cb   uuid := 'bbbbbbbb-0000-0000-0000-000000000002';
  p13 uuid; p1 uuid; n int; v numeric; t text; ok boolean;
begin
  ---------------------------------------------------------------- dados sintéticos (como dono do schema)
  insert into auth.users(id) values (ua), (ub), (uadm);
  insert into clients(id, nome) values (ca, '[TESTE] Cliente A'), (cb, '[TESTE] Cliente B');
  insert into client_members(client_id, user_id, papel) values (ca, ua, 'admin'), (cb, ub, 'admin');
  insert into client_contacts(client_id, email) values (ca, 'a@teste.invalid');
  insert into platform_admins(user_id) values (uadm);

  insert into process_types(agency_id, codigo, nome, setor, tema)
    select id, 'TESTE_REEQ', 'Reequilíbrio', 'Rodovia', 'Tarifa' from agencies where sigla = 'ANTT';
  insert into people(agency_id, nome, nome_normalizado, funcao)
    select id, '[TESTE] Dir 1', 'teste dir 1', 'diretor' from agencies where sigla = 'ANTT';
  insert into people(agency_id, nome, nome_normalizado, funcao)
    select id, '[TESTE] Dir 2', 'teste dir 2', 'diretor' from agencies where sigla = 'ANTT';

  insert into processes(agency_id, nup, nup_normalizado, tipo_id, assunto, status)
    select a.id, '50500.' || lpad((900000 + g)::text, 6, '0') || '/2024-11',
                 '50500.' || lpad((900000 + g)::text, 6, '0') || '/2024-11', pt.id, '[TESTE] Reequilíbrio ' || g, 'em_andamento'
    from agencies a join process_types pt on pt.agency_id = a.id and pt.codigo = 'TESTE_REEQ', generate_series(1, 13) g
    where a.sigla = 'ANTT';
  select id into p13 from processes where nup_normalizado = '50500.900013/2024-11';
  select id into p1  from processes where nup_normalizado = '50500.900001/2024-11';

  -- 12 reuniões passadas (processos 1..12): 9 deferidos, 3 indeferidos
  insert into meetings(agency_id, numero, ano, inicio, status)
    select a.id, 990000 + g, 2099, now() - interval '6 months' + (g || ' days')::interval, 'realizada'
    from agencies a, generate_series(1, 12) g where a.sigla = 'ANTT';
  insert into agenda_items(meeting_id, process_id, nup, item_ref, natureza, resultado_tipo, situacao)
    select m.id, p.id, p.nup_normalizado, '1.' || g, 'pleito', case when g <= 9 then 'deferido' else 'indeferido' end, 'deliberado'
    from generate_series(1, 12) g
    join meetings m on m.ano = 2099 and m.numero = 990000 + g
    join processes p on p.nup_normalizado = '50500.' || lpad((900000 + g)::text, 6, '0') || '/2024-11';
  -- Dir 1 sempre defere; Dir 2 acompanha o resultado
  insert into director_votes(agenda_item_id, person_id, voto)
    select ai.id, pe.id,
           case when pe.nome = '[TESTE] Dir 1' then 'deferimento'
                when ai.resultado_tipo = 'deferido' then 'deferimento' else 'indeferimento' end
    from agenda_items ai join meetings m on m.id = ai.meeting_id and m.ano = 2099
    cross join people pe where pe.nome like '[TESTE] Dir %';

  -- reunião de amanhã (14h, Brasília) com o processo 13
  insert into meetings(agency_id, numero, ano, inicio, status)
    select id, 990100, 2099, ((now() at time zone 'America/Sao_Paulo')::date + 1 + time '14:00') at time zone 'America/Sao_Paulo', 'confirmada'
    from agencies where sigla = 'ANTT';
  insert into agenda_items(meeting_id, process_id, nup, item_ref, natureza, assunto)
    select m.id, p13, '50500.900013/2024-11', '3.2', 'pleito', '[TESTE] Revisão de Tarifa'
    from meetings m where m.ano = 2099 and m.numero = 990100;

  insert into client_processes(client_id, process_id) values (ca, p13), (cb, p1);

  -- fontes e documento para testar saúde/qualidade
  insert into sources(agency_id, codigo, nome, tipo, metodo, sla_horas, last_ok_at)
    select id, 'teste.fonte_atrasada', '[TESTE] fonte', 'pauta', 'pdf', 24, now() - interval '3 days' from agencies where sigla = 'ANTT';
  insert into raw_documents(source_id, url, sha256, tipo_doc, esperado_n, extraido_n)
    select id, 'http://teste.invalid/ata.pdf', 'teste-sha-1', 'ata', 35, 33 from sources where codigo = 'teste.fonte_atrasada';

  ---------------------------------------------------------------- 1. normalize_nup
  if normalize_nup('50500123456/2024-78') is distinct from '50500.123456/2024-78' then raise exception 'FALHA: normalize_nup sem pontuação'; end if;
  if normalize_nup('Proc. 50300.016700/2026-57 x') is distinct from '50300.016700/2026-57' then raise exception 'FALHA: normalize_nup em texto'; end if;
  if normalize_nup('lixo') is not null then raise exception 'FALHA: normalize_nup deveria ser null'; end if;

  ---------------------------------------------------------------- 2. Cliente A (authenticated)
  perform set_config('request.jwt.claims', json_build_object('sub', ua, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  select count(*) into n from v_my_processes;
  if n <> 1 then raise exception 'FALHA: cliente A deveria ver 1 processo, viu %', n; end if;
  select count(*) into n from v_my_processes where nup = '50500.900001/2024-11';
  if n <> 0 then raise exception 'FALHA: cliente A enxerga processo do cliente B'; end if;

  select processos_monitorados into n from v_kpis;
  if n <> 1 then raise exception 'FALHA: KPI processos_monitorados=% (esperado 1)', n; end if;
  select reunioes_30d into n from v_kpis;
  if n <> 1 then raise exception 'FALHA: KPI reunioes_30d=% (esperado 1)', n; end if;

  select count(*) into n from v_agenda_client where relevancia = 'processo_monitorado';
  if n <> 1 then raise exception 'FALHA: agenda do cliente A deveria ter 1 item, tem %', n; end if;

  -- RPC: taxa de deferimento (n=12, 9 deferidos => 75%, evidência média)
  select r.n_casos, r.pct_deferimento, r.evidencia into n, v, t from rpc_similar_outcome(p13) r;
  if n <> 12 or v <> 75 or t <> 'media' then raise exception 'FALHA: rpc_similar_outcome (n=%, pct=%, evid=%)', n, v, t; end if;

  -- RPC: histórico por diretor (Dir 1 = 100%, Dir 2 = 75%)
  select pct_deferimento into v from rpc_vote_history(p13) where nome = '[TESTE] Dir 1';
  if v is distinct from 100 then raise exception 'FALHA: Dir 1 deveria ter 100%%, tem %', v; end if;
  select pct_deferimento into v from rpc_vote_history(p13) where nome = '[TESTE] Dir 2';
  if v is distinct from 75 then raise exception 'FALHA: Dir 2 deveria ter 75%%, tem %', v; end if;

  -- importação privada de andamento: A grava o próprio, B não vê, A não grava em nome de B
  insert into process_events(process_id, client_id, ocorrido_em, etapa, titulo, origem, dedupe_hash)
    values (p13, ca, now(), 'nota_tecnica', '[TESTE] NT importada', 'sei_import', 'teste-evt-A');
  begin
    insert into process_events(process_id, client_id, ocorrido_em, etapa, titulo, origem, dedupe_hash)
      values (p13, cb, now(), 'outros', '[TESTE] forjado', 'sei_import', 'teste-evt-forjado');
    raise exception 'FALHA: cliente A conseguiu gravar andamento em nome do cliente B';
  exception when insufficient_privilege then null; end;

  -- views/funções operacionais bloqueadas para cliente
  begin perform * from v_ingestion_health; raise exception 'FALHA: cliente leu v_ingestion_health';
  exception when insufficient_privilege then null; end;
  begin perform * from v_dq_anomalias; raise exception 'FALHA: cliente leu v_dq_anomalias';
  exception when insufficient_privilege then null; end;
  begin perform fn_generate_notifications(); raise exception 'FALHA: cliente executou fn_generate_notifications';
  exception when insufficient_privilege then null; end;
  begin perform * from rpc_pending_notifications(); raise exception 'FALHA: cliente leu a fila de notificações';
  exception when insufficient_privilege then null; end;
  begin perform * from rpc_audit_sample(); raise exception 'FALHA: cliente executou rpc_audit_sample';
  exception when insufficient_privilege then null; end;
  select count(*) into n from rpc_admin_health();
  if n <> 0 then raise exception 'FALHA: cliente comum viu % linhas em rpc_admin_health', n; end if;

  -- tabelas de coleta: sem policy => cliente vê 0 linhas
  select count(*) into n from raw_documents; if n <> 0 then raise exception 'FALHA: cliente leu raw_documents'; end if;
  select count(*) into n from sources;       if n <> 0 then raise exception 'FALHA: cliente leu sources'; end if;
  select count(*) into n from platform_admins; if n <> 0 then raise exception 'FALHA: cliente leu platform_admins'; end if;

  ---------------------------------------------------------------- 3. Cliente B
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', ub, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  select count(*) into n from v_my_processes where nup = '50500.900013/2024-11';
  if n <> 0 then raise exception 'FALHA: cliente B enxerga processo do cliente A'; end if;
  select count(*) into n from v_process_timeline where titulo = '[TESTE] NT importada';
  if n <> 0 then raise exception 'FALHA: cliente B enxerga andamento importado pelo cliente A'; end if;

  ---------------------------------------------------------------- 4. anon
  execute 'reset role';
  execute 'set local role anon';
  select count(*) into n from processes;
  if n <> 0 then raise exception 'FALHA: anon enxerga processos'; end if;
  begin perform * from rpc_vote_history(p13); raise exception 'FALHA: anon executou rpc_vote_history';
  exception when insufficient_privilege then null; end;

  ---------------------------------------------------------------- 5. Admin da plataforma
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', uadm, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  select count(*) into n from rpc_admin_health() where codigo = 'teste.fonte_atrasada' and atrasada;
  if n <> 1 then raise exception 'FALHA: admin não vê a fonte atrasada via rpc_admin_health'; end if;
  select count(*) into n from rpc_admin_dq() where regra = 'contagem_divergente';
  if n < 1 then raise exception 'FALHA: admin não vê contagem_divergente via rpc_admin_dq'; end if;

  ---------------------------------------------------------------- 6. service_role (coletores / N8N)
  execute 'reset role';
  execute 'set local role service_role';
  select count(*) into n from v_ingestion_health where codigo = 'teste.fonte_atrasada' and atrasada;
  if n <> 1 then raise exception 'FALHA: service_role não vê v_ingestion_health'; end if;
  select count(*) into n from v_dq_anomalias where regra = 'contagem_divergente';
  if n < 1 then raise exception 'FALHA: service_role não vê anomalia de contagem'; end if;

  -- geração de notificações: 2 para o cliente A (na pauta + reunião amanhã) e idempotente
  perform fn_generate_notifications();
  select count(*) into n from notifications where client_id = ca;
  if n <> 2 then raise exception 'FALHA: esperadas 2 notificações do cliente A, geradas %', n; end if;
  select fn_generate_notifications() into n;
  if n <> 0 then raise exception 'FALHA: geração de notificações não é idempotente (gerou % na 2ª vez)', n; end if;

  -- fila de envio: traz o e-mail do contato; marcar enviadas zera a fila do cliente A
  select count(*) into n from rpc_pending_notifications() where client_id = ca and emails = array['a@teste.invalid'];
  if n <> 2 then raise exception 'FALHA: fila do cliente A deveria ter 2 itens com e-mail, tem %', n; end if;
  perform rpc_mark_notifications_sent(array(select notification_id from rpc_pending_notifications() where client_id = ca));
  select count(*) into n from rpc_pending_notifications() where client_id = ca;
  if n <> 0 then raise exception 'FALHA: fila do cliente A deveria estar vazia após o envio'; end if;

  -- amostra de auditoria devolve itens com NUP
  select count(*) into n from rpc_audit_sample(50, 365) where nup like '50500.9000%';
  if n < 1 then raise exception 'FALHA: rpc_audit_sample não devolveu itens de teste'; end if;

  execute 'reset role';
  raise exception 'OK_TODOS_OS_TESTES (transação revertida de propósito)';
end $$;
