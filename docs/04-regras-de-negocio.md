# 04 — Regras de negócio (sem IA: regex, SQL e estatística simples)

## 1. NUP
- Formato: `NNNNN.NNNNNN/AAAA-DD`. Normalizar sempre (função SQL `normalize_nup` e equivalente em `collectors/core/nup.py`).
- O prefixo (5 primeiros dígitos) identifica o órgão: validar contra `agencies.nup_prefixos`; se não casar, gravar mesmo assim e marcar `origem` + log de aviso.
- Dígito verificador: ⚠️ avaliar se há algoritmo público; no MVP apenas formato.

## 2. Etapas normalizadas (linha do tempo)
`autuacao → distribuicao → manifestacao → nota_tecnica → consulta_publica → pauta → deliberacao → decisao → publicacao → recurso → encerramento` (+ `outros`).

Regras por palavra-chave (case-insensitive, sem acento) sobre o texto do evento:

| Etapa | Gatilhos |
|---|---|
| autuacao | `autuad`, `autuaç`, `processo iniciado`, `protocolo`, `processo inicial` |
| distribuicao | `distribu`, `sorteio`, `relator designad`, `atribuíd` |
| manifestacao | `manifestaç`, `parecer`, `procuradoria`, `despacho` |
| nota_tecnica | `nota técnica`, `\bNT\b` |
| consulta_publica | `consulta pública`, `audiência pública`, `tomada de subsídios` |
| pauta | `incluíd\w* em pauta`, `pauta da reunião` |
| deliberacao | `deliberaç`, `reunião de diretoria`, `deliberad` |
| decisao | `acórdão`, `decisão`, `aprovad`, `indeferid`, `deferid` |
| publicacao | `publicad`, `diário oficial`, `\bDOU\b` |
| recurso | `recurso`, `reconsideraç` |
| encerramento | `arquivad`, `encerrad`, `concluíd` |

Prioridade em caso de múltiplos gatilhos: o mais **específico** vence (ordem da tabela de baixo para cima em empate). Sem gatilho → `outros`. `processes.etapa_atual` = etapa do evento mais recente (não-`outros` se existir nos últimos 30 dias).

## 3. Eventos que nascem dos coletores
| Origem | Evento gerado | Etapa |
|---|---|---|
| Pauta publicada com NUP | "Incluído na pauta da Reunião {nº} de {data}" + link da pauta | `pauta` |
| Ata/acórdão com NUP | "Deliberado na Reunião {nº}: {resultado}" + link | `deliberacao`/`decisao` |
| Retirado de pauta | "Retirado de pauta (relator)" | `pauta` |
| Sorteio/designação de relator (ex.: ANEEL) | "Processo distribuído ao Diretor {nome}" | `distribuicao` |
| DOU | "Publicado no DOU: {ato}" | `publicacao` |
| Importação assistida do SEI | conforme texto (seção 2) | variável |

`dedupe_hash = sha1(process_id | client_id|'' | ocorrido_em(ISO) | etapa | texto_normalizado)`.

## 4. Natureza do item e resultado (base da taxa de deferimento)
**natureza:** `pleito | normativo | outorga_concessao | sancionador | administrativo | outros` (regras por agência em `rules.yaml`).
Só `pleito` entra em taxa de deferimento e histórico de votos. **Não** entram: normativo, outorga/concessão (leilões, editais), sancionador, administrativo.

**resultado_tipo** (extraído de ata/acórdão por padrões):

| Texto (exemplos) | resultado_tipo |
|---|---|
| "deferir", "aprovar o pleito", "dar provimento" | `deferido` |
| "dar provimento parcial", "deferir parcialmente" | `parcial` |
| "indeferir", "negar provimento", "rejeitar o pedido" | `indeferido` |
| "não conhecer" | `nao_conhecido` |
| "retirado de pauta" | `retirado` |
| sem resultado ainda | `pendente` |
| fora do escopo (normativo etc.) | `nao_aplicavel` |

Atenção à **perspectiva do pleiteante**: em recurso, "dar provimento" favorece o recorrente → `deferido`. Casos ambíguos → `outros` + log (**nunca chutar**).

## 5. Processos semelhantes e taxa de deferimento (RPC `rpc_similar_outcome`)
- **Semelhante** = mesma `agency_id` + mesmo `tipo_id` (de `process_types`) + `natureza='pleito'` + resultado em {deferido, indeferido, parcial} + últimos **3 anos**, excluindo o próprio processo.
- `pct_deferimento = deferidos / n_casos`.
- **Nível de evidência:** `alta` (n ≥ 30) · `media` (10 ≤ n < 30) · `baixa` (n < 10). Sempre exibir *n* e o nível.
- Sem `tipo_id` → sem comparação (mostrar "tipo de processo não classificado").
- Ampliar semelhança (v1.5): degrau `tipo → tema → setor`, mostrando o degrau usado.

## 6. Níveis de granularidade de voto (por agência)
| Nível | O que a fonte publica | O que o produto mostra |
|---|---|---|
| **L0** | só o resultado do item | Taxa de deferimento por tipo (W1.7 sem tabela por diretor). W1.8/W1.9 ocultos com aviso de cobertura |
| **L1** | relator + resultado | Estatísticas do **relator** (relatorias, % deferimento quando relator). W1.8 limitado ao relator do processo |
| **L2** | voto de cada diretor | Todos os widgets |

Definido no Spike e gravado em `agencies.nivel_voto`. Mensagem padrão: *"Esta agência não publica o voto individual de cada diretor; exibimos o resultado das decisões e o relator."*

## 7. Histórico por diretor e rótulos (W1.8) — sem "previsão de voto"
Para o processo-alvo e cada diretor *D* (via `rpc_vote_history`): `k` = votos de deferimento, `n` = votos em pleitos semelhantes com resultado.

- `pct = k / n`.
- **Suavização (opcional, recomendada com n pequeno):** `p = (k + α·p0) / (n + α)` com `α = 5` e `p0 = pct_deferimento` da agência/tipo (de `rpc_similar_outcome`), ou `0,5` se não houver.
- **Intervalo de Wilson 95%** para `pct` (calcular no front ou numa view): mostrar como tooltip "entre X% e Y%".
- **Rótulo** (evidência manda no rótulo):
  - `n < 10` → **"Dados insuficientes"** (sempre, qualquer que seja o %);
  - `p ≥ 0,60` → "Histórico favorável ao deferimento";
  - `p ≤ 0,40` → "Histórico desfavorável ao deferimento";
  - senão → "Indefinido".
- **Substitui o "% de confiança da projeção" do mockup** por: "Base: *n* casos · Evidência alta/média/baixa". Um percentual de "confiança" sem calibração induz ao erro.
- Mostrar o **relator** do processo (efeito relator é forte em colegiados) e a observação: *"Baseado em decisões passadas em casos semelhantes. Não é previsão de resultado nem parecer jurídico."*

## 7b. Situação do item e resultado provisório (descobertos na pesquisa)
- `agenda_items.situacao`: `pauta` (estava na pauta, sem desfecho) · `deliberado` · `adiado` · `pedido_vista` · `retirado` · `extrapauta` (votado sem constar na pauta).
- Itens `adiado`/`pedido_vista`/`retirado` **não** entram em taxa de deferimento (resultado não é final).
- `resultado_provisorio = true` quando a fonte for extrato/minuta sujeito a alteração (ex.: extrato de ata da ANS) até existir a ata aprovada.
- **Pautas republicadas** (ANVISA): cada versão é um `raw_document`; `meetings.pauta_doc_id` aponta a mais recente; gerar evento "Pauta republicada".
- **Semântica de voto por agência:** relator vota primeiro; ausente ≠ voto; manifestação escrita de ausente **pode ou não** valer como voto (ANP: votos enviados ao Diretor-Geral e apresentados ✅; ANAC, regimento de 2007: sem valor de voto ⚠️ conferir vigência). Registrar a regra no `docs/agencias/<sigla>.md`.
- **Unanimidade:** gravar `unanime=true` e criar votos apenas para os **presentes** listados na ata.

## 8. Status e "Confirmada/Prevista" da reunião
- `prevista`: veio do calendário/expectativa (sem pauta publicada) ou item inferido.
- `confirmada`: existe **pauta publicada** contendo o item/NUP.
- `realizada`: ata/resultado publicado ou data passada com resultado.
- `cancelada`: aviso oficial de cancelamento/adiamento.
Transições nunca retrocedem sem evidência (ex.: `confirmada` → `prevista` só se a pauta for retirada).

## 9. Reunião "relevante" para o cliente
Item da reunião é relevante se: (a) NUP está em `client_processes`; ou (b) agência em `client_interests` e (`keyword` nula ou presente em `assunto`/`tema`). Audiências públicas das agências de interesse entram como relevantes. (Implementado em `v_agenda_client`.)

## 10. Notificações (pg_cron + SQL; e-mail por Edge Function)
| Tipo | Gatilho | `dedupe_key` |
|---|---|---|
| `na_pauta` | novo `agenda_item` ligado a processo monitorado | `pauta:{agenda_item_id}` |
| `reuniao_amanha` | diário 08:00 BRT (cron `0 11 * * *` UTC) para reuniões no dia seguinte com item relevante | `amanha:{meeting_id}:{data}` |
| `novo_andamento` | novo `process_event` público de processo monitorado | `evento:{event_id}` |
| `decisao` | `resultado_tipo` sai de `pendente` | `decisao:{agenda_item_id}` |
| `status_mudou` | `processes.status` muda | `status:{process_id}:{novo}` |
Unicidade `(client_id, dedupe_key)` evita duplicatas.

## 11. Importação assistida do SEI (andamento)
- Entrada: texto colado de "Consultar Andamento" (⚠️ confirmar formato real: colunas **Data/Hora · Unidade · Descrição**) ou PDF do processo (quando o cliente é interessado).
- Parser: uma linha = um evento; data `dd/mm/aaaa HH:MM`; unidade; descrição; extrair rótulos de documentos ("Nota Técnica nº 234/2026/SUROD", "Parecer", "Despacho") e **SEI nº** quando houver.
- Etapa pela tabela da seção 2. Grava `process_events` com `origem='sei_import'`, `client_id` do cliente, `dedupe_hash`.
- Privacidade: fica visível **só** ao cliente que importou.

## 12. Prazo estimado (v1.5, opcional)
Mediana e faixa P25–P75 de `concluido_em − aberto_em` em processos semelhantes concluídos (n ≥ 20; relaxar degraus e informar o degrau).
Corrigir viés de censura: mostrar também "% dos semelhantes ainda em aberto após *t* dias". Regra regulamentar (ex.: prazo do relator na ANTAQ) prevalece como marco.
Depende de `aberto_em`/`concluido_em`, que **só existem onde a fonte publica** — validar no Spike.
