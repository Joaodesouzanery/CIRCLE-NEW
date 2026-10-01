# 07 — Briefing para o Lovable (front)

## Regras
1. O Lovable **só constrói interface**. **Não cria, altera nem apaga tabelas/policies.** Se achar que falta um campo, abra pedido para o backend (Claude Code).
2. Conectar ao Supabase com **chave anon + login do usuário** (RLS faz o isolamento por cliente). Nunca usar `service_role`.
3. Consumir apenas as views/RPCs abaixo. Usar tipos gerados (`supabase gen types typescript`).
4. Enquanto o backend não tem dados reais, usar um arquivo de *mock* com o **mesmo formato** das views; trocar por chamadas reais sem mudar os componentes.

## Contrato de dados (nomes e colunas)
| Uso | Objeto | Colunas principais |
|---|---|---|
| KPIs | `v_kpis` | `client_id, processos_monitorados, reunioes_30d` |
| Meus processos | `v_my_processes` | `client_id, process_id, nup, agencia, assunto, status, etapa_atual, interessados, apelido, tipo, setor, tema, unidade, relator` |
| Andamentos | `v_process_timeline` | `process_id, event_id, ocorrido_em, etapa, titulo, descricao, unidade, doc_rotulo, doc_url, origem` |
| Agenda (cliente) | `v_agenda_client` | `client_id, meeting_id, agenda_item_id, agencia, orgao, tipo_reuniao, numero, ano, inicio, status, item_ref, nup, assunto, process_id, retirado_de_pauta, resultado_tipo, tema, fonte_url, relevancia` |
| Agenda (geral) | `v_agenda_all` | idem, sem `client_id`/`relevancia` |
| Taxa de deferimento | `rpc_similar_outcome(p_process_id)` | `n_casos, deferidos, indeferidos, parciais, pct_deferimento, evidencia` |
| Histórico por diretor (processo) | `rpc_vote_history(p_process_id)` | `person_id, nome, cargo, n_casos, deferimentos, indeferimentos, abstencoes, pct_*, evidencia` |
| Diretores | `v_directors` | `person_id, agencia, nome, cargo, funcao, mandato_inicio, mandato_fim, bio_resumo, bio_url, foto_url, foto_fonte, fonte_url, ativo` |
| Estatística geral por diretor | `v_director_stats` | `person_id, n_processos, pct_deferimento, pct_indeferimento, pct_abstencao` |
| Agências | tabela `agencies` (leitura) | `sigla, nome, esfera, setor, colegiado, nivel_voto` |
| Escritas permitidas ao cliente | `client_processes`, `client_interests`, `process_requests`, `process_events` (somente `origem in ('sei_import','manual')` com `client_id`), `notifications` (marcar lida) | — |

## Design (a partir do mockup)
- Layout: **sidebar azul-marinho** fixa à esquerda com logo "Circle · Monitoramento Regulatório" e menu; topo claro com *breadcrumb* (Dashboard › Meus Processos), seletor de cliente, sino e avatar.
- Cards brancos com cantos arredondados e sombra leve; botão primário azul; chips verde (confirmada/deferimento), azul (prevista/etapa), amarelo (indefinido), vermelho (desfavorável).
- Linha do tempo com marcadores coloridos por etapa; tabelas compactas; donut para deferimento.
- Fonte sans-serif limpa (Inter ou similar); estados vazios, *loading* (skeleton) e erro em todos os widgets.
- Extrair cores exatas do mockup anexado (não inventar paleta).
- Português (pt-BR); datas `dd/mm/aaaa`; NUP sempre com máscara.

## Comportamentos obrigatórios
- Todo dado exibe **link para a fonte** quando houver (`doc_url`, `fonte_url`).
- Todo percentual exibe **"n casos"** e badge de evidência (alta/média/baixa). `n < 10` → "Dados insuficientes" no rótulo do diretor.
- Se `agencies.nivel_voto != 'L2'` para a agência do processo, **ocultar** o widget de histórico por diretor e mostrar o aviso de cobertura (texto em `04`, seção 6).
- Rodapé fixo com o aviso de `06`, seção 4.
- Iniciais no lugar de foto quando `foto_url` for nulo.

## Prompt sugerido para colar no Lovable
```
Crie o front "Circle — Better Regulation" em React + Tailwind, em português do Brasil, conectado ao meu projeto Supabase
(autenticação por e-mail/senha; use somente a chave anon). NÃO crie nem altere tabelas, views, funções ou políticas no banco:
o backend é gerenciado por migrações externas. Consuma apenas os objetos listados no documento "Contrato de dados" (anexo).

Telas: (1) Meus Processos [página inicial], (2) Agenda Regulatória, (3) Agências e Diretores, (4) Configurações.
Siga o mockup anexo (sidebar azul-marinho, cards brancos, chips coloridos). Widgets da tela 1: Consultar Processo (campo NUP com máscara),
KPIs, Andamentos do Processo (linha do tempo), Agenda de Reuniões (abas por agência), Taxa de Deferimento (donut + tabela por diretor),
Histórico dos Diretores em Casos Semelhantes e Histórico de Votos dos Diretores.
Regras: exibir sempre a fonte (link), o número de casos (n) e o nível de evidência; ocultar widgets de voto quando nivel_voto != 'L2';
usar iniciais quando não houver foto; incluir estados de carregamento, vazio e erro. Enquanto não houver dados, use mocks com o mesmo formato.
```
