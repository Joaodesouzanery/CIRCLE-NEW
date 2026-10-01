# 08 — Backlog e sprints (estimativas grosseiras; dependem do Spike)

## Sprint 0 — Spike (1–2 semanas)
- [ ] Fichas `docs/agencias/{antaq,antt,aneel,anvisa}.md` + 5 fixtures cada.
- [ ] Definir `nivel_voto` por agência; atualizar `agencies`.
- [ ] `docs/matriz-viabilidade.md`.
- **Aceite:** decisões pendentes listadas; PM aprova ordem dos coletores.

## Sprint 1 — Fundação (1–2 semanas)
- [ ] Repositório `CIRCLE-NEW`, `CLAUDE.md`, Makefile, CI (lint + pytest).
- [ ] Projetos Supabase `staging` e `prod`; aplicar `0001_init.sql`; bucket `raw-documents`.
- [ ] `collectors/core`: `http` (rate limit, UA), `pdf` (pdfplumber + OCR fallback), `nup`, `hashing`, `db`, `runlog`.
- [ ] Teste automatizado de **RLS** (cliente A × B) e das RPCs com dados sintéticos (reaproveitar o teste do kit).
- [ ] (já entregue na 0002) `platform_admins`, `v_ingestion_health`, `v_dq_anomalias`, RPCs de admin.
- **Aceite:** `make test` verde; migração reaplicável do zero; run de exemplo grava em `ingestion_runs`.

## Sprint 1b — Operação e qualidade (1 semana, em paralelo)
- [ ] Aplicar `0002_qualidade_operacao.sql` no staging; cadastrar `platform_admins` e `client_contacts` do cliente-piloto.
- [ ] `healthcheck.yml` + secrets (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`).
- [ ] **N8N**: executar `PROMPT_N8N.md` → REG-00 a REG-06 criados inativos e testados com pin data; ativar após aprovação.
- [ ] Planilha "Circle — Auditoria" e definição das metas de `docs/10` §4.
- [ ] **Processos-âncora:** cliente-piloto fornece 5–10 NUPs reais e o que ele sabe do andamento de cada um.
- **Aceite:** forçar fonte atrasada → e-mail do watchdog e falha do healthcheck; notificação de teste chega 1× por cliente.

## Sprint 2 — Coletor ANTAQ (2–3 semanas)
- [ ] Crawler da página de reuniões deliberativas → lista de PDFs → download/hash/Storage.
- [ ] Parser de **pauta** e **ata** (campos de `03`, seção 3) com testes sobre fixtures.
- [ ] Upsert: `meetings`, `agenda_items`, `decisions`, `processes`, `process_events`; regras de `natureza`/`resultado`.
- [ ] Alarme de zero registros; `esperado_n/extraido_n` (acórdãos da ata); `situacao`/`resultado_provisorio`; `collect.yml` em staging disparado pelo REG-01.
- **Aceite:** reexecução idempotente; conferência manual de 20 itens com 0 divergências críticas; backfill de 12 meses.

## Sprint 3 — Lovable v1 em paralelo (3–4 semanas)
- [ ] Seed realista a partir da ANTAQ; usuário e cliente de teste ("CS Infra").
- [ ] Telas 1 e 2 com dados reais; Tela 3 e 4 básicas.
- **Aceite:** demo ponta a ponta: cliente loga → monitora NUP → vê agenda e linha do tempo (pública).

## Sprint 4 — Coletor ANTT (2–3 semanas)
- [ ] Pautas (documento SEI/PDF), calendário, Datalegis (se viável); regras de `natureza` (outorga × pleito).
- **Aceite:** igual à Sprint 2.

## Sprint 5 — Diretores e votos (2–3 semanas)
- [ ] Coletor de "Composição da Diretoria" (ANTAQ/ANTT) → `people` (nome, cargo, mandato, bio, fonte).
- [ ] Parser de votos conforme `nivel_voto` → `director_votes`.
- [ ] Validação cruzada: soma de votos × resultado do acórdão.
- **Aceite:** W1.7, W1.8, W1.9 corretos para as agências L1/L2; aviso de cobertura nas L0.

## Sprint 6 — Notificações e importação assistida (2 semanas)
- [ ] `pg_cron` + SQL de notificações (`04`, seção 10); Edge Function `send-notifications` (e-mail).
- [ ] Parser de andamento do SEI (texto colado) + tela "Importar andamento".
- **Aceite:** processo monitorado que entra na pauta gera 1 (e só 1) notificação e e-mail.

## Sprint 7 — ANEEL e ANVISA (3–4 semanas)
- [ ] ANEEL: dataset/API de pautas e atas + PDFs; sorteio de relator; L2 se confirmado.
- [ ] ANVISA: ROP (pauta/ata), numeração hierárquica, GGREC.

## Sprint 8 — Endurecimento e piloto
- [ ] Monitoramento (saúde das coletas), backups, revisão LGPD/RIPD, textos legais, revisão jurídica das redações.
- [ ] Piloto com 1 cliente; coletar feedback; decidir v1.5 (prazo estimado) e v2 (IA).

## Depois
ANATEL, ANAC, ANP, ANM, ANPD, ANA, ANS, ANCINE, ARTESP · prazo estimado · busca avançada · relatórios PDF · N8N para e-mail de intimação/WhatsApp · IA com guardrails.
