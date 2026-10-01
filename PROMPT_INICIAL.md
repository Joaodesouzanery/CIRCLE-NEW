# Prompt inicial para o Claude Code (cole isto na primeira mensagem)

Você vai construir o **backend e a camada de dados** do **Circle** (codinome interno: Cortex), uma plataforma
de monitoramento regulatório para empresas de infraestrutura e consultorias que acompanham processos nas
agências reguladoras brasileiras.

## O que é a plataforma (em 10 linhas)
- O cliente (ex.: "CS Infra") cadastra os processos que acompanha (número SEI/NUP) e as agências de interesse.
- O sistema coleta, de fontes **públicas**, pautas, atas, acórdãos e dados abertos das agências e organiza:
  **processos → andamentos (linha do tempo) → reuniões e pautas → decisões → votos dos diretores**.
- O dashboard (front feito no **Lovable**) mostra: consulta de processo, andamentos, agenda de reuniões que
  impactam o cliente, taxa de deferimento em processos semelhantes e histórico de decisões por diretor.
- Três camadas de valor: **Monitorar** (agenda + andamentos), **Analisar** (histórico e taxas),
  **Antecipar** (indicadores estatísticos de casos semelhantes — **sem IA** nesta fase).
- Escopo inicial: **ANTT e ANTAQ** (cliente de infraestrutura), depois ANEEL e ANVISA; as 12 agências federais
  (incluindo ANPD, agência desde fev/2026) entram por etapas. O mockup também mostra ARTESP (estadual).

## Restrições obrigatórias
1. **Sem IA/LLM nesta fase.** Tudo por código determinístico (regex, parsers, SQL, estatística simples).
2. **Sem servidor dedicado** (nada de Railway/Render): coletores em **GitHub Actions**, **disparados pelo N8N** (agendador confiável),
   com **Supabase** (Postgres, Auth, Storage, RLS, pg_cron). O N8N só orquestra, vigia e envia e-mails — **nenhuma regra de negócio nele**
   (ver `docs/09`; os workflows são construídos depois com o `PROMPT_N8N.md`).
3. **Nunca contornar captcha** (SEI Pesquisa Pública tem captcha). Andamentos finos entram por: fontes públicas,
   importação assistida (cliente cola/sobe o andamento) e e-mail encaminhado. Documente, não automatize o captcha.
4. **Você é dono do schema** (migrações em `supabase/migrations`). O Lovable só consome *views* e RPCs.
5. Toda coleta é **idempotente**, guarda o documento original (hash SHA-256) e registra execução em `ingestion_runs`.
6. Coleta com **zero registros inesperados = alerta**, não sucesso.
7. Dados restritos/sigilosos não são coletados. LGPD: siga `docs/06-lgpd-e-limites.md`.
8. Onde um documento marcar ⚠️, **valide no Spike antes de construir** e me pergunte se houver ambiguidade.

## Leia nesta ordem
`CLAUDE.md` → `docs/00-visao-plataforma.md` → `docs/referencia/requisitos-originais.md` + `docs/referencia/mockup-iris.png`
→ `docs/11-cobertura-dos-requisitos-originais.md` → `docs/01-arquitetura-decisoes.md` → `docs/02-telas-e-widgets.md`
→ `docs/03-fontes-de-dados.md` → `docs/04-regras-de-negocio.md` → `docs/10-qualidade-e-veracidade-dos-dados.md`
→ `docs/05-spike-checklist.md` → `docs/06-lgpd-e-limites.md` → `docs/09-n8n-instrucoes.md` → `docs/07-lovable-handoff.md`
→ `docs/08-backlog-sprints.md`.
As migrações `0001_init.sql` e `0002_qualidade_operacao.sql` foram **testadas** em Postgres 16 (aplicam em banco limpo; isolamento entre clientes,
RPCs estatísticas, notificações idempotentes, fila de envio, anomalias de qualidade e permissões validados com dados sintéticos e privilégios padrão do Supabase).
Elas ainda **não** foram aplicadas no seu Supabase: faça isso no **staging**.
`docs/referencia/cortex-plano-tecnico.md` é só referência (partes de IA estão adiadas).

## Antes de começar, confirme comigo (se faltar, me peça)
1. Projeto Supabase **staging** conectado (MCP) — nunca rodar migração direto em produção.
2. Repositório GitHub `CIRCLE-NEW` criado + secrets `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` (staging).
3. **5–10 NUPs reais do cliente-piloto** (processos-âncora) e o que o cliente sabe do andamento de cada um — será o teste de verdade.
4. Credenciais do N8N criadas (`docs/09`, seção 3) — só necessárias na etapa do `PROMPT_N8N.md`.
5. Nome oficial do produto (mockup: Circle) e e-mail dos administradores da plataforma.

## Sua primeira tarefa (Sprint 0 + 1)
1. Crie o repositório conforme a estrutura do `CLAUDE.md` e aplique a migração `0001` no meu projeto Supabase
   (me peça URL/chaves ou use o MCP do Supabase se estiver configurado).
2. **Spike**: para **ANTAQ, ANTT, ANEEL, ANVISA e ANP** (ANP é forte candidata a nível L2), preencha `docs/agencias/<sigla>.md` (modelo em
   `docs/05-spike-checklist.md`), salvando 5 PDFs reais por agência em `tests/fixtures/<sigla>/`.
   Determine o **nível de voto (L0/L1/L2)** de cada uma e atualize `agencies.nivel_voto`.
3. Construa o **framework de coleta** (`collectors/core`): HTTP com rate limit e User-Agent identificável,
   download+hash+Storage, extração de texto de PDF (com OCR como fallback), utilitário de NUP, logging de runs.
3b. Aplique `0001` e `0002` no staging (via MCP do Supabase) e rode os testes de RLS/RPC do kit; cadastre `platform_admins` e o cliente-piloto.
4. Entregue o **coletor da ANTAQ** (pautas + atas → `meetings`, `agenda_items`, `decisions`, `processes`)
   com testes sobre as fixtures.
5. Ao final de cada etapa: atualize a matriz de viabilidade, liste decisões pendentes e **pare para eu aprovar**.

## Definição de pronto (qualquer coletor)
Testes de parser passam com fixtures reais · reexecutar não duplica · run registrado · alarme de zero registros ·
`esperado_n`/`extraido_n` quando o documento declara contagem · `situacao`/`resultado_provisorio` tratados ·
fonte (URL + documento) rastreável em cada linha · nenhum dado restrito · `v_dq_anomalias` sem anomalia **alta** nos dados do piloto.
