# 10 — Qualidade e veracidade dos dados

## 1. Princípio
Nenhum sistema que lê portais públicos consegue **garantir** 100% de acerto. O que se garante é: (a) **verificabilidade** (toda linha tem fonte e pode ser conferida em 1 clique), (b) **medição** (acurácia medida, não presumida), (c) **detecção rápida** de falhas e (d) **honestidade na tela** (o que é provisório, incompleto ou desconhecido aparece como tal). Dado desconhecido é `null` com motivo — **nunca inferido**.

## 2. Cadeia de confiança
```
Fonte oficial → documento original (bronze, imutável, sha256) → parser versionado (parser_version)
→ validações (estrutura, completude, consistência) → linha com proveniência (documento + página)
→ tela com "Fonte", "Atualizado em" e selo de qualidade da agência
```

## 3. Camadas de verificação
| # | Camada | Como | Onde implementar |
|---|---|---|---|
| 1 | **Estrutural** | NUP no formato e com prefixo da agência; datas plausíveis; enums válidos | parser + `CHECK` no banco + `v_dq_anomalias` |
| 2 | **Completude** | Comparar o que o documento **declara** com o que foi **extraído**. Ex. real (ANTAQ): a ata diz "Acórdãos de nºs 440 a 471 e 473 a 475" ✅ → esperado = 35; se o parser achou 33, alerta. Reuniões numeradas sem "buracos" na sequência (606, 610, 613, 615…) | `raw_documents.esperado_n/extraido_n` → regra `contagem_divergente` |
| 3 | **Consistência cruzada** | Todo item deliberado estava na pauta **ou** está marcado `extrapauta`; resultado × voto; ANEEL dataset × PDF da pauta; DOU × portal da agência | regras SQL + testes |
| 4 | **Frescor** | SLA por fonte (`sources.sla_horas`); fonte atrasada = alerta | `v_ingestion_health` + REG-02 + `healthcheck.yml` |
| 5 | **Deriva de layout** | Queda de `parse_confidence`, campos obrigatórios ausentes, nº de itens muito abaixo da média | parser grava `parse_confidence` e abre `data_quality_issues` |
| 6 | **Auditoria humana por amostragem** | 20 itens/semana conferidos contra a fonte | `rpc_audit_sample` + REG-05 (planilha) |
| 7 | **Regressão (golden set)** | Fixtures reais por agência com resultado esperado; todo parser novo/alterado roda nelas | `tests/fixtures` + pytest |
| 8 | **Processos-âncora** | 5–10 processos **reais do cliente-piloto** cujo andamento o cliente conhece; o sistema deve reproduzir o que ele sabe | aceite do piloto |

## 4. Campos críticos (erro aqui é inaceitável) × secundários
- **Críticos:** NUP, agência, data/hora e nº da reunião, relator, resultado (deferido/indeferido…), voto individual, link da fonte.
- **Secundários:** assunto (texto), tema/setor (classificação), bio de dirigente.
- **Meta de acurácia (a definir com o PM ⚠️):** críticos ≥ 98% na auditoria semanal; abaixo disso, a agência recebe selo "em revisão" na tela.

## 5. Casos reais encontrados na pesquisa que quebram suposições ingênuas
| Caso | Evidência | Consequência no modelo |
|---|---|---|
| **Pauta ≠ o que foi deliberado** | Processo votado "extrapauta" e outro adiado na ANTT (ViaBahia, jan/2026) ✅; "retirados de pauta" em ANTAQ/ANVISA/ANEEL ✅; pedido de vista na ANP ✅ | `agenda_items.situacao` (`pauta/deliberado/adiado/pedido_vista/retirado/extrapauta`) |
| **Resultado provisório** | Extrato de ata da ANS: "este texto pode ser alterado em função da aprovação da minuta de Ata" ✅ | `resultado_provisorio` até a ata aprovada |
| **Pauta republicada** | ANVISA publica "pauta … republicada" com alterações ✅ | cada versão tem `sha256` próprio; `meetings.pauta_doc_id` aponta a mais recente; evento "Pauta republicada" |
| **Reunião eletrônica/virtual em vários dias** | ANTAQ (janela de 3 dias) e ANAC (janela de ~36 h) ✅ | `meetings.inicio/fim`, `modalidade` |
| **Semântica de voto varia** | ANP: diretor ausente enviou votos ao DG para apresentação ✅; ANAC (regimento de 2007 ⚠️ vigência): manifestação escrita de ausente "não tem valor de voto" | regra por agência; `director_votes.observacao`; `ausente` ≠ voto |
| **Unanimidade** | ANS: "Aprovado por unanimidade" + lista de presentes ✅ | `agenda_items.unanime`; votos preenchidos **só** para presentes listados |
| **Divergências nomeadas** | ANP: "apresentaram votos divergentes … o Diretor X … o Diretor Y aderiu ao voto do Diretor Z" ✅ | `observacao` com a adesão; L2 viável |

## 6. Política de dúvida
Parser inseguro → grava o que tem certeza, `null` no resto, `parse_status='parcial'`, abre `data_quality_issues` (severidade conforme campo). Nada de "chute". A tela mostra "não confirmado".

## 7. Correção e versionamento
Reprocessar com parser novo **não apaga** histórico: grava `parser_version` e atualiza por chave natural. Correção manual é registrada (quem, quando, motivo). Erros descobertos geram caso novo na fixture (regressão).

## 8. O que o usuário vê
"Fonte" (link) em cada linha · "Atualizado em" por agência · selo de **cobertura** (fontes ativas, nível de voto) · selo de **qualidade** (resultado da última auditoria) · marca "resultado provisório" quando aplicável.

## 9. Métricas operacionais (painel admin)
% de itens com fonte (meta 100%) · acurácia por campo no golden set e na auditoria · taxa de parse OK · atraso médio por fonte · nº de anomalias abertas por severidade · tempo médio de resolução.

## 10. Rotina
Diário: REG-04 (anomalias) + REG-02 (frescor). Semanal: REG-05 (20 itens). A cada parser alterado: golden set. Mensal: revisão das metas e das regras por agência.
