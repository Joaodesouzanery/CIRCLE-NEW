# Resposta ao Claude Code — decisões e próximos passos (cole isto)

Obrigado pelo relatório. Decisões e ordem de trabalho abaixo. **Pare ao final de cada bloco e me mostre o resultado.**

## A. Antes de qualquer coisa nova (segurança e base)
1. **Revisão da `0003_hardening.sql`:** mostre o diff/o conteúdo e explique cada alteração (grants, policies, `search_path`, views). Ela não veio do kit e eu não a vi.
2. **Teste de segurança:** o kit agora traz `supabase/tests/rls_e_regras.sql` (faltava no zip anterior — por isso você não o encontrou).
   Rode-o inteiro no **staging** (SQL Editor/`execute_sql`). Ele roda num bloco só e **reverte tudo de propósito**.
   - Sucesso = erro com a mensagem `OK_TODOS_OS_TESTES (transação revertida de propósito)`.
   - Falha = mensagem iniciada por `FALHA:` → **não avance**; corrija e rode de novo.
   - Se o `insert into auth.users` falhar, use 3 usuários de teste criados pelo painel Auth e troque os UUIDs no topo.
   Depois rode **o advisor de segurança de novo** e cole o resultado.
3. Mova `pg_trgm` e `unaccent` para o schema `extensions` (se não quebrar os índices existentes) e confira "leaked password protection" nas configurações de Auth.
4. **pg_cron:** execute `select * from cron.job;`. Se estiver vazio, habilite a extensão e reexecute o bloco de agendamento da `0002` (ele só agenda se a extensão existir).
5. Confirme: `web/.env` fora do git; nenhuma `service_role` em `web/` ou em arquivo versionado; repositório **privado**.
6. Abra o **PR e faça merge em `main`** depois de 1–5 (o cron e o `workflow_dispatch` do GitHub dependem do arquivo estar na branch padrão).

## B. Seed e login (sua pergunta)
**Decisão: opção híbrida — front ligado ao banco real do staging, com seed claramente fictício, e login real.**
- Eu crio 2 usuários no Supabase Auth (um admin da plataforma, um do cliente de teste) e passo os UUIDs. Você cria `platform_admins`, o cliente **"[DEMO] CS Infra"**, `client_members` e `client_contacts`.
- Seed em `supabase/seed/demo_seed.sql`, **somente staging**, com marcadores inequívocos: NUPs com prefixo `99999.`, pessoas com nome `[DEMO] Diretor A/B/C` (**nunca nomes reais de dirigentes**), cliente "[DEMO]".
- Faça `supabase/seed/demo_cleanup.sql` que remove tudo do demo, e ponha uma **faixa visível "Dados de demonstração"** no front quando houver dados `[DEMO]`.
- Os números do demo devem ser **internamente consistentes** (veja C.2) e gerados pelas mesmas views/RPCs reais, não por mock paralelo.
- `VITE_USE_MOCKS=false` no staging; manter o modo mock só para desenvolvimento offline.
- Quando a ANTAQ coletar dados reais, rode o cleanup.

## C. Ajustes no front (a partir do screenshot)
1. **Mocks com nomes reais:** os três diretores do mockup são pessoas reais da ANTT, e o mock mostra percentuais e biografias inventados atribuídos a elas. Troque por nomes fictícios e adicione a faixa de demonstração. Isso vale para qualquer tela/print compartilhado.
2. **Inconsistência numérica:** o donut diz "Baseado em 38 casos", mas os cards mostram bases de 67/62/59 casos. Em dados reais o *n* de cada diretor nunca passa do total de casos semelhantes. O bloco "Histórico de Votos" tem o subtítulo "Processos semelhantes (últimos 3 anos)" mas exibe contagens gerais. Decisão: esse bloco usa `v_director_stats` e o subtítulo passa a ser **"Todos os pleitos decididos — últimos 3 anos"**; o bloco de casos semelhantes usa `rpc_vote_history`.
3. **Agenda:** na linha da Audiência Pública o tema aparece duplicado ("Concessões Rodoviárias" ×2) e o texto "CS Infra" sob o tema confunde. Mostre, no lugar, a relevância ("Processo monitorado" / "Interesse cadastrado").
4. **Sidebar:** no screenshot ela termina antes do fim da página. Garanta `sticky` + altura de viewport.
5. **KPI "Processos monitorados":** evite a quebra com "Infra" sozinho na linha.
6. **Tela Agências:** "Atualizado em" por agência, selo de **cobertura** (`nivel_voto` L0/L1/L2) e estados de vazio/erro/carregamento em todos os widgets.
7. Mantenha o que está certo: rótulos neutros, "Base: n casos · evidência", selos "Fonte pública"/"Importado" e o rodapé de aviso legal.

## D. Hospedagem do front
O front agora é código nosso em `web/`. **Decisão:** manter `web/` e hospedar depois no **Vercel** (root directory `web`, variáveis `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`, e URLs de redirect configuradas no Supabase Auth). Lovable não edita este código. Não faça deploy ainda; só deixe documentado em `docs/deploy-web.md`.

## E. Coletores — pergunta sobre a rede
**Primeiro teste de conectividade, antes do Spike.** Para cada URL de agência listada em `docs/03-fontes-de-dados.md`, registre: código HTTP, tempo, tamanho, se há captcha/WAF/bloqueio por IP e o `robots.txt`.
1. Teste **deste ambiente**. Se não alcançar os portais, **não improvise**: crie `.github/workflows/spike.yml` (manual) que roda o mesmo teste num **runner do GitHub** e salva os arquivos baixados como *artifact*.
2. Hipótese a verificar (⚠️ não confirmada): portais `.gov.br` podem bloquear IPs de fora do Brasil/datacenter. Se o runner do GitHub for bloqueado, o plano de coleta muda (runner self-hosted ou container em região de São Paulo). **Reporte isso antes de escrever coletores.**
3. Só depois: Spike (ANTAQ, ANTT, ANEEL, ANVISA, ANP) → framework `collectors/core` → coletor da ANTAQ.
4. Os 5–10 NUPs do piloto eu envio separadamente; **não bloqueiam** o Spike.

## F. Não fazer ainda
Workflows do N8N (depende do staging com dados + credenciais) · ativar cron · qualquer coisa em produção · alterar o schema sem migração versionada.

## G. Formato do seu próximo relatório
Para cada item A–E: feito / não feito / bloqueado e por quê, com evidência (saída do teste, do advisor, do `cron.job`, tabela de conectividade). Liste o que depende de mim.
