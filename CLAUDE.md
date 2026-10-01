# CLAUDE.md — Circle (backend)

## Missão
Coletar dados públicos das agências reguladoras brasileiras e servir um dashboard (Lovable) por meio de
views/RPCs no Supabase. **MVP sem IA.**

## Regras inegociáveis
1. Nunca contornar captcha nem usar serviços de resolução de captcha.
2. Respeitar robots.txt/termos; ≤ 1 requisição a cada 2 s por domínio; User-Agent com contato.
3. Coleta idempotente (hash SHA-256 do documento; `dedupe_hash` em eventos; `unique` em chaves naturais).
4. Todo dado exibido carrega **fonte** (URL do documento original). Sem fonte, não publica.
5. Dados restritos/sigilosos: não coletar, não armazenar.
6. RLS em tudo que é de cliente. Chave `service_role` só nos coletores (GitHub Secrets). O front usa só `anon` + JWT.
7. Schema só muda por migração versionada em `supabase/migrations`. O Lovable não cria tabelas.
8. Parser novo = fixture real + teste. Sem fixture, sem merge.
9. Zero registros onde se esperava algum = `ingestion_runs.status = 'alerta'`.
10. Pauta ≠ resultado: modele `situacao` (extrapauta, adiado, pedido de vista, retirado) e `resultado_provisorio`. Pautas podem ser republicadas.
11. Toda coleta registra `parser_version`, `parse_confidence` e, quando o documento declara contagens, `esperado_n`/`extraido_n`.
12. N8N só orquestra/avisa (ver `docs/09`); nenhuma regra de negócio em workflow. Workflows nascem **inativos**.
13. Não invente dado. Campo não encontrado fica `null` e o parser registra o motivo.

## Estrutura do repositório
```
collectors/
  core/        http.py pdf.py nup.py db.py hashing.py runlog.py
  antaq/       pautas.py atas.py parse.py
  antt/        ...
  aneel/       ...
  anvisa/      ...
  run.py       (python -m collectors.run --agency ANTAQ|all)
tests/fixtures/<sigla>/   (PDFs/HTML reais de amostra)
tests/
supabase/migrations/       (SQL versionado: 0001_init, 0002_qualidade_operacao)
supabase/functions/send-notifications/   (Edge Function de e-mail)
docs/ docs/agencias/<sigla>.md
.github/workflows/collect.yml
```

## Stack
Python 3.12 · httpx · selectolax/BeautifulSoup · pdfplumber/PyMuPDF · Tesseract (fallback OCR) · pytest · ruff.
Supabase (Postgres 15+, Auth, Storage, RLS, pg_cron, Edge Functions). GitHub Actions para agendamento.

## Comandos (criar no Makefile)
`make test` · `make lint` · `make migrate` · `make collect AGENCY=ANTAQ` · `make seed` · `make types`

## Supabase
Aplicar migrações **somente no projeto de staging** (MCP do Supabase é para desenvolvimento; ⚠️ confira a recomendação atual da documentação para produção).
Produção: apenas via pipeline/`supabase db push` revisado. Nunca colar `service_role` em arquivo versionado.

## Fluxo de trabalho
Spike da agência → ficha em `docs/agencias/` → fixtures → parser com testes → coletor → run em staging →
conferência manual de 20 registros → liga o cron. Pare e pergunte quando houver ⚠️ sem validação.
