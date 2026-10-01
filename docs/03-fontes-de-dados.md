# 03 — O que buscar na internet (fontes, campos, padrões)

✅ = observado em fontes públicas (out/2026) · ⚠️ = validar no Spike. **Nunca** automatizar captcha. Respeitar robots.txt e termos.

## 1. Entidades-alvo (o que o sistema precisa extrair, em qualquer agência)

| Entidade | Campos | Onde costuma estar |
|---|---|---|
| Reunião | órgão, nº, ano, tipo, modalidade, início/fim, link da pauta/ata/vídeo | calendário, página de reuniões, cabeçalho da pauta |
| Item de pauta | item_ref, NUP, assunto, interessado, relator, unidade técnica, bloco, retirado/incluído, natureza | pauta (PDF/HTML) |
| Resultado | resultado_tipo, texto, nº do acórdão/decisão, data | ata, acórdão, extrato de decisão |
| Voto | diretor, voto (deferimento/indeferimento/abstenção/impedido/ausente), papel (relator/membro), acompanhou relator | ata/voto/acórdão (**só onde publicado**) |
| Processo | NUP, assunto, interessados, tipo, unidade, relator, datas | pauta, ata, dataset aberto, DOU |
| Evento/andamento | data, etapa, título, unidade, documento (rótulo+URL) | pauta/ata (públicos); SEI (importação); e-mail |
| Pessoa | nome, cargo, função, mandato, mini-bio, fonte | página "Composição da Diretoria", DOU (nomeações), sabatina no Senado |
| Norma/decisão | tipo, número, ano, data, ementa, link | DOU, sistemas de legislação da agência |
| Consulta/audiência pública | nº, título, abertura, encerramento, link | página de consultas da agência |

## 2. Padrões universais (regex de partida)
```
NUP (com ou sem pontuação):   \b(\d{5})\.?(\d{6})/?(\d{4})-?(\d{2})\b
Reunião ordinária nº:         (\d{1,4})[ªa°º]?\s+Reuni[ãa]o\s+(Ordin[áa]ria|Extraordin[áa]ria|P[úu]blica)
Acórdão ANTAQ:               AC[ÓO]RD[ÃA]O\s+N[º°]\s*(\d+)-(\d{4})-ANTAQ
Período (virtual):            de\s+(\d{2}/\d{2}/\d{4})\s+(?:às|a)\s+.*?(\d{2}/\d{2}/\d{4})
Retirado de pauta:            (?i)retirad[oa]s?\s+de\s+pauta
Item hierárquico (ANVISA):    \b\d+(?:\.\d+){1,4}\b
Data por extenso (ata):       (\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})
```
Prefixos de NUP por agência: ANEEL 48500 ✅ · ANTAQ 50300 ✅ · ANTT 50500 ✅ · ANVISA 25351 ✅ · ANATEL 53500 ✅ · ANPD 00261 ✅ · **ANP 48610 ✅ · ANS 33910 ✅** · demais ⚠️.
Use o prefixo para validar a agência do processo e **sinalizar** NUPs que não casam.

---
## 3. ANTAQ (prioridade 1 — ✅ bem mapeada)
**Entrada:** `https://www.gov.br/antaq/pt-br/acesso-a-informacao/institucional/reunioes-deliberativas` ✅ (PDFs de pauta e ata ficam nesta pasta; os nomes de arquivo variam — ex.: `PautadaROD610.pdf`, `AtaROD615.pdf`, `copy_of_AtaROD613.pdf` — **não confie em padrão de nome; rastreie a página de listagem**).
**Característica:** reuniões ordinárias numeradas (ex.: 606, 610, 613, 615), em geral **virtuais em janela de ~3 dias** ✅.

**Pauta Externa (PDF)** — campos observados ✅:
- Cabeçalho: "NNNª Reunião Ordinária Virtual – Pauta Externa", "Período: 14h de DD/MM/AAAA às 17h de DD/MM/AAAA".
- Por item: **NUP**, "Contextualização:", "Tipo: Finalístico: …" (ex.: Auto de Infração de Ofício), "Interessados:", referência a recursos ("Recurso de Reconsideração … Acórdão nº X/AAAA"), TAC (Termo de Compromisso de Ajustamento de Conduta), consulta pública, homologação de deliberação do Diretor-Geral, referência a acórdão do TCU.
- Rodapé: "Pauta de Reunião de Diretoria … SEI nnnnnnn".

**Ata (PDF)** — campos observados ✅:
- "ATA DA REUNIÃO DE DIRETORIA REALIZADA ENTRE D E D DE MÊS DE AAAA", presidência (Diretor-Geral), presença do Procurador-Chefe, "Reunião Ordinária da Diretoria Colegiada da ANTAQ de nº N".
- Seção **"PROCESSOS RETIRADOS DE PAUTA"** com NUPs e o diretor relator.
- Blocos **"ACÓRDÃO Nº X-AAAA-ANTAQ"**: `Processo:` (NUP) · `Unidade Técnica:` · razões "expostas pelo Relator/Relatora" · `Data da Reunião: DD a DD/MM/AAAA - Virtual`.
- A ata lista a faixa de acórdãos aprovados (ex.: "Acórdãos de nºs 440 a 471").

**Extrair → tabelas:** `meetings` (nº, período, modalidade=virtual) · `agenda_items` (NUP, tipo→natureza, retirado) · `decisions` (acórdão nº/ano, NUP, data) · `processes` (NUP, assunto) · `people` (relatores).
**Normas úteis:** Resolução ANTAQ 66/2022 (andamento de processos na diretoria; alterada em abr/2026: prazo do relator 30→60 dias após a instrução técnica) ✅ → alimenta regra de prazo regulamentar (v1.5).
**SEI:** `sei.antaq.gov.br` tem Pesquisa Pública por NUP; processos restritos só para interessados cadastrados ✅ — **somente documentar**.
**Voto individual:** ⚠️ verificar se a ata/acórdão registra divergência/voto de cada diretor (provável L1: relator + resultado).

## 4. ANTT (prioridade 1 — ✅ parcialmente mapeada)
**Reuniões:** "Reunião de Diretoria Pública" numerada (ex.: 1.040ª em 27/08/2026, 14h30) ✅; calendário anual divulgado (ex.: reunião em 15/01/2026) ✅.
**Pauta:** publicada como **documento SEI** (rodapé "Pauta da Reunião de Diretoria nnnnnnnn · SEI 50500.nnnnnn/AAAA-DD"), com links `sei.antt.gov.br/sei/controlador_externo.php?acao=documento_conferir…` ✅.
Campos: "Assunto:" por item (ex.: revisão de estatuto da auditoria interna; abertura de edital de processo competitivo; free flow em concessões rodoviárias; chamamento público e autorização com referência a acórdão do TCU) ✅.
**Normas/atos:** sistema **Datalegis** `anttlegis.antt.gov.br` ✅ (⚠️ verificar se há listagem estruturada/exportável).
**Entrada das reuniões:** ⚠️ localizar a página oficial de "Reuniões de Diretoria" em `gov.br/antt` (Spike).
**Particularidade:** muita matéria é **concessão/leilão/relicitação** (ciclos longos, interação com o TCU) — mapear `natureza = outorga_concessao` e **excluir** da taxa de deferimento.
**Voto individual:** ⚠️ verificar ata/extrato de decisão (L1 ou L2?). O regimento prevê que o **relator vota primeiro** e que há pedido de vista e impedimento ✅ (padrão comum às agências).
**Atenção:** a pauta não é o resultado — já houve item votado **extrapauta** e deliberação **adiada** (ex.: concessão ViaBahia, jan/2026) ✅. Modelar `situacao` (ver `10`).

## 5. ANEEL (prioridade 2 — ✅ melhor caso técnico)
**Dados abertos:** Portal de Dados Abertos da ANEEL, com **API**; conjunto **"Pautas e Atas das Reuniões Públicas da Diretoria" desde set/2017** ✅ (inclui datas, processos discutidos, decisões e atos publicados) e base de penalidades ✅. Domínio do portal: ⚠️ confirmar (provável `dadosabertos.aneel.gov.br`).
**Pauta (PDF)** — rótulos observados ✅: "PAUTA DA NNª REUNIÃO PÚBLICA ORDINÁRIA DA DIRETORIA DE AAAA", "Data da Reunião", `Processo:` (NUP 48500.…), `Assunto:`, **`Área Responsável:`** (sigla da superintendência, ex.: SMA, STD, SCE), **`Diretor(a)-Relator(a):`**, "BLOCO DA PAUTA", "O processo foi retirado de pauta".
**Pós-reunião:** votos, memórias de reunião, atas e atos administrativos ✅. **Sorteio de relator** e redistribuição na troca de diretor ✅.
**Voto individual:** itens "em bloco" têm posicionamentos dos diretores antecipados ✅ → provável **L2** (⚠️ confirmar no dataset/votos).
**Tipo de reunião:** ordinárias numeradas por ano (ex.: 39ª de 2025), geralmente às terças ✅.

## 6. ANVISA (prioridade 2 — ✅ bem estruturada)
**Reuniões:** Dicol — **Reunião Ordinária Pública (ROP)** numerada por ano (ex.: ROP nº 18 de 07/11/2025, por videoconferência) ✅.
**Base de URLs:** `https://www.gov.br/anvisa/pt-br/composicao/diretoria-colegiada/reunioes-da-diretoria/` com subpastas `pautas/`, `atas/`, `processos/` ("Processos deliberados") ✅.
**Pauta:** itens com **numeração hierárquica** (ex.: 2.4.10, 3.3.5.1), marcações "retirado de pauta pelo Relator", "incluído em pauta", "mantido em pauta", "reunião anterior / decisão anterior", citação de **Sessões de Julgamento (SJO/GGREC)** para recursos ✅; rodapé "Pauta de Reunião da Dicol … SEI 25351.nnnnnn/AAAA-DD" ✅.
**Regras úteis (confirmar no regimento vigente ⚠️):** inscrição para sustentação oral/pedido de sigilo com antecedência mínima de 2 dias úteis; manifestações publicadas até 3 dias antes; 10 min por processo para sustentação ✅ (texto de pautas anteriores).
**Outros:** "Temas com deliberação final em Dicol" e minutas (Agenda Regulatória) ✅ → `regulatory_agenda`/consultas.
**Voto individual:** ⚠️ verificar atas (provável L1/L2).

## 7. ANATEL, ANAC, ANP, ANM, ANA, ANS, ANCINE, ANPD, ARTESP (Spike antes de codar)

| Agência | O que já sabemos | O que validar |
|---|---|---|
| ANATEL ✅ | Conselho Diretor; reuniões abertas e transmitidas; Plano de Dados Abertos 2025–2027 prevê base "Textos Públicos" (documentos públicos do SEI, atos, processos encerrados — previsão dez/2025) e "PACs de Ressarcimento"; SACP para consultas públicas; NUP 53500 | Se "Textos Públicos" já foi publicada (seria a melhor fonte de histórico); onde ficam pautas/atas |
| ANAC ✅/⚠️ | Reuniões deliberativas **eletrônicas** (janela de ~36 h) e presenciais, calendário anual | Onde ficam pautas, votos e resultados; prefixo NUP |
| **ANP ✅ (forte candidata a L2)** | Reuniões de Diretoria numeradas (ex.: 1.177ª em 27/02/2026; 1.178ª em 13/03/2026); **atas em PDF** em `gov.br/anp/pt-br/composicao/diretoria-colegiada/reunioes-da-diretoria-colegiada/pautas-atas-e-calendario-de-reunioes-da-diretoria-colegiada/2026/arquivos-rd-2026/ata-NNNN.pdf`; NUP **48610**; cada item traz **Unidade Autora (superintendência), Diretor-Relator e Deliberação**; registra **votos divergentes nomeados**, adesões, pedido de vista, ausências e voto enviado por escrito ✅ | Pautas e calendário; dados abertos |
| ANM ⚠️ | Reuniões de diretoria com calendário (ex.: 28/01/2026) | Distinguir processo regulatório de processo minerário |
| ANA ⚠️ | Calendário 2026 não estava publicado no site em jan/2026 | Regularidade de publicação |
| **ANS ✅/⚠️** | **Extrato de Ata** de Reunião Ordinária de Diretoria Colegiada (ex.: 636ª em 24/04/2026) publicado como documento SEI; NUP **33910**; traz presentes, `Processo:`, `Assunto:`, `Decisão: Aprovado por unanimidade o Voto nº/AAAA/DIRETORIA`; **aviso de que o texto pode mudar até a aprovação da minuta da ata** ✅ → `resultado_provisorio`. SEI historicamente de acesso difícil (estudo 2022 ⚠️) | Pautas; onde ficam os extratos; Pesquisa Pública |
| ANCINE ⚠️ | Idem ANS | Pautas/deliberações |
| ANPD ✅ | Conselho Diretor; SEI/ANPD com Pesquisa Pública; Agenda Regulatória 2025–2026 (16 temas) e nova proposta (NT 20/2026); NUP 00261 | Atas/decisões do Conselho; sancionadores públicos |
| ARTESP ⚠️ | **Estadual** (SP) — aparece no mockup | Existência de pauta/atas públicas; incluir só após Spike |

## 8. Fontes transversais
- **DOU — use o INLABS** (`inlabs.in.gov.br`): edições completas em **XML e PDF, gratuito desde 01/01/2020**, com login/cadastro e scripts oficiais (Python/Bash) ✅. Não faça scraping do portal de busca (a Imprensa Nacional bloqueou buscas automatizadas em jan/2023 ✅). Filtrar por órgão/seção; guardar o XML original.
- **Portal Brasileiro de Dados Abertos (dados.gov.br):** tem **API REST** (Swagger) para listar conjuntos por organização ✅ → use para descobrir datasets de cada agência no Spike.
- **E-mails automáticos do SEI:** o SEI notifica o usuário externo (acesso externo liberado, intimação eletrônica, documento para assinatura) com o **número do processo** ✅ — base do REG-07 (formato por agência ⚠️, pedir amostras).
- **Senado Federal**: sabatinas e indicações de diretores (mini-bio e mandato).
- **Sites das agências — "Composição da Diretoria"**: nome, cargo, mandato, bio oficial.
- **Lattes/currículos publicados pelo próprio dirigente**: apenas se linkado em fonte oficial. **Não** coletar LinkedIn/redes sociais.
- **TCU** (acórdãos citados em pautas): v2.

## 9. Como transformar (padrão de cada coletor)
```
listar página/dataset → detectar documento novo (URL + hash) → baixar → Storage (bronze) → texto (pdfplumber; OCR se vazio)
→ parser da agência → objetos normalizados → upsert idempotente (chaves naturais) → eventos (process_events)
→ run em ingestion_runs (+ alarme se zero) → notificações (pg_cron)
```
**Chaves naturais:** reunião `(agency, orgao, tipo, ano, numero)` · item `(meeting, item_ref)` · processo `nup_normalizado` ·
decisão `(agency, tipo, ano, numero)` · evento `dedupe_hash` · documento `sha256`.

## 10. Classificação por regra (sem IA)
`process_types.palavras_chave` + regras por agência. Exemplos de semente:
- **ANTAQ:** auto de infração → sancionador · TAC → administrativo/pleito ⚠️ · recurso de reconsideração → pleito (recurso) · consulta pública/resolução → normativo · leilão/arrendamento/terminal → outorga_concessao · homologação de deliberação do DG → administrativo.
- **ANTT:** revisão de tarifa/reequilíbrio/pedido de revisão → pleito · edital/leilão/relicitação/chamamento/autorização/contrato → outorga_concessao · estatuto/auditoria interna → administrativo · norma/resolução/AIR → normativo.
Mantenha as regras em tabela/arquivo versionado (`collectors/<sigla>/rules.yaml`) com testes.
