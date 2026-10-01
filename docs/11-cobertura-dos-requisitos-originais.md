# 11 — Cobertura dos requisitos originais (8 módulos) × MVP

Legenda: **MVP** = no kit atual · **v1.5** = depois do piloto, ainda sem IA · **v2** = exige IA/revisão humana ou dado que ainda não sabemos se existe.
"Limite de verdade" = o que impede o dado de ser completo ou 100% confiável.

| # | Requisito original | Fase | Limite de verdade / dependência |
|---|---|---|---|
| **1. Visão Geral** | | | |
| 1.1 | Processos em andamento por agência/área técnica/superintendência | **MVP (parcial)** | Não existe fonte pública com **todos** os processos da agência. Mostramos os **monitorados** e os que aparecem em pautas/atas/dados abertos. Área técnica: pauta traz (ANEEL "Área Responsável", ANP "Unidade Autora", ANTAQ "Unidade Técnica" ✅) |
| 1.2 | Status e etapa atual | **MVP** | Etapa vem dos eventos conhecidos; sem andamento do SEI, a etapa pode estar defasada (mostrar "última movimentação conhecida em…") |
| 1.3 | Tempo de tramitação e previsão de conclusão | **v1.5** | Exige data de abertura/conclusão publicada (⚠️ validar no Spike) e ≥ 20 similares |
| 1.4 | Processos recentes e movimentações relevantes | **MVP** | — |
| 1.5 | Alertas (novos processos, mudança de status, reuniões) | **MVP** | E-mail via N8N; "novos processos" = os que aparecem em fonte pública |
| **2. Mapeamento do Processo** | | | |
| 2.1 | Linha do tempo step-by-step | **MVP (parcial)** | Público: pauta/ata/acórdão/DOU. Fino (nota técnica, despacho): **importação assistida** e e-mail do SEI (captcha impede automação) |
| 2.2 | Histórico de movimentações e decisões | **MVP** | Idem |
| 2.3 | Área técnica/superintendência responsável | **MVP** | Onde a pauta/ata informa |
| 2.4 | Datas de entrada, movimentações, reuniões, conclusão | **MVP (parcial)** | Data de entrada/conclusão só onde publicada |
| 2.5 | Etapa atual e **próximas etapas previstas** | **v1.5/v2** | Exige modelo de fluxo por tipo de processo (começar por sequência estatística observada no histórico) |
| **3. Inteligência de Prazo** | | | |
| 3.1–3.5 | Tempo médio, comparação com 20+ similares, estimativa, acima/abaixo da média, histórico por tipo | **v1.5** | Classificação de tipo por regra + histórico por agência + datas de abertura/conclusão; método em `04` §12 |
| **4. Agenda Regulatória** | | | |
| 4.1–4.5 | Calendário, aviso por e-mail, link da pauta, reunião↔pauta↔processo, resultado | **MVP** | Pauta ≠ resultado (extrapauta, adiamento) — tratado em `10` |
| **5. Inteligência sobre Agências** | | | |
| 5.1 | Perfil de dirigentes | **MVP** | Página oficial de composição + DOU |
| 5.2 | Currículo do diretor responsável | **MVP (resumo)** | Bio oficial/sabatina no Senado; currículo completo só se publicado oficialmente (sem LinkedIn) |
| 5.3 | Currículo do superintendente/área técnica | **v1.5 (parcial)** | Bios de superintendentes raramente são publicadas ⚠️ |
| 5.4 | Histórico de atuação em processos | **MVP** | Relatorias (L1) e votos (L2) onde publicados |
| 5.5 | "Quem é quem" (organograma) | **v1.5** | Páginas institucionais |
| **6. Busca e Banco de Dados** | | | |
| 6.1 | Busca avançada (processo, empresa, agência, tema, responsável) | **v1.5** (MVP: NUP/assunto/agência) | "Empresa" = interessados extraídos de pauta (ANTAQ "Interessados:" ✅), varia por agência |
| 6.2 | Banco histórico ≥ 3 anos | **MVP→v1.5, por agência** | Backfill por agência; profundidade depende do que cada portal mantém |
| 6.3 | Processos anteriores e casos semelhantes | **MVP** | Por tipo de processo |
| 6.4 | Cruzamento processo×decisão×reunião×pauta | **MVP** | Modelo relacional já cobre |
| **7. Inteligência Comparativa** | | | |
| 7.1 | Processos semelhantes anteriores | **MVP** | Qualidade depende da classificação por regra |
| 7.2 | Comparação entre decisões/encaminhamentos | **v1.5** | Tabela lado a lado por tipo (sem IA) |
| 7.3 | Padrões de atuação da agência | **MVP** | Taxas e histórico por diretor/tipo, sempre com *n* |
| 7.4 | Divergências/contradições | **v2** | Exige leitura de votos/justificativas (IA + **revisão humana**); apresentar como "ponto de atenção" com citação |
| 7.5 | Análise das justificativas | **v2** | Idem |
| **8. Visão do Cliente** | | | |
| 8.1–8.7 | Processos monitorados, status/etapa, marcos e reuniões, prazo estimado, responsáveis, histórico, alertas | **MVP** (prazo: **v1.5**) | "Ações necessárias" = alertas + prazos regulamentares conhecidos |

## Leitura honesta
- **Monitorar:** forte no MVP (agenda, pauta, decisão, alertas). O ponto fraco é o **andamento fino do SEI**.
- **Analisar:** parcialmente no MVP (taxas, histórico por diretor, similares). Prazo e busca avançada vêm depois do piloto.
- **Antecipar:** no MVP é **estatístico e conservador** (histórico em casos semelhantes). Previsão de próximas etapas e detecção de contradições dependem de v1.5/v2.
