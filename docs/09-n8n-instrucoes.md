# 09 — N8N: instruções para o Claude Code construir os workflows

## 0. Papel do N8N nesta arquitetura (decisão revisada após pesquisa)
O N8N **não** processa documentos nem contém regra de negócio. Ele faz 4 coisas que ele faz bem:
1. **Agendar** as coletas (dispara o GitHub Actions) — porque o cron do GitHub **não é confiável** (atrasos de dezenas de minutos, sem garantia de horário; desativação automática por inatividade em repositórios públicos) ✅.
2. **Vigiar** (watchdog): detectar fonte atrasada, coleta com erro ou zero registros.
3. **Enviar** e-mails de notificação e relatórios de qualidade.
4. **Borda de entrada**: e-mails do SEI encaminhados pelos clientes (fase 2).

A lógica (parsers, regras, estatística) fica em Python/SQL versionados e testados. O GitHub Actions continua com um cron **de reserva** (coleta é idempotente; rodar 2× é inofensivo).

## 1. Estado real da instância (lido em 01/out/2026, somente leitura)
| Item | Valor |
|---|---|
| Projeto (pessoal) | `v9QNbZ9D7sqGvLo4` |
| **Pasta "Regulação"** | `jGayRhzwfjhWjIZk` (vazia — todos os workflows do Circle vão aqui) |
| Outra pasta | "Construtora" (`ivMZWQsD08Bqg36O`) — **não tocar** |
| Workflows existentes (outros projetos) | "Ingestão - Controle de Caixa", "Ingestão - Operacional Sabesp", "Ingestão - Gestão da Empresa" — **não tocar** |
| Credenciais existentes | apenas `Google Drive account` e `Google Sheets account` (OAuth2) |
| Planos | projetos de equipe habilitados |

⚠️ **Não existem credenciais de Supabase, GitHub nem e-mail.** O MCP do N8N só **lista** credenciais; **não cria**. O usuário as cria na interface (seção 3) antes dos workflows.

## 2. Orçamento de execuções (importante)
O N8N Cloud cobra por **execução de workflow** (não por nó): Starter ≈ 2.500/mês, Pro ≈ 10.000/mês, e **os workflows pausam ao atingir o limite** ✅ (valores de mercado, ⚠️ conferir seu plano; "variáveis globais" só no Pro). Os 3 workflows "Ingestão" existentes também consomem a cota.
**Regras:** nada de polling a cada poucos minutos; agendamentos em horários fixos; uma execução faz o trabalho de todas as agências (loop interno).

| Workflow | Frequência | Execuções/mês (22 dias úteis) |
|---|---|---|
| REG-01 Disparo de coletas | 4×/dia útil | ≈ 88 |
| REG-02 Watchdog | a cada 2 h, 08–20h | ≈ 154 |
| REG-03 Envio de notificações | 3×/dia útil | ≈ 66 |
| REG-04 Relatório de qualidade | 1×/dia útil | ≈ 22 |
| REG-05 Auditoria semanal | 1×/semana | ≈ 4 |
| REG-07 E-mails SEI (fase 2) | 1×/dia útil | ≈ 22 |
| REG-00 Erros / REG-06 Backfill | eventual / manual | ≈ 20 |
| **Total estimado** | | **≈ 380** |

**Dead-man's switch fora do N8N:** se o N8N pausar (cota) ou cair, o `healthcheck.yml` do GitHub (diário) falha e o GitHub avisa por e-mail. Ver `.github/workflows/healthcheck.yml`.

## 3. Pré-requisitos (o usuário faz; o Claude Code confere com `list_credentials`)
Criar no N8N → *Credentials* (nomes exatos, para os workflows referenciarem):
| Nome | Tipo | Conteúdo |
|---|---|---|
| `supabase-iris-staging` | Supabase API (ou Header Auth) | URL do projeto + **service_role** do **staging** (nunca expor no front) |
| `github-iris-dispatch` | GitHub API / Header Auth | PAT *fine-grained* restrito ao repositório `CIRCLE-NEW`, permissão **Actions: Read and write** (+ Metadata: read) |
| `email-iris-alertas` | Gmail OAuth2 **ou** SMTP | Piloto: Gmail. Produção: SMTP transacional com SPF/DKIM do domínio (entregabilidade) |
| `Google Sheets account` | (já existe) | Planilha "Circle — Auditoria" (REG-05) |
Só depois disso o Claude Code cria os workflows. **Nenhum segredo em código, em nó "Set" ou em log.**

Config não secreta fica em um nó **Set** chamado `Config` no início de cada workflow: `SUPABASE_URL`, `GITHUB_OWNER`, `GITHUB_REPO`, `ADMIN_EMAILS`, `APP_URL`. (Sem depender de variáveis globais do plano Pro.)

## 4. Como o Claude Code deve trabalhar (ordem obrigatória)
1. `get_instance_context` + `search_projects` + `search_folders` (confirmar IDs da seção 1) + `list_credentials`.
2. `get_workflow_best_practices` e `get_workflow_sdk_reference` (planejamento obrigatório antes de qualquer criação).
3. `search_nodes` / `get_node_types` / `validate_node_config` para: Schedule Trigger, HTTP Request, Code, IF, Split In Batches/Loop, Wait, Send Email/Gmail, Google Sheets, Error Trigger, Manual Trigger. Conferir como autenticar o HTTP Request com a credencial Supabase (tipo predefinido ou cabeçalhos `apikey` + `Authorization: Bearer`).
4. Para cada workflow: escrever o código SDK → `validate_workflow` → `create_workflow_from_code` com `projectId=v9QNbZ9D7sqGvLo4` e `folderId=jGayRhzwfjhWjIZk`, `versionName` preenchido.
5. Testar com `prepare_workflow_pin_data` + `test_workflow` (dados "pinados": sem chamar serviços reais).
6. **Criar INATIVOS.** Só `publish_workflow` depois da aprovação explícita do usuário (e depois de a migração 0002 + os secrets do GitHub existirem).
7. Definir o **REG-00** como *Error Workflow* dos demais (via `update_workflow`).
8. Ao terminar, informar projeto + pasta onde cada workflow caiu, e listar o que ficou pendente.
**Convenções:** nome `REG-0X · Descrição`; timezone do workflow `America/Sao_Paulo`; tag `iris`; um nó `Config` por workflow; nós com nomes descritivos; sem nós órfãos.
**Proibido:** alterar/excluir workflows fora da pasta Regulação; usar credenciais que não sejam as listadas; gravar e-mail de cliente em log.

## 5. Contratos com o Supabase (HTTP Request, `Prefer`/`Accept-Profile` padrão)
Base: `{SUPABASE_URL}/rest/v1`. Headers: `apikey: <service_role>`, `Authorization: Bearer <service_role>`, `Content-Type: application/json`.
| Uso | Chamada |
|---|---|
| Fontes ativas | `GET /sources?select=codigo,agencies(sigla)&ativo=eq.true` |
| Saúde das coletas | `GET /v_ingestion_health?or=(atrasada.eq.true,ultimo_status.in.(erro,alerta))` |
| Anomalias | `GET /v_dq_anomalias?select=*&order=severidade.asc` |
| Fila de e-mails | `POST /rpc/rpc_pending_notifications` body `{"p_limit":200}` |
| Marcar enviadas | `POST /rpc/rpc_mark_notifications_sent` body `{"p_ids":["uuid",...]}` |
| Amostra de auditoria | `POST /rpc/rpc_audit_sample` body `{"p_n":20,"p_dias":14}` |
Erros: 4xx/5xx → o workflow **falha** (não engole erro) para cair no REG-00.

## 6. Especificação dos workflows

### REG-00 · Tratamento de erros
- **Gatilho:** Error Trigger.
- **Faz:** monta e-mail para `ADMIN_EMAILS` com nome do workflow, nó que falhou, mensagem de erro (sem dados de cliente) e link da execução.
- **Aceite:** forçar erro em REG-01 de teste → e-mail chega.

### REG-01 · Disparo de coletas
- **Gatilho:** Schedule `0 8,12,16,20 * * 1-5` (America/Sao_Paulo). Mais: execução manual para teste.
- **Fluxo:** `Config` → GET fontes ativas → agrupar por agência (`sigla`) → para cada agência: `POST https://api.github.com/repos/{owner}/{repo}/actions/workflows/collect.yml/dispatches` com headers `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`, credencial `github-iris-dispatch`, body `{"ref":"main","inputs":{"agency":"<SIGLA>"}}` (resposta esperada **204**) → `Wait` 5 s entre agências.
- **Aceite:** execução manual dispara o workflow no GitHub e aparece na aba Actions; agência sem fonte ativa não dispara.
- **Nota:** `collect.yml` deve ter `concurrency` por agência para não sobrepor execuções.

### REG-02 · Watchdog de coletas
- **Gatilho:** Schedule `0 8-20/2 * * 1-5`.
- **Fluxo:** GET `v_ingestion_health` filtrado (atrasada ou último status erro/alerta) → se vazio, **encerra sem e-mail** → senão, **Code** com `$getWorkflowStaticData('global')` para só reenviar alerta da mesma fonte após 6 h → e-mail resumo (fonte, agência, horas desde OK, último erro, issues abertos).
- **Aceite:** forçar `last_ok_at` antigo numa fonte de teste → 1 e-mail; segundo ciclo em < 6 h → nenhum e-mail.

### REG-03 · Envio de notificações aos clientes
- **Gatilho:** Schedule `15 8,12,17 * * 1-5` (o `pg_cron` do Supabase gera as notificações às 08:00, 12:00 e 17:00 BRT).
- **Fluxo:** `POST rpc_pending_notifications` → se vazio, encerra → **Code**: agrupar por `client_id`; montar **um e-mail-resumo por cliente** (assunto: `Circle · N atualizações regulatórias`; corpo: lista de `titulo` + `corpo`, link `APP_URL`; rodapé com aviso legal de `docs/06`) → **Send Email** para `emails[]` do cliente (cliente sem e-mail: pular e **não** marcar) → **somente após envio OK**: `POST rpc_mark_notifications_sent` com os ids daquele cliente.
- **Aceite:** com 2 notificações de teste → 1 e-mail por cliente e `enviado_em` preenchido; reexecução não reenvia; falha de SMTP não marca como enviada.

### REG-04 · Relatório diário de qualidade
- **Gatilho:** Schedule `30 7 * * 1-5`.
- **Fluxo:** GET `v_dq_anomalias` + `v_ingestion_health` → Code resume contagens por `regra`/`severidade` e lista as 20 mais graves → **só envia se** houver severidade `alta` ou fonte atrasada (segunda-feira envia resumo mesmo sem problema) → e-mail `ADMIN_EMAILS`.
- **Aceite:** inserir anomalia de teste `contagem_divergente` → e-mail com a linha.

### REG-05 · Auditoria semanal por amostragem
- **Gatilho:** Schedule `0 9 * * 1`.
- **Fluxo:** `POST rpc_audit_sample` (20 itens) → **Google Sheets** (credencial existente) → anexar linhas na planilha **"Circle — Auditoria"** (aba `amostras`) com colunas: data, agência, reunião, item, NUP, assunto, relator, resultado, provisório?, URL pauta, URL ata, **[revisor: NUP ok? relator ok? resultado ok? obs]** (colunas em branco) → e-mail ao revisor com o link da planilha.
- **Aceite:** 20 linhas novas por semana; colunas do revisor vazias; a taxa de acerto semanal é calculada na planilha (meta em `docs/10`).

### REG-06 · Backfill controlado (manual)
- **Gatilho:** Manual (com campos `agency`, `data_inicio`, `data_fim`).
- **Fluxo:** gera lista de meses → para cada mês `POST` dispatch em `backfill.yml` (inputs `agency`, `from`, `to`) → `Wait` 90 s → resumo final por e-mail.
- **Regra:** 1 agência por vez; teto de meses por execução = 6; nunca em horário comercial.
- (O `backfill.yml` é criado pelo Claude Code no Sprint de cada coletor.)

### REG-07 · Ingestão de e-mails do SEI (**fase 2 — não construir antes de ter amostras**)
- **Contexto:** o SEI envia e-mail automático ao usuário externo quando há liberação de acesso externo, intimação eletrônica ou documento para assinatura, informando o **número do processo** ✅. O formato exato varia por agência ⚠️.
- **Pré-requisito:** o usuário fornece **3+ e-mails reais anonimizados por agência** e define a caixa/etiqueta de ingestão por cliente (ex.: endereço dedicado com *plus-addressing* ou etiqueta do Gmail).
- **Fluxo (lote diário 07:00):** Gmail (etiqueta `SEI/Circle`, não lidos) → Code: extrair NUP (regex de `docs/03`), tipo (intimação/acesso liberado/assinatura) e data → mapear cliente pela caixa/etiqueta → `POST /process_events` (`client_id` preenchido, `origem='email'`, `etapa='outros'`, título "Intimação eletrônica recebida", **sem corpo do e-mail**) + criar `processes`/`client_processes` se ainda não existir → marcar e-mail como processado.
- **LGPD:** guardar **só** NUP, tipo e data; descartar corpo/anexos; o cliente autoriza expressamente o encaminhamento.
- **Tabela de apoio** (criar em migração futura): `client_inboxes(client_id, identificador, ativo)`.

## 7. Entregáveis do Claude Code para o N8N
1. Workflows REG-00 a REG-06 **criados inativos** na pasta *Regulação*, com testes de pin data.
2. `docs/n8n/` com: diagrama de cada workflow, credenciais usadas (nomes, não valores), horários, contratos de chamada e como reproduzir o teste.
3. Lista do que depende do usuário (credenciais, planilha, PAT, e-mails de amostra).
4. Relatório de **execuções estimadas por mês** com o plano real do usuário.
