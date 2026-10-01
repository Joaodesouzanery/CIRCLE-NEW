# 02 — Telas e widgets (o que levar, de onde vem cada dado)

Baseado no mockup "Circle — Better Regulation". Todos os widgets leem **views `v_*` ou RPCs** (ver `0001_init.sql`).
Cabeçalho global: seletor de cliente (ex.: "CS Infra"), sino de notificações (`notifications`), avatar/logout.
Menu: **Meus Processos · Agenda Regulatória · Agências e Diretores · Configurações**.

---
## TELA 1 — Meus Processos (página inicial)

### W1.1 Consultar Processo
- **Entrada:** campo NUP com máscara `NNNNN.NNNNNN/AAAA-DD`; validar com `normalize_nup`.
- **Fluxo:**
  1. Achou em `processes` → seleciona e carrega W1.4–W1.8. Se ainda não monitorado → botão **Monitorar** (insere em `client_processes`).
  2. Não achou → insere em `process_requests` (status `pendente`) e mostra: *"Ainda não encontramos este processo nas fontes públicas.
     Adicionamos à fila. Você pode importar o andamento (colar do SEI) em Configurações → Importar andamento."*
- **Aceite:** NUP inválido mostra erro de formato; NUP de outro cliente não vaza dados privados.

### W1.2 KPI "Processos monitorados"
- Fonte: `v_kpis.processos_monitorados`. Texto: "N processos da {cliente}".

### W1.3 KPI "Próximas reuniões relevantes"
- Fonte: `v_kpis.reunioes_30d` ("nas próximas 30 dias"). Relevante = item de processo monitorado **ou** interesse cadastrado (agência/palavra-chave).

### W1.4 Cabeçalho do processo + chips
- Fonte: `v_my_processes`. Exibir: agência + NUP (ex.: "Processo ANTT 50500.123456/2024-78"), chip de **status**
  ("Em andamento" = `status='em_andamento'`), assunto, interessado(s), chips: agência, **setor** (ex.: Rodovia), **tema** (ex.: Tarifa)
  — vindos de `process_types`.
- Se `tipo_id` nulo: chips só de agência; sem setor/tema.

### W1.5 Andamentos do Processo (linha do tempo)
- Fonte: `v_process_timeline` ordenada por `ocorrido_em desc`.
- Colunas: **Data · Etapa · Descrição · Documento** (link `doc_url` com rótulo `doc_rotulo`, ex.: "Pauta RD nº 1.245", "NT 234/2026/SUROD").
- Etapas exibidas: Autuação, Distribuição, Manifestação, Nota técnica, Deliberação (+ Consulta pública, Pauta, Decisão, Publicação, Recurso, Encerramento).
- Marcador de cor por etapa; badge de origem: **"Fonte pública"** (`pauta/ata/dados_abertos/dou`) ou **"Importado"** (`sei_import/email/manual`, visível só ao cliente).
- **Importante:** o andamento fino do SEI (nota técnica, despacho, manifestação) **não** vem de fonte pública automatizável (captcha).
  No MVP ele chega por **importação assistida** (colar/subir) e por e-mail. Eventos de pauta/ata/acórdão vêm dos coletores.
- Estado vazio: "Sem andamentos públicos ainda. Importe o andamento do SEI para completar a linha do tempo."

### W1.6 Agenda de Reuniões que Impactam o Cliente
- Fonte: `v_agenda_client` (filtrar por `client_id`). Abas por agência com contador (Todas, ANTT, ANTAQ, ARTESP...).
- Colunas: **Data · Agência · Reunião** (ex.: "Reunião de Diretoria", "Audiência Pública") · **Pauta/Processo** (item + NUP) · **Tema** · **Status**.
- **Status**: `confirmada` (pauta publicada com o item) · `prevista` (só calendário/expectativa). Ver regra em `04`.
- Link "Ver agenda completa" → Tela 2.

### W1.7 Taxa de Deferimento em Processos Semelhantes
- Fonte: `rpc_similar_outcome(process_id)` → `n_casos, deferidos, indeferidos, parciais, pct_deferimento, evidencia`.
- Donut (Deferimento × Indeferimento; "parcial" em legenda à parte) + tabela por diretor (`rpc_vote_history`, colunas `pct_deferimento/indeferimento`).
- Filtro "Todos os temas semelhantes" / "Mesmo tipo de processo".
- **Regra de exibição:** mostrar sempre "baseado em *n* casos (últimos 3 anos)" e badge de evidência. Se `n_casos < 10` → badge **"Evidência baixa"**;
  se `n_casos = 0` → "Sem casos semelhantes na base".

### W1.8 Projeção de Votos dos Diretores  →  **renomear no MVP para "Histórico dos diretores em casos semelhantes"**
- Fonte: `rpc_vote_history(process_id)` + regra de rótulo em `04` (seção 7).
- Card por diretor: foto/iniciais, nome, cargo, rótulo, barra e % + **"Base: n casos"**.
- Rótulos neutros: *"Histórico favorável ao deferimento"* / *"Histórico desfavorável"* / *"Indefinido"* / *"Dados insuficientes"*.
- **Só aparece** se `agencies.nivel_voto = 'L2'` para a agência do processo. Em L0/L1 mostrar a mensagem de cobertura (ver `04`, seção 6).
- Mostrar destaque "Relator deste processo: {nome}" (quando conhecido).

### W1.9 Histórico de Votos dos Diretores
- Fonte: `v_directors` + `v_director_stats` (+ `rpc_vote_history` quando filtrado "processos semelhantes (últimos 3 anos)").
- Card: foto/iniciais, nome, cargo, mini-bio (`bio_resumo`), **Nº de processos analisados · % deferimento · % indeferimento · % abstenção**, link "Ver perfil completo" → Tela 3.

---
## TELA 2 — Agenda Regulatória
- Fonte: `v_agenda_all` (todas) com filtro "Somente os meus" (`v_agenda_client`).
- Visões: **Calendário** (mês) e **Lista**. Filtros: agência, tipo de reunião, período, status, busca por NUP/assunto.
- Linha: data/hora, agência, órgão, nº da reunião, modalidade (presencial/virtual/eletrônica), item, NUP, assunto, relator, unidade, status, link da **pauta** (fonte) e, quando houver, da **ata**/acórdão.
- Pós-reunião: mostrar `resultado_tipo` e `acordao_numero` por item.
- Aceite: toda linha tem link para o documento de origem; itens "retirado de pauta" aparecem marcados.

## TELA 3 — Agências e Diretores
- Lista de agências com **cobertura** (selo): fontes ativas, última coleta OK (`sources.last_ok_at`), nível de voto L0/L1/L2.
- Dentro da agência: diretores atuais e anteriores (`v_directors`), mandatos, bio curta, link para fonte oficial.
- Perfil do diretor: bio, mandato, **histórico de votos** (tabela por tema/tipo), nº de relatorias, % deferimento (últimos 3 anos), lista de decisões com link.
- Fotos: usar **iniciais** como padrão; foto oficial só se `foto_url` + `foto_fonte` preenchidos (decisão jurídica — ver `06`).

## TELA 4 — Configurações
- **Processos monitorados:** adicionar/remover NUP, apelido, papel (parte/interessado/monitor).
- **Interesses/alertas:** agência + palavra-chave opcional (`client_interests`); preferências de notificação.
- **Importar andamento:** colar o texto de "Consultar Andamento" do SEI (ou subir PDF do processo, quando o cliente é interessado). Parser determinístico → `process_events` com `origem='sei_import'` e `client_id` preenchido.
- **Saúde das coletas (admin interno):** por fonte: última execução, status, nº de registros, alertas de zero registros (`sources`, `ingestion_runs` via view administrativa — criar `v_ingestion_health` restrita a admins).
- Usuários do cliente (`client_members`).

---
## Mapa widget → dado → coletor (resumo)
| Widget | Tabelas | Quem alimenta |
|---|---|---|
| W1.4 cabeçalho | `processes`, `process_types` | pautas/atas (NUP, assunto), regras de tipo |
| W1.5 andamentos | `process_events` | coletor de pauta/ata/DOU; importação assistida; e-mail |
| W1.6 / Tela 2 | `meetings`, `agenda_items` | coletores de calendário e pauta |
| W1.7 | `agenda_items.resultado_tipo`, `natureza` | parser de ata/acórdão |
| W1.8 / W1.9 | `director_votes`, `people` | parser de ata/votos (se L2) + página de composição da diretoria |
| Alertas/sino | `notifications` | `pg_cron` + SQL |
