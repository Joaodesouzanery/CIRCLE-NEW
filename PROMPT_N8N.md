# Prompt para o Claude Code — construir os workflows do N8N

> Pré-requisitos: (1) migrações `0001` e `0002` aplicadas no **staging** do Supabase; (2) repositório `CIRCLE-NEW` no GitHub com `collect.yml`;
> (3) credenciais criadas no N8N (`supabase-iris-staging`, `github-iris-dispatch`, `email-iris-alertas`); (4) MCP do N8N conectado ao Claude Code.

---

Leia `docs/09-n8n-instrucoes.md` por completo e execute-o. Resumo da missão:

Construa no meu N8N, **dentro do projeto pessoal `v9QNbZ9D7sqGvLo4`, pasta "Regulação" (`jGayRhzwfjhWjIZk`)**, os workflows
**REG-00 a REG-06** descritos na seção 6 (REG-07 só quando eu fornecer e-mails de amostra). Confirme os IDs antes com
`search_projects` e `search_folders`, e confira as credenciais com `list_credentials`. **Não toque** na pasta "Construtora" nem nos
workflows "Ingestão - …".

Regras:
1. Antes de criar qualquer coisa: `get_workflow_best_practices` e `get_workflow_sdk_reference`; valide cada workflow com `validate_workflow`.
2. Crie tudo **inativo**. Teste com `prepare_workflow_pin_data` + `test_workflow`. **Não publique** sem minha aprovação explícita.
3. Sem segredos em código/nós Set/logs. Config não secreta no nó `Config`.
4. Respeite o **orçamento de execuções** (seção 2): sem polling frequente, um workflow processa todas as agências em loop.
5. Marque notificações como enviadas **somente depois** do envio OK. Erros devem falhar o workflow (para cair no REG-00).
6. REG-00 vira *Error Workflow* dos demais.
7. Ao final: liste, para cada workflow, projeto/pasta, ID, gatilho, estimativa de execuções/mês e o resultado dos testes; e liste o que depende de mim.

Se algo no documento conflitar com o que você encontrar no N8N (nomes de nós, parâmetros), **pare e me pergunte** antes de improvisar.
