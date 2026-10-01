# Kit de início — Circle

| Arquivo | Para quê |
|---|---|
| `PROMPT_INICIAL.md` | **Cole na 1ª mensagem do Claude Code.** Explica a plataforma, restrições, pré-requisitos e a primeira tarefa. |
| `PROMPT_N8N.md` | **Cole depois** (com Supabase staging e credenciais prontos): manda o Claude Code criar os workflows na pasta *Regulação*. |
| `CLAUDE.md` | Memória permanente do projeto (regras, estrutura, comandos). Fica na raiz do repo. |
| `docs/00-visao-plataforma.md` | O que é, para quem, escopo do MVP, o que ficou de fora do mockup. |
| `docs/01-arquitetura-decisoes.md` | Decisões: sem Railway, Supabase vs N8N, Lovable vs Vercel, repositórios. |
| `docs/02-telas-e-widgets.md` | Cada widget do dashboard: dados, fonte, regra, estado vazio, critério de aceite. |
| `docs/03-fontes-de-dados.md` | **O que buscar na internet**, em cada site, campo a campo, com padrões (regex). |
| `docs/04-regras-de-negocio.md` | NUP, etapas, natureza, resultado, taxa de deferimento, histórico por diretor, alertas (sem IA). |
| `docs/05-spike-checklist.md` | Ficha de validação por agência (transforma ⚠️ em ✅). |
| `docs/06-lgpd-e-limites.md` | LGPD, captcha, fotos, redação das projeções, retenção. |
| `docs/07-lovable-handoff.md` | Briefing e prompt para o Lovable construir o front. |
| `docs/08-backlog-sprints.md` | Sprints, tarefas e critérios de aceite. |
| `docs/09-n8n-instrucoes.md` | N8N: papel, estado real da instância, orçamento de execuções, credenciais, REG-00 a REG-07. |
| `docs/10-qualidade-e-veracidade-dos-dados.md` | Como manter os dados corretos e verificáveis (camadas, auditoria, casos reais). |
| `docs/11-cobertura-dos-requisitos-originais.md` | Os 8 módulos originais × MVP/v1.5/v2 e o limite de verdade de cada item. |
| `docs/referencia/` | Requisitos originais, mockup, plano técnico anterior (referência; partes de IA adiadas). |
| `supabase/migrations/0001_init.sql` | Schema + RLS + views + RPCs (**testado** em Postgres 16 com dados sintéticos). |
| `supabase/migrations/0002_qualidade_operacao.sql` | Qualidade de dados, saúde das coletas, notificações, auditoria (**testada**). |
| `.github/workflows/collect.yml` | Coleta (disparada pelo N8N; cron só de reserva). |
| `.github/workflows/healthcheck.yml` | Dead-man's switch: falha se houver fonte atrasada. |

Legenda: ✅ confirmado em fonte pública (out/2026) · ⚠️ a validar no Spike.
