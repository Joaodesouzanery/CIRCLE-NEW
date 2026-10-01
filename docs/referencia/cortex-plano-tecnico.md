> **ATENÇÃO — documento de REFERÊNCIA.** Escrito antes da decisão "MVP sem IA e sem servidor dedicado".
> Onde houver conflito, **prevalecem os arquivos em `docs/00` a `docs/08`**. As partes de IA (seção 7),
> embeddings/RAG, worker em Railway/Render e o desenho de 10 workflows N8N ficam **adiados para a v2**.
> As seções 2 (hierarquia de fontes), 5 (playbook por agência), 8 (prazo), 11 (LGPD) e 12 (spike) continuam válidas.

# Cortex — Plano Técnico de Monitoramento Regulatório (12 agências)

> Documento para ser entregue ao Claude Code como especificação inicial.
> Data-base da pesquisa: 01/out/2026.
>
> **Legenda de confiança**
> - ✅ = confirmado em fontes públicas consultadas nesta pesquisa
> - ⚠️ = inferido, de conhecimento prévio ou ainda não verificado. **Validar no Spike (seção 12) antes de construir.**

---

## 0. Resumo executivo e correções importantes

1. **São 12 agências reguladoras federais, não 11.** A ANPD virou agência reguladora pela Lei 15.352/2026 (25/02/2026), entrando no rol da Lei 13.848/2019 como inciso XII ✅.
2. **A lei ajuda você.** A Lei 13.848/2019 determina decisão colegiada e reuniões deliberativas **públicas e gravadas** ✅. Isso garante pautas, atas e votos publicados em todas as agências — é a espinha dorsal do produto.
3. **O gargalo não é o SEI inteiro, é a "movimentação" do processo.** Pautas/atas/acórdãos são públicos e previsíveis (fácil). O andamento detalhado de cada processo está no SEI, cuja Pesquisa Pública **exige captcha** ✅ e processos restritos só aparecem para interessados cadastrados ✅.
4. **Recomendação-chave de arquitetura:** construir em torno de uma **hierarquia de fontes** (seção 2) e **não contornar captcha**. O produto nasce forte em *Agenda + Decisões + Relatores + Comparativo* (dados abertos) e ganha *andamento fino* via canais legítimos (e-mail de intimação do cliente, acesso externo autorizado pelo cliente).
5. **Dá para testar o fluxo inteiro sem o Lovable**: Supabase + N8N + Claude Code ficam prontos e validados; o Lovable só consome *views/RPCs* com contrato fixo (seção 10).

---

## 1. Cobertura: as 12 agências

| # | Agência | Colegiado | Prefixo NUP (SEI) | Estado do mapeamento |
|---|---|---|---|---|
| 1 | **ANEEL** (energia) | Diretoria (5 dir.) | 48500 ✅ | Melhor caso: dados abertos + API, pautas e atas desde set/2017 ✅ |
| 2 | **ANATEL** (telecom) | Conselho Diretor | 53500 ✅ | Dados abertos; reuniões transmitidas; plano de abrir "Textos Públicos do SEI" ✅ |
| 3 | **ANP** (petróleo/gás) | Diretoria Colegiada | 48610 ⚠️ | Reuniões com calendário ✅; dados abertos ⚠️ |
| 4 | **ANS** (saúde suplementar) | Dicol | 33910 ⚠️ | SEI historicamente "difícil acesso" (estudo 2022) ⚠️ |
| 5 | **ANVISA** (vigilância sanitária) | Dicol | 25351 ✅ | Pautas, atas, "processos deliberados", sessões de recurso ✅ |
| 6 | **ANA** (águas/saneamento) | Diretoria Colegiada | 02501 ⚠️ | Calendário 2026 não estava no site em jan/2026 ✅ (risco) |
| 7 | **ANTT** (transp. terrestre) | Diretoria Colegiada | 50500 ✅ | Pauta publicada como documento SEI (PDF) ✅; atos no sistema Datalegis ✅ |
| 8 | **ANTAQ** (aquaviário) | Diretoria Colegiada | 50300 ✅ | Pauta externa + ata em PDF com nº do processo e acórdão ✅ |
| 9 | **ANAC** (aviação civil) | Diretoria Colegiada | 00058 ⚠️ | Reuniões eletrônicas e presenciais, calendário anual ✅ |
| 10 | **ANCINE** (audiovisual) | Diretoria Colegiada | 01416 ⚠️ | SEI historicamente "difícil acesso" (estudo 2022) ⚠️ |
| 11 | **ANM** (mineração) | Diretoria Colegiada | 48400/48403 ⚠️ | Reuniões com calendário ✅; restante ⚠️ |
| 12 | **ANPD** (proteção de dados) | Conselho Diretor | 00261 ✅ | SEI com Pesquisa Pública; Agenda Regulatória 2025-26 e nova proposta ✅ |

**Ordem sugerida de implantação (por facilidade e valor):**
ANEEL → ANTAQ → ANTT → ANVISA → ANATEL → ANAC → ANP → ANM → ANPD → ANA → ANS → ANCINE.

---

## 2. Hierarquia de fontes e regras de coleta

Use sempre a fonte **mais alta** da lista que entregue o campo desejado.

| Nível | Fonte | Estabilidade | Como coletar |
|---|---|---|---|
| 1 | **Dados abertos** (API/CSV/JSON em dados.gov.br e portais próprios) | Alta | N8N HTTP Request + upsert direto |
| 2 | **Pautas, atas, acórdãos, votos** (PDF/HTML no portal gov.br da agência) | Média-alta | Download → hash → extração de texto → Claude estrutura |
| 3 | **Normas e atos** (DOU, sistemas de legislação como Datalegis/ANTT, resoluções) | Média | Coleta por busca de termos + DOU ⚠️ (verificar INLABS/XML do DOU) |
| 4 | **SEI — Pesquisa Pública** (por nº do processo ou período) | Baixa (captcha, mudanças) | Só consulta individual, com limites. **Sem burlar captcha** |
| 5 | **Ingestão por e-mail** (notificações/intimações que o cliente recebe do SEI/agência) | Alta | Cliente cria regra de encaminhamento → caixa dedicada → N8N parseia |
| 6 | **Acesso externo concedido pelo cliente** (cliente é interessado no processo) | Média | Somente com autorização contratual e credencial própria do cliente ⚠️ avaliar termos de uso |
| 7 | **LAI** (Lei 12.527/2011) | Lenta | Pedido formal quando não há outra via |

### Regras de ouro (não negociáveis)
1. **Não contornar captcha** (nem serviços de resolução). Risco jurídico, de bloqueio e de imagem.
2. Respeitar `robots.txt`, termos de uso e limite de taxa (≤ 1 requisição/2 s por domínio, janelas fora do horário comercial para backfill).
3. User-Agent identificável, com contato.
4. **Guardar sempre o documento original** (bronze) + hash SHA-256 + URL + data de captura. Toda análise de IA aponta para a fonte.
5. Coleta **idempotente**: reexecutar nunca duplica nem corrompe.
6. Se uma coleta retorna **zero registros** onde se esperava algum, é **alarme**, não sucesso.

---

## 3. Arquitetura em camadas (Bronze → Silver → Gold)

```
FONTES ──► [Coletores] ──► BRONZE ──► [Parsers + IA] ──► SILVER ──► [Regras/Estatística] ──► GOLD ──► Lovable
         N8N + Worker     Storage     Edge Fn/Worker     Postgres    SQL/Edge Fn            Views/RPC   Dashboard
                          raw_documents                  tabelas     duration_stats          v_* + RLS
```

- **Bronze**: arquivos e payloads brutos intactos (Supabase Storage + tabela `raw_documents`).
- **Silver**: entidades normalizadas (processos, eventos, reuniões, pautas, decisões, pessoas).
- **Gold**: *views* e tabelas materializadas prontas para a tela (visão geral, linha do tempo, prazo estimado, painel do cliente).
- **Semântica**: `doc_chunks` com embeddings (pgvector) para busca e comparação.

### Onde cada coisa roda

| Responsabilidade | N8N | Edge Function (Supabase) | Worker (Railway/Fly/Cloud Run) |
|---|---|---|---|
| Agendar, orquestrar, retry, alertas | ✅ | | |
| HTTP simples a API/CSV | ✅ | | |
| Download de PDF + hash + storage | ✅ (ou) | ✅ | |
| Extração de texto de PDF/OCR | | | ✅ (PyMuPDF, Tesseract/OCR) |
| Páginas com JS/formulário (Playwright) | | | ✅ |
| Chamada ao Claude API (estruturação) | ✅ (fila simples) | ✅ (lógica) | ✅ (lote/backfill) |
| Regras de negócio, upsert, deduplicação | | ✅ | ✅ |
| Estatística de prazo | | ✅ / SQL | |
| Envio de e-mail/WhatsApp | ✅ | | |

**Princípio:** N8N **orquestra**, não "pensa". Lógica pesada fica em código versionado (Claude Code escreve), testável fora do N8N.

---

## 4. Modelo de dados (Supabase / Postgres)

Extensões: `vector`, `pg_trgm`, `unaccent`, `pg_cron`, `pgcrypto`.

```sql
-- Cadastros
agencies(id, sigla, nome, setor, nup_prefixos text[], ativo)
org_units(id, agency_id, sigla, nome, tipo /*diretoria|superintendencia|gerencia*/, parent_id)
people(id, agency_id, nome, cargo, tipo /*diretor|superintendente|outro*/,
       unidade_id, mandato_inicio, mandato_fim, bio_url, lattes_url, fonte_url, atualizado_em)

-- Rastreabilidade de coleta
sources(id, agency_id, nome, tipo, url_base, metodo /*api|html|pdf|playwright|email*/,
        cadencia, status, last_ok_at, last_rows)
ingestion_runs(id, source_id, iniciado_em, finalizado_em, status, n_encontrados, n_novos, n_atualizados, erro)
raw_documents(id, source_id, url, sha256 unique, mime, storage_path, capturado_em,
              texto_extraido, usou_ocr bool, paginas int)

-- Núcleo
process_types(id, agency_id, codigo, nome, familia, versao_taxonomia)
processes(id, agency_id, nup, nup_normalizado unique, tipo_id, tipo_confianca numeric,
          assunto, interessados text[], status, etapa_atual, unidade_id, relator_id,
          aberto_em, concluido_em, restrito bool, fonte_principal_id)
process_events(id, process_id, ocorrido_em, tipo_evento, etapa_normalizada,
               unidade_id, descricao_original, doc_id, hash unique)
meetings(id, agency_id, orgao /*diretoria|conselho*/, numero, tipo /*ordinaria|extra*/,
         modalidade /*presencial|virtual|eletronica*/, inicio, fim, pauta_doc_id, ata_doc_id, video_url, status)
agenda_items(id, meeting_id, process_id, ordem, bloco /*individual|em_bloco*/, assunto,
             relator_id, unidade_id, retirado_de_pauta bool, resultado, decisao_id)
decisions(id, agency_id, tipo /*acordao|resolucao|despacho|rdc|ren|outro*/, numero, ano, data,
          process_id, meeting_id, ementa, resultado, doc_id)
regulatory_agenda(id, agency_id, tema, fase, previsao, status, doc_id)       -- Agenda Regulatória / AIR
public_consultations(id, agency_id, numero, titulo, abertura, encerramento, status, doc_id)

-- IA
ai_extractions(id, doc_id, modelo, prompt_versao, saida jsonb, schema_ok bool,
               revisado_por, revisado_em, confianca numeric)
doc_chunks(id, doc_id, process_id, idx, texto, embedding vector(1024), meta jsonb)
similar_cases(process_id, similar_process_id, score, motivo)

-- Clientes (multi-tenant)
clients(id, nome, plano, ativo)
client_users(id, client_id, user_id, papel)
client_processes(id, client_id, process_id, apelido, papel /*parte|interessado|monitor*/, alertas jsonb)
alerts(id, client_id, process_id, tipo, payload jsonb, enviado_em, canal)

-- Gold
duration_stats  -- materialized view: agency, tipo, n, p25, p50, p75, media, versao
```

**RLS:** toda tabela `client_*`, `alerts` e as *views* do cliente filtram por `client_id` via `client_users`. Dados públicos (processos, pautas, decisões) são leitura para autenticados; **a lista de processos que um cliente monitora é sigilo comercial** e nunca aparece para outro cliente.

**Número de processo (NUP):** normalizar para `NNNNN.NNNNNN/AAAA-DD` e extrair prefixo (órgão) para validar que o NUP pertence à agência certa. Parser compartilhado, com testes.

---

## 5. Playbook por agência

Para cada agência: **o que buscar → de onde → como coletar → o que extrair → para onde vai no Cortex → como aparece**.

### 5.1 ANEEL ✅ (agência piloto recomendada)
- **Fontes**
  - Portal de Dados Abertos da ANEEL, com API; inclui **Pautas e Atas das Reuniões Públicas da Diretoria desde set/2017** e base de penalidades ✅.
  - Pautas em PDF (ex.: "Pauta da Nª Reunião Pública Ordinária da Diretoria de AAAA") com: processo, assunto, **Área Responsável (superintendência)**, **Diretor-Relator**, bloco da pauta, indicação de "retirado de pauta" ✅.
  - Votos, memórias de reunião, atas e atos administrativos publicados após a reunião ✅.
  - Sorteio de relator e redistribuição de processos na troca de diretoria ✅ (ex.: saída de diretor redistribui processos por sorteio).
  - Consultas e audiências públicas; Agenda Regulatória.
- **Coleta:** N8N (cron diário + gatilho extra nas terças, dia de reunião) → dataset de pautas via API → PDF da pauta quando não houver dado estruturado.
- **Extrair:** nº da reunião, data, NUP, assunto, área responsável, relator, bloco, retirado de pauta, resultado, ato publicado.
- **Destino:** `meetings`, `agenda_items`, `processes`, `decisions`, `people` (relatores), `org_units`.
- **Exibição:** Agenda (calendário + pauta por processo), perfil de relator (nº de processos, tempo médio, % em bloco), linha do tempo do processo, "empates/retiradas de pauta" como sinal de risco.
- **Sinais de inteligência especiais:** processos empatados e retirados de pauta (aparecem na imprensa especializada), concentração de pauta por relator em fim de mandato ✅.
- **Validar no Spike:** campos reais do dataset, paginação da API, se há data de abertura do processo, se há *andamento*.

### 5.2 ANTAQ ✅
- **Fontes:** pasta "Reuniões Deliberativas" no gov.br/antaq com **Pauta Externa (PDF)** e **Ata (PDF)**; reuniões ordinárias numeradas (ex.: 606, 610, 613, 615) e normalmente **virtuais em janela de 3 dias** ✅.
- **Estrutura da ata:** "Acórdão nº X-AAAA-ANTAQ", **Processo**, **Unidade Técnica**, relator(a), "processos retirados de pauta", interessados, referência a SEI de relatório/minuta ✅.
- **Normas de processo:** Resolução ANTAQ 66/2022 (andamento de processos na diretoria), alterada em abr/2026: prazo do relator para levar o processo à diretoria após a instrução técnica passou de **30 para 60 dias**; novas regras de inclusão em pauta ✅. → **Isso alimenta o módulo de prazo com regra, não só estatística.**
- **Coleta:** N8N lista a página de reuniões (HTML) → detecta PDFs novos → Worker extrai texto → Claude estrutura.
- **Destino:** `meetings`, `agenda_items`, `decisions` (acórdãos), `processes`.
- **Exibição:** acórdão ligado ao processo e à reunião; indicador "prazo regulamentar do relator" com contagem regressiva.
- **Acesso a processos:** SEI/ANTAQ tem Pesquisa Pública; há processos restritos acessíveis só a interessados cadastrados ✅.

### 5.3 ANTT ✅
- **Fontes:** reuniões de Diretoria Pública numeradas (ex.: 1.040ª em 27/08/2026), com **pauta publicada como documento SEI (PDF)**, referenciando editais, concessões, acórdãos do TCU, contratos de autorização ✅. Atos normativos no sistema **Datalegis (anttlegis.antt.gov.br)** ✅.
- **Coleta:** HTML da página de reuniões → PDF da pauta → texto → Claude. Datalegis por busca de atos (⚠️ validar se há formato estruturado).
- **Extrair:** nº da reunião, horário, assunto, NUP (50500.xxxxxx/AAAA-DD), tipo (edital, relicitação, TAC, norma), referência ao TCU.
- **Exibição:** painel de concessões (rodovias, ferrovias) por fase; relações com acórdãos do TCU.
- **Atenção:** muita matéria é **leilão/concessão** (ciclos longos, com TCU no meio). O "tipo de processo" precisa refletir isso para a comparação ser honesta.

### 5.4 ANVISA ✅
- **Fontes:** Dicol — **Reunião Ordinária Pública (ROP)** numerada por ano, com pauta, ata e página "Processos deliberados" ✅; **Sessões de Julgamento (GGREC)** para recursos ✅; **Temas com deliberação final em Dicol** e minutas na Agenda Regulatória ✅.
- **Regras úteis:** inscrição para sustentação oral/pedidos de sigilo até 2 dias úteis antes; manifestações publicadas até 3 dias antes da reunião ✅ (confirmar regra vigente no regimento atual).
- **Estrutura do item:** numeração hierárquica (ex.: 2.4.10), "retirado de pauta pelo relator", "incluído em pauta", reunião anterior, decisão anterior ✅.
- **Coleta:** HTML + PDF (pauta, ata). RDCs/INs via sistema de legislação.
- **Destino:** `meetings`, `agenda_items`, `decisions` (RDC/IN), `regulatory_agenda`, `public_consultations`.
- **Exibição:** pauta com alerta "prazo para inscrição" e "item retirado/voltou"; histórico do tema (consulta pública → minuta → RDC).

### 5.5 ANATEL ✅
- **Fontes:** Conselho Diretor — calendário de reuniões, pautas, atas, atos; reuniões abertas e transmitidas (YouTube) ✅. **Plano de Dados Abertos 2025–2027** com novas bases, incluindo **"Textos Públicos da Anatel" (documentos públicos do SEI, atos publicados, processos encerrados)** — previsão dez/2025 ⚠️ (**verificar se já foi publicada; seria a melhor fonte para histórico**) ✅. Painéis de dados e Portal Brasileiro de Dados Abertos ✅. **SACP** para consultas públicas ✅. SEI Pesquisa Pública (com captcha) ✅.
- **Coleta:** dados abertos primeiro; pautas/atas em HTML/PDF; consultas públicas via SACP (HTML).
- **Destino:** `meetings`, `agenda_items`, `decisions`, `public_consultations`, `processes` (53500.xxxxxx/AAAA-DD).
- **Exibição:** Agenda + consultas públicas com prazo de contribuição; base de histórico de 3 anos via dados abertos quando disponível.

### 5.6 ANPD ✅
- **Fontes:** SEI/ANPD com Módulo de Pesquisa Pública (por nº, livre, unidade geradora, tipo, período) e Consulta Pública ✅; Agenda Regulatória 2025–2026 (16 temas) e **nova proposta de agenda** em elaboração (Nota Técnica 20/2026) ✅; processos sancionadores e fiscalização (volume crescente em 2026) ✅.
- **Particularidade:** é a mais nova agência (Lei 15.352/2026); estrutura ainda se instalando — espere mudanças de site e de fluxo ✅.
- **Coleta:** HTML/PDF do gov.br/anpd; Pesquisa Pública pontual.
- **Exibição:** agenda regulatória por tema/fase; processos sancionadores relevantes para clientes.

### 5.7 ANAC ⚠️/✅
- **Fontes:** reuniões deliberativas **eletrônicas (janela de ~36h)** e presenciais, calendário anual divulgado ✅; pautas, atas e decisões no portal; resoluções.
- **Coleta:** calendário (HTML) → pauta → atas. Atenção ao formato "reunião eletrônica": início/fim em datas distintas.
- **Spike:** onde ficam os votos e o resultado por item.

### 5.8 ANP ⚠️/✅
- **Fontes:** reuniões de Diretoria (calendário ✅), pautas/atas ⚠️, dados abertos da ANP ⚠️ (produção, preços, autorizações), resoluções ⚠️, consultas/audiências públicas ⚠️.
- **Valor:** forte componente de **dados setoriais** (cruzar processo com autorizações e empresas).

### 5.9 ANM ⚠️/✅
- **Fontes:** reuniões de Diretoria (calendário ✅); processos minerários no sistema próprio (SEI + sistemas de cadastro mineiro) ⚠️.
- **Spike:** diferenciar processo administrativo regulatório de processo minerário (títulos/direitos), que é outro universo de dados.

### 5.10 ANA ⚠️
- **Fontes:** reuniões da Diretoria Colegiada; calendário 2026 ausente do site em jan/2026 ✅ (risco de cobertura irregular); resoluções, normas de referência de saneamento ⚠️.
- **Estratégia:** cobertura "melhor esforço" até validar regularidade de publicação.

### 5.11 ANS ⚠️
- **Fontes:** Dicol (reuniões e pautas), resoluções normativas (RN), processo administrativo eletrônico/Pesquisa Pública do SEI previsto em norma própria ⚠️; estudo de 2022 classificou o acesso ao SEI da ANS como "difícil" ⚠️.
- **Estratégia:** priorizar pautas/atas e normas; andamento via e-mail do cliente.

### 5.12 ANCINE ⚠️
- **Fontes:** Diretoria Colegiada, pautas e deliberações, sistemas próprios do setor (ex.: registro e fomento) ⚠️; SEI historicamente de "difícil acesso" ⚠️.
- **Estratégia:** igual à ANS.

---

## 6. Transformação: como cada informação vira tela

Template de cada "linha de produção" (usar como padrão em todo coletor):

```
[FONTE] → [COLETOR] → [PARSER] → [NORMALIZAÇÃO] → [TABELA] → [REGRA/IA] → [VIEW GOLD] → [TELA]
```

| Informação | Fonte típica | Parser / IA | Tabela | View Gold | Como aparece no Cortex |
|---|---|---|---|---|---|
| Reunião (data, nº, modalidade) | Calendário/pauta | Regex + Claude (fallback) | `meetings` | `v_agenda` | Calendário regulatório |
| Item de pauta (NUP, assunto, relator, unidade) | Pauta PDF / dataset | Claude → JSON validado por schema | `agenda_items` | `v_pauta_item` | Pauta com link ao processo |
| Resultado da reunião | Ata / acórdão | Claude extrai decisão + justificativa | `decisions` | `v_decisao` | "O que foi decidido" + link à fonte |
| Etapa do processo | Eventos (pauta, ata, SEI, e-mail) | Mapa evento→etapa normalizada | `process_events` | `v_timeline` | Linha do tempo step-by-step |
| Tipo de processo | Assunto + texto | Classificador Claude + taxonomia por agência | `processes.tipo_id` | `v_processo` | Rótulo + confiança |
| Prazo estimado | Histórico de duração | SQL estatístico (seção 8) | `duration_stats` | `v_prazo` | Faixa P25–P75 + n de casos |
| Perfil de dirigente | Site oficial, Lattes, DOU | Extração de bio + datas | `people` | `v_pessoa` | "Quem é quem" |
| Casos similares | Embeddings + filtros | Busca vetorial + regras | `similar_cases` | `v_similares` | Lista de 20+ comparáveis |
| Pontos de atenção | Comparação de decisões | RAG com citação obrigatória | `ai_extractions` | `v_atencao` | Cartão "possível divergência" + trecho citado |
| Alertas | Eventos novos | Regras (diff) | `alerts` | `v_alertas_cliente` | Sino + e-mail |

**Etapas normalizadas (taxonomia comum, mapeada por agência):**
`Protocolo → Instrução técnica → Análise jurídica (Procuradoria) → Consulta/Audiência pública → Pauta publicada → Sorteio/Designação de relator → Deliberação da diretoria → Publicação do ato → Recurso/Reconsideração → Encerrado`
(Cada agência mapeia seus termos para estas etapas; o que não mapear fica como `Outros` com texto original preservado.)

---

## 7. Pipeline de IA (Claude API) — regras

1. **Saída sempre em JSON com schema** (validar com Zod/Pydantic). Se não validar → fila de revisão, nunca grava em Silver.
2. **Citação obrigatória:** todo campo extraído e toda análise carrega `fonte_doc_id` + trecho + página.
3. **Separar extração de raciocínio:** (a) extrair fatos → grava; (b) analisar/comparar → grava como "análise" com versão do prompt.
4. **Modelo por tarefa:** modelo menor/mais barato para extração em lote e classificação; modelo maior para comparação e resumo jurídico. Medir custo por 1.000 documentos antes do backfill.
5. **Golden set:** 30–50 documentos por agência rotulados à mão (a base de testes). Todo prompt novo roda contra o golden set antes de ir a produção.
6. **"Contradições" = "pontos de atenção":** nunca veredito. Texto do produto: *"Em casos anteriores, a agência decidiu X (fonte). Neste processo, o encaminhamento atual é Y (fonte)."*
7. **Dados restritos/sigilosos nunca vão para a IA.** Se `restrito = true`, bloqueia no pipeline.
8. **Custos:** estimar tokens do backfill (3 anos × agência × nº de documentos) e fixar teto mensal por agência.

---

## 8. Inteligência de prazo (metodologia)

Problema clássico: se você calcular só a média de processos **já concluídos**, a estimativa fica **otimista demais**, porque os processos longos ainda não terminaram (dados censurados).

**Método recomendado (simples e honesto):**
1. **Definir "similar":** mesma agência + mesmo `tipo` (+ filtros opcionais: área técnica, faixa de complexidade). Mínimo **n ≥ 20**. Se n < 20, relaxar em degraus: `tipo → família → agência` e **mostrar o degrau usado**.
2. **Duração base:** `concluido_em − aberto_em` em dias corridos (e opcionalmente em dias úteis).
3. **Estatística:** P25, mediana (P50), P75 — não média (outliers distorcem).
4. **Condicional à idade atual:** para um processo com *t* dias, estimar o **restante** usando apenas similares cuja duração total > *t*.
5. **Tratar censura:** incluir processos em andamento via **Kaplan-Meier** (ou, no MVP, exibir também "% ainda em aberto com mais de *t* dias").
6. **Saída ao usuário:** faixa ("entre X e Y meses, com base em *n* casos") + nível de confiança (n, dispersão) + **lista dos casos usados** (transparência).
7. **Regras regulamentares sobrepõem estatística** quando existirem (ex.: prazos de relator na ANTAQ).
8. **Rótulos:** "acima da mediana", "dentro da faixa", "abaixo da mediana".

---

## 9. Workflows N8N (a preparar)

Padrão de todo workflow: `Trigger → Buscar → Hash/idempotência → Gravar bronze → Chamar parser → Upsert silver → Log em ingestion_runs → (erro) → WF-90`.

| ID | Nome | Gatilho | O que faz |
|---|---|---|---|
| WF-00 | Orquestrador / healthcheck | Cron 15 min | Checa fontes atrasadas, dispara coletores |
| WF-10…21 | Coletor por agência (um por agência) | Cron diário + extra em dia de reunião | Detecta novos documentos/dados da agência |
| WF-30 | Parser de documento | Webhook (novo `raw_document`) | Chama Worker/Edge Fn para texto + estrutura |
| WF-31 | Enriquecimento IA | Fila (lote) | Classificação de tipo, etapa, resumo, embeddings |
| WF-40 | Alertas ao cliente | Evento (novo `process_event`/`agenda_item`) | Cruza com `client_processes` → e-mail/WhatsApp |
| WF-41 | Aviso prévio de reunião | Cron diário | D-2/D-1: "seu processo está na pauta de amanhã" |
| WF-50 | Digest semanal | Cron semanal | Resumo por cliente |
| WF-60 | Backfill histórico | Manual, em lotes | 3 anos por agência, com teto de custo e janela noturna |
| WF-70 | Ingestão por e-mail | Gmail trigger | Parseia notificações SEI encaminhadas pelo cliente |
| WF-90 | Tratamento de erro | Error trigger | Registra, alerta (e-mail/Slack), dead-letter |

**Alarmes obrigatórios:** zero registros inesperado; queda de volume > 50% vs. média; schema da fonte mudou; falha de parser > X%; custo de IA acima do teto.

> **Dica prática:** o conector do N8N que você já tem permite criar, validar e **testar workflows com dados "pinados"** (sem bater nos sites reais). Dá para preparar todos os WF em paralelo ao Lovable.

---

## 10. Testar o fluxo inteiro sem esperar o Lovable

**Contrato de dados (o que o Lovable vai consumir):**
- Somente **views `v_*` e RPCs** (funções SQL), nunca tabelas cruas.
- Tipos TypeScript gerados do schema (`supabase gen types`).
- RLS ativa desde o dia 1; usuários de teste por cliente.
- **Seed realista:** rodar o coletor da ANEEL (e depois ANTAQ) e popular o Supabase com dados reais. O Lovable já nasce com dados de verdade.

**Pirâmide de testes**
1. **Parsers (unit):** PDFs reais salvos como *fixtures* → asserts sobre campos extraídos.
2. **Contrato/schema:** saída do Claude validada contra JSON Schema.
3. **Integração N8N:** execução com pin data → confere linhas no Supabase.
4. **E2E de agência:** "dia de reunião simulado" — injeta uma pauta nova e verifica: gravou → alertou → apareceu em `v_agenda`.
5. **RLS:** teste automatizado de que o Cliente A não enxerga nada do Cliente B.
6. **Avaliação de IA:** golden set com métricas (precisão de NUP, relator, resultado, tipo).

**Front de teste temporário (opcional):** Supabase Studio + Metabase/Streamlit simples para o time conferir dados antes do Lovable existir.

---

## 11. LGPD, jurídico e compliance (checklist)

> Isto é um roteiro técnico. **Faça revisão com advogado de proteção de dados antes de comercializar.**

- **Natureza dos dados:** processos e pautas são públicos, mas contêm **dados pessoais** (nomes de partes, representantes, servidores, dirigentes).
- **Base legal (a documentar no RIPD):** tratamento de dados de acesso público considera a finalidade e a boa-fé que justificaram sua publicação (LGPD art. 7º §§3º e 4º); **legítimo interesse** (art. 7º, IX) para monitoramento regulatório, com teste de proporcionalidade documentado ⚠️ (validar com jurídico).
- **Minimização:** guardar só o necessário; mascarar CPF, endereços, telefones e e-mails de pessoas físicas encontrados em PDFs; **não exibir** dado pessoal que o cliente não precisa ver.
- **Retenção:** política escrita (ex.: dados públicos por X anos; dados do cliente conforme contrato; descarte documentado).
- **Relatório de Impacto (RIPD)** e **registro das operações** (art. 37/38); definir **encarregado (DPO)**.
- **Direitos dos titulares:** canal para solicitação de exclusão/correção (art. 18), com processo interno.
- **Dirigentes e servidores (módulo "quem é quem"):** usar fontes oficiais (site da agência, DOU, Lattes/currículos publicados, sabatina no Senado). **Evitar scraping de LinkedIn** e redes sociais. Limitar a dados funcionais e profissionais.
- **Segredo e restrição:** processos `restritos` (sigilo comercial/fiscal/etc.) **não são coletados** e **não vão para a IA**. Se o cliente fornecer documento restrito dele mesmo, fica em espaço isolado do cliente.
- **Contratos:** DPA com Supabase, Anthropic, N8N (se cloud), provedor do worker; verificar região/transferência internacional de dados.
- **Segurança:** RLS, segredos em vault, logs de auditoria (quem viu o quê), backups, MFA no admin.
- **Termos de uso das fontes e LAI:** respeitar limites de acesso; usar LAI quando necessário.
- **Responsabilidade do produto:** aviso claro de que prazo estimado e pontos de atenção são **apoio à decisão, não parecer jurídico**; sempre exibir a fonte.

---

## 12. Spike obrigatório (Sprint 0) — 1 dia por agência

Preencher uma ficha por agência antes de escrever qualquer coletor definitivo:

1. URL exata das páginas de **calendário, pautas, atas, votos/decisões**.
2. Formato (API, CSV, HTML estático, HTML dinâmico, PDF texto, PDF escaneado).
3. Existe **dataset aberto** equivalente? Tem API? Qual paginação e limite?
4. Como é o **nº do processo** e quais prefixos aparecem.
5. A pauta traz **relator, unidade responsável, assunto**?
6. Onde está o **resultado** (ata, acórdão, extrato) e quanto tempo após a reunião?
7. **SEI Pesquisa Pública:** existe? captcha? mostra andamento? lista documentos? (apenas **documentar**, não automatizar.)
8. Histórico disponível: até que ano dá para voltar? (meta: 3 anos)
9. Termos de uso / robots.txt / limite de taxa.
10. 5 PDFs de amostra salvos como fixtures + nota de dificuldade (1–5).

**Entregável do spike:** `docs/agencias/<sigla>.md` + matriz geral "campo × agência × fonte × confiança". É isso que transforma os ⚠️ deste documento em ✅.

---

## 13. Skills e agents recomendados para o Claude Code

> Estrutura proposta: subagentes em `.claude/agents/` e skills em `.claude/skills/`. Os nomes abaixo são **sugestões de papéis a criar** (use o `skill-creator` quando for transformá-los em skills reais).

### 13.1 Subagentes (um papel por agente, escopo curto)

| Agente | Missão | Ferramentas |
|---|---|---|
| `agency-recon` | Fazer o spike de uma agência e escrever a ficha (seção 12) | Playwright MCP / web fetch, leitura de PDFs |
| `scraper-engineer` | Escrever e manter coletores (Python/Playwright), com idempotência e rate limit | Bash, Playwright, testes |
| `pdf-parser` | Extração de texto/OCR e parsers de pauta/ata por agência | PyMuPDF, Tesseract, pytest com fixtures |
| `data-modeler` | Migrações SQL, índices, RLS, views `v_*`, seeds | Supabase MCP / CLI |
| `ai-pipeline` | Prompts, schemas, classificador de tipo, RAG, golden set e avaliação | Claude API, pytest |
| `n8n-builder` | Criar/validar/testar workflows (WF-xx) | Conector N8N |
| `lgpd-reviewer` | Revisar PRs contra o checklist de LGPD, minimização, retenção, RLS | Somente leitura + relatório |
| `qa-e2e` | Cenário "dia de reunião simulado", testes de RLS, regressão | Bash, Supabase, N8N test |
| `frontend-contract` | Escrever o contrato para Lovable: telas, views, tipos, prompts | Leitura do schema |
| `security-reviewer` | Segredos, injection, SSRF no worker, permissões | Somente leitura |

Exemplo mínimo de definição:

```markdown
---
name: lgpd-reviewer
description: Revisa mudanças que tocam dados pessoais, retenção, RLS e envio para IA. Use proativamente em todo PR que altere schema, coletores ou prompts.
tools: Read, Grep, Glob
---
Você revisa conformidade com a LGPD no projeto Cortex.
Cheque: (1) minimização e mascaramento de CPF/contatos, (2) processos restritos nunca vão à IA,
(3) RLS por client_id em toda tabela de cliente, (4) política de retenção, (5) fonte citada em toda análise.
Saída: lista de achados com severidade (bloqueia/alerta/sugestão), arquivo:linha e correção sugerida.
```

### 13.2 Skills (conhecimento reutilizável)

| Skill | Conteúdo |
|---|---|
| `cortex-agency-playbooks` | As fichas por agência (seção 5 + spike) |
| `cortex-nup-parser` | Regex/validação de NUP, prefixos por agência, casos de borda |
| `cortex-data-contract` | Schema, views `v_*`, convenções de nomes, versionamento |
| `cortex-lgpd-checklist` | Seção 11 como checklist executável |
| `cortex-ai-extraction` | Prompts versionados, schemas JSON, regras de citação, golden set |
| `cortex-duration-method` | Metodologia da seção 8 com exemplos SQL |
| `cortex-n8n-patterns` | Padrões WF (idempotência, retry, alarmes) |
| `cortex-lovable-handoff` | Como gerar o prompt/briefing para o Lovable a partir das views |

### 13.3 MCPs e conectores úteis
- **Supabase** (migrações, SQL, tipos), **N8N** (você já tem conectado), **Playwright** (inspeção de portais), **GitHub** (PRs/CI), leitura de PDFs.
- **Hooks do Claude Code:** `pre-commit` rodando testes de parser + lint SQL; bloqueio de commit com segredos.

### 13.4 `CLAUDE.md` inicial (resumo)
```
Projeto: Cortex — monitoramento regulatório de 12 agências.
Regras: (1) nunca contornar captcha; (2) toda coleta idempotente e com hash; (3) toda saída de IA
valida schema e cita fonte; (4) dados restritos nunca vão à IA; (5) RLS em tudo que é de cliente;
(6) N8N orquestra, lógica fica em código testado; (7) cada agência tem ficha em docs/agencias/.
Comandos: make test | make migrate | make seed | make e2e
```

---

## 14. Onde hospedar cada peça

| Peça | Recomendação inicial | Quando mudar |
|---|---|---|
| Banco, Auth, Storage, Edge Functions | **Supabase** (região São Paulo, se disponível ⚠️) | — |
| Orquestração | **N8N** (cloud que você já usa) | Self-host se custo/volume exigir |
| Worker (Playwright/OCR) | **Railway / Fly / Cloud Run** (container) | Mais volume → fila + múltiplos workers |
| Front | **Lovable** (hospedagem própria) | **Vercel** só se exportar o código para repositório próprio (Next.js), precisar de domínio/white-label avançado, SSR ou controle de build |
| Observabilidade | Logs do Supabase + `ingestion_runs` + alertas N8N | Sentry/Better Stack quando crescer |

---

## 15. Roadmap sugerido

| Fase | Duração (estimativa grosseira) | Entrega |
|---|---|---|
| **0 — Spike** | 1–2 semanas | Fichas das 12 agências + matriz de viabilidade + fixtures |
| **1 — Fundação** | 1–2 semanas | Schema, RLS, parser de NUP, CLAUDE.md, subagentes, CI de testes |
| **2 — Piloto ANEEL** | 2–3 semanas | Coleta de pautas/atas/decisões, relatores, agenda, alertas por e-mail, seed para Lovable |
| **3 — Lovable v1 (em paralelo à 2)** | 3–4 semanas | Visão geral, agenda, linha do tempo, painel do cliente |
| **4 — ANTAQ, ANTT, ANVISA** | 4–6 semanas | 3 agências adicionais |
| **5 — Analisar** | 4–6 semanas | Prazo (seção 8), perfil de dirigentes, busca + backfill 3 anos nas agências ativas |
| **6 — Antecipar** | 4–6 semanas | Casos similares, RAG, "pontos de atenção" com revisão humana |
| **7 — Escala** | contínuo | Demais agências, white-label, relatórios mensais |

Prazos dependem fortemente do resultado do Spike.

---

## 16. Valor para clientes (resumo)

- **Quem compra:** reguladas (energia, telecom, saúde, O&G, transporte, mineração, dados), escritórios e consultorias regulatórias, associações setoriais, áreas de RI/GR.
- **O que entrega:** menos risco (nenhuma pauta/prazo perdido), previsibilidade (faixa de prazo com base em casos), inteligência sobre quem decide, economia de horas de analista.
- **Planos:** Básico (monitoramento + alertas), Premium (prazo + comparativo + relatório mensal), Enterprise/White-label (consultorias). Cobrança por processos monitorados e agências cobertas + setup de backfill.
- **Diferencial:** a maioria entrega coleta e alerta; o Cortex entrega **Monitorar → Analisar → Antecipar**, sempre com fonte citada.

---

## 17. Riscos principais e mitigação

| Risco | Mitigação |
|---|---|
| Portais mudam e coletor quebra | Alarmes de zero/queda, fixtures, testes de regressão, `ingestion_runs` |
| Captcha/restrição no SEI | Não contornar; e-mail do cliente + acesso do cliente + dados abertos + LAI |
| Qualidade da classificação do "tipo" | Taxonomia por agência, golden set, revisão humana de baixa confiança |
| Custo de IA no backfill | Teto por agência, modelo menor para extração, lotes noturnos |
| Promessa jurídica excessiva | Texto de produto neutro, fonte sempre visível, "apoio à decisão" |
| LGPD | Seção 11 + revisão jurídica antes da venda |
| Cobertura desigual entre agências (ANA, ANS, ANCINE) | Comunicar "nível de cobertura" por agência no produto |

---

## 18. Prompt inicial sugerido para o Claude Code

```
Leia este documento inteiro (cortex-plano-tecnico.md). Objetivo: executar a Fase 0 e a Fase 1.

1) Crie o repositório com a estrutura: /docs/agencias, /supabase/migrations, /workers, /parsers,
   /n8n, /tests/fixtures, /.claude/agents, /.claude/skills, CLAUDE.md (seção 13.4).
2) Fase 0: para cada uma das 12 agências, crie docs/agencias/<sigla>.md seguindo a seção 12.
   Comece por ANEEL, ANTAQ, ANTT e ANVISA. Salve 5 PDFs/amostras por agência em tests/fixtures.
   NÃO automatize o SEI Pesquisa Pública nem contorne captcha; apenas documente.
3) Fase 1: gere as migrações do schema da seção 4 (com RLS), o parser de NUP com testes,
   as views v_* mínimas e um seed. Gere os tipos TypeScript.
4) Crie os subagentes e skills da seção 13 (versão inicial enxuta).
5) Ao final, atualize a matriz de viabilidade (campo × agência × fonte × confiança) e liste
   as decisões pendentes para eu aprovar.
Regras: siga as "Regras de ouro" da seção 2 e o checklist da seção 11 em todo PR.
```

---

## 19. Fontes consultadas nesta pesquisa

- Lei 15.352/2026 (ANPD como agência) e texto da Lei 13.848/2019 (decisão colegiada; reuniões públicas e gravadas): Planalto/Câmara/portais jurídicos.
- ANEEL: Portal de Dados Abertos (pautas e atas desde 2017, API); pautas em PDF de 2025/2026; apresentação de transparência ativa (reuniões públicas, sorteio de relator); cobertura da imprensa setorial sobre redistribuição de processos.
- ANATEL: Plano de Dados Abertos 2025–2027 (Teletime); página de Dados Abertos (gov.br/anatel); decisão CMRI com referência ao SEI Pesquisa Pública.
- ANTAQ: pautas externas e atas de reuniões 606–615 (gov.br/antaq); decisão CMRI sobre acesso a processos; revisão da Resolução 66/2022 (abr/2026).
- ANTT: pauta da 1.040ª Reunião de Diretoria Pública (27/08/2026); Datalegis.
- ANVISA: pautas e atas Dicol/ROP (2019–2025); página "Processos deliberados"; agenda regulatória.
- ANPD: manual SEI/ANPD e Módulo de Pesquisa Pública (mar/2025); Nota Técnica 20/2026 (proposta de agenda regulatória).
- Calendário de reuniões 2026 das agências de infraestrutura (Agência iNFRA, jan/2026).
- Estudo UFCG (2022) sobre acesso ao SEI por usuário externo em agências (dado de 2022; validar).
- Manuais de SEI de outros órgãos (Pesquisa Pública com captcha; acesso externo para processos restritos).

*Itens marcados com ⚠️ não foram confirmados em fontes primárias nesta pesquisa e devem ser validados no Spike.*
