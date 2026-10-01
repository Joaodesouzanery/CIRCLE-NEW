# 05 — Spike por agência (1 dia cada) — transforma ⚠️ em ✅

Crie `docs/agencias/<sigla>.md` com este modelo e salve **5 amostras reais** em `tests/fixtures/<sigla>/`.

```markdown
# <SIGLA> — ficha de viabilidade (data, responsável)

## Fontes
| Tipo | URL exata | Formato | Atualização | Paginação/limite | robots/termos |
|---|---|---|---|---|---|
| Calendário de reuniões | | HTML/PDF/API | | | |
| Pautas | | | | | |
| Atas | | | | | |
| Acórdãos/decisões/votos | | | | | |
| Dataset aberto (API/CSV) | | | | | |
| Composição da diretoria | | | | | |
| DOU (atos da agência) | | | | | |

## Perguntas
1. Formato do NUP e prefixos que aparecem.
2. A pauta traz relator? unidade técnica? assunto? interessado? bloco?
3. Onde está o resultado por item e quanto tempo depois da reunião?
4. **Nível de voto: L0 / L1 / L2?** (evidência: trecho + link)
5. Há data de abertura/conclusão de processo em alguma fonte pública?
6. Histórico disponível: até que ano (meta: 3 anos)?
7. SEI Pesquisa Pública: existe? captcha? mostra andamento? (apenas documentar)
8. Reuniões virtuais/eletrônicas (janela de dias)? Como representar início/fim?
9. Mudanças recentes de site/layout (risco de quebra)?

## Amostras (arquivos em tests/fixtures/<sigla>/)
- [ ] pauta_1  - [ ] pauta_2  - [ ] ata_1  - [ ] ata_2  - [ ] acórdão/decisão

## Veredito
Dificuldade (1–5): __ · Método principal: api|csv|html|pdf|playwright · Nível de voto: __ · Pronto para coletor? sim/não · Riscos:
```

## Matriz final (entregável do Spike)
`docs/matriz-viabilidade.md`: linhas = campos do item 1 de `03`; colunas = agências; célula = ✅ fonte/URL · 🟡 parcial · ❌ indisponível.
Atualizar `agencies.nivel_voto` e `sources` conforme as fichas.

## Critério de saída
ANTAQ, ANTT, ANEEL, ANVISA com ficha completa + fixtures + nível de voto definido; lista de decisões pendentes entregue para aprovação.
