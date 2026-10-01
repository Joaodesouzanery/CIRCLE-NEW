# 00 — Visão da plataforma e escopo do MVP

## 1. Nome e conceito
Nome no mockup: **Circle — Better Regulation** (codinome interno: Cortex). Ajuste se o nome mudar.

> Transformar o acompanhamento regulatório de coleta de processos em ferramenta de inteligência:
> **MONITORAR → ANALISAR → ANTECIPAR**.

| Camada | No MVP (sem IA) | Fica para depois |
|---|---|---|
| Monitorar | Consulta de processo, linha do tempo de andamentos, agenda de reuniões/pautas, alertas | Cobertura das 12 agências |
| Analisar | Taxa de deferimento em processos semelhantes, histórico de votos por diretor, perfil de diretores | Busca avançada, banco histórico completo de 3 anos em todas as agências |
| Antecipar | Indicadores estatísticos de casos semelhantes ("histórico favorável/desfavorável", sempre com *n* e fonte) | Prazo estimado (v1.5), RAG, resumos e pontos de atenção com IA |

## 2. Usuários
- Analistas de regulatório/Relações Governamentais de empresas reguladas (infra: rodovias, ferrovias, portos, aeroportos).
- Escritórios e consultorias regulatórias (multi-cliente → white-label no futuro).

## 3. Redução de módulos: de 8 itens de menu do mockup para 4
O mockup tem: Visão Geral, Meus Processos, Agenda Regulatória, Agências, Diretores, Análise e Histórico, Relatórios, Configurações.

| # | Tela do MVP | Absorve | Justificativa |
|---|---|---|---|
| 1 | **Meus Processos** (página inicial) | Visão Geral + Análise e Histórico (do processo) | O mockup já concentra KPIs, andamentos, agenda e análises nesta página |
| 2 | **Agenda Regulatória** | — | Reuniões e pautas de todas as agências; é o módulo mais fácil de vender |
| 3 | **Agências e Diretores** | Agências + Diretores | Uma tela: lista de agências → diretores → perfil e histórico de votos |
| 4 | **Configurações** | — | Clientes, processos monitorados, interesses/alertas, **saúde das coletas** (admin) |
| — | ~~Relatórios~~ | adiado (v2) | Exportar PDF/CSV depois que os dados estiverem confiáveis |
| — | ~~Visão Geral~~ | adiado (v2) | Só faz sentido com várias agências e muitos processos |

## 4. Fora do escopo do MVP
IA/LLM; RAG; resumo automático de documentos; detecção de "contradições"; busca textual avançada; relatórios em PDF;
white-label; WhatsApp; agências estaduais (ARTESP entra como cadastro, coleta só depois do Spike).

## 5. Princípios de produto
1. **Fonte sempre visível:** cada dado tem link para o documento original.
2. **Honestidade estatística:** todo percentual mostra o *n* de casos e o nível de evidência (alta/média/baixa).
3. **Nada de veredito:** o produto mostra histórico e contexto; não promete resultado nem substitui parecer jurídico.
4. **Cobertura transparente:** cada agência exibe seu nível de cobertura (o que é coletado e o que não é).

## 6. Glossário
- **NUP**: Número Único de Protocolo do SEI, formato `NNNNN.NNNNNN/AAAA-DD` (ex.: `50500.123456/2024-78`).
- **SEI**: Sistema Eletrônico de Informações (processo eletrônico das agências).
- **Pauta / Ata**: lista de itens a deliberar / registro do que foi deliberado na reunião da diretoria.
- **Acórdão**: decisão colegiada numerada (ex.: ANTAQ "Acórdão nº 440-2026-ANTAQ").
- **Relator**: diretor responsável por levar o processo à deliberação.
- **Dicol / Conselho Diretor / Diretoria Colegiada**: colegiado decisório (varia por agência).
- **Pleito**: pedido de uma parte (requerimento, recurso, reequilíbrio...). Só pleitos entram na "taxa de deferimento".
