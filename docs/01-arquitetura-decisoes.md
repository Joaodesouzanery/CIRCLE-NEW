# 01 — Arquitetura e decisões (ADRs curtos)

## Diagrama
```
Fontes públicas (portais, PDFs, dados abertos, DOU)
        │  (agendador: N8N → dispara GitHub Actions; cron do GitHub só como reserva)
        ▼
 collectors/ (Python)  ──►  Supabase Storage (bronze: PDFs originais + hash)
        │                        │
        ▼                        ▼
 Supabase Postgres (silver: processos, eventos, reuniões, itens, decisões, votos)
        │  views v_* + RPCs (gold)         pg_cron → notifications → Edge Function (e-mail)
        ▼
 Lovable (React) — Auth + RLS por cliente
```

## ADR-1 — Precisa de Railway/Render? **Não, no MVP.**
Coletores rodam em **GitHub Actions** (Python, `pdfplumber`, Tesseract e, se preciso, Playwright), **disparados pelo N8N** via `workflow_dispatch`.
**Por que não confiar só no cron do GitHub:** a documentação e a comunidade mostram que o agendamento pode atrasar dezenas de minutos, não garante horário,
e é desativado automaticamente após 60 dias sem atividade **em repositórios públicos** ✅. Por isso: N8N agenda (horário previsível) + cron do GitHub como reserva
(a coleta é idempotente) + `healthcheck.yml` como "dead-man's switch" (falha → GitHub avisa por e-mail).
Vantagens: sem servidor para manter, código versionado, testável, o Claude Code domina o fluxo, custo baixo.
- ⚠️ Validar cota gratuita de minutos do plano do GitHub (repo privado) e a regra de desativação de cron em repositórios inativos.
- **Revisitar** (migrar para container em Railway/Fly/Cloud Run) se: OCR/backfill pesado passar do limite de tempo/minutos,
  se precisar de coleta "sob demanda" em segundos, ou se Playwright ficar instável.

## ADR-2 — Supabase vs N8N: **Supabase (e GitHub Actions) para o núcleo; N8N só nas bordas.**
Motivos: o N8N Cloud é cobrado **por execução** (Starter ≈ 2.500/mês, Pro ≈ 10.000/mês; **workflows pausam ao atingir o limite**) ✅ e polling frequente consome a cota;
lógica dentro de nós de workflow é difícil de testar e versionar; Supabase já tem agendador (pg_cron) e Edge Functions.

| Tarefa | Onde roda |
|---|---|
| Agendar coletas | **N8N** (REG-01) dispara o GitHub Actions; cron do GitHub como reserva |
| Rodar parsers | GitHub Actions (Python) |
| Upsert, deduplicação, regras, estatísticas | Postgres (SQL/RPC) + Python |
| Gerar notificações (na pauta, reunião amanhã, novo andamento) | `pg_cron` + SQL |
| Enviar e-mail | **N8N** (REG-03) lê a fila via RPC e envia (alternativa: Edge Function + provedor transacional) |
| **Ingestão de e-mails de intimação do SEI** (Gmail) | **N8N** (REG-07, fase 2; lote diário, sem polling) |
| Watchdog, relatório de qualidade, auditoria semanal | **N8N** (REG-02, REG-04, REG-05) |
| WhatsApp/Slack | **N8N** (fase posterior) |

## ADR-3 — Lovable substitui Vercel? **Sim, para o MVP.**
O Lovable gera e **publica** o front (React) com o Supabase integrado; o domínio próprio depende do plano (⚠️ conferir).
Use Vercel **somente se** exportar o código do Lovable (GitHub) para ter: SSR/Next.js, controle de build, domínio/white-label
avançado, preview por PR ou regras de edge. Migração é possível sem reescrever (o front só fala com o Supabase).

## ADR-4 — Quem é dono do quê
- **Claude Code** → repositório `CIRCLE-NEW`: migrações, coletores, funções, testes, docs.
- **Lovable** → repositório `circle-web`: só interface. **Não cria/edita tabelas**; consome `v_*` e `rpc_*`.
- Tipos TypeScript: `supabase gen types typescript` no backend → copiados para o front.
- Risco: o Lovable consegue alterar o Supabase conectado. Mitigação: conectar com a chave `anon`, revisar toda
  alteração de schema pedida pelo Lovable e **rejeitar**; mudanças só por migração do backend.

## ADR-5 — Segredos
`SUPABASE_SERVICE_ROLE_KEY` apenas em GitHub Secrets e Edge Functions. O front nunca recebe essa chave.

## ADR-6 — Ambientes
Dois projetos Supabase: `iris-staging` e `iris-prod`. Coletores novos rodam em staging até conferência manual.

## ADR-6b — Dead-man's switch
Se o N8N pausar (cota) ou cair, nada avisaria. `healthcheck.yml` (GitHub) consulta `v_ingestion_health` diariamente e **falha** se houver fonte atrasada → e-mail do GitHub.

## ADR-7 — IA fica para a v2 (e como encaixar)
Quando entrar: tabela `ai_extractions` (saída JSON validada + fonte + versão do prompt) e `doc_chunks` (pgvector),
sempre atrás de *feature flag* e nunca com dados restritos. O MVP não deve criar dependência de IA.

## Quadro de custos (qualitativo — ⚠️ conferir preços atuais)
Supabase (plano Pro quando sair do piloto) · GitHub Actions (minutos) · e-mail transacional · Lovable (plano pago para domínio) ·
N8N (já existente; uso mínimo). **Sem** custo de LLM no MVP.
