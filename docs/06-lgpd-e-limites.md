# 06 — LGPD, limites técnicos e jurídicos

> Roteiro técnico. **Revisão por advogado de proteção de dados antes de comercializar.**

## 1. Natureza dos dados
Processos, pautas e decisões são públicos, mas contêm **dados pessoais** (partes, representantes, servidores, dirigentes).
Dirigentes são agentes públicos: dados **funcionais** (cargo, mandato, votos em sessão pública, bio oficial) são o núcleo do módulo.

## 2. Bases e minimização
- Base a documentar no RIPD: tratamento de dado de acesso público considerando finalidade/boa-fé da publicação (LGPD art. 7º §§3º e 4º) e **legítimo interesse** (art. 7º, IX) com teste de proporcionalidade ⚠️ (validar com jurídico).
- Minimização: mascarar CPF, endereço, telefone e e-mail de pessoas físicas em PDFs; **não** armazenar nem exibir o que o cliente não precisa.
- Não coletar: processos **restritos/sigilosos**, dados sensíveis, redes sociais/LinkedIn de dirigentes.
- Retenção: política escrita (dados públicos por prazo definido; dados do cliente conforme contrato; descarte documentado).
- Encarregado (DPO), RIPD, registro das operações, canal para direitos do titular (art. 18).

## 3. Captcha e limites de coleta
- **Proibido** contornar captcha ou usar serviço de resolução. SEI Pesquisa Pública = só documentar.
- Respeitar robots.txt/termos; rate limit (≤ 1 req/2 s por domínio); User-Agent identificável; janelas fora do horário comercial para backfill.
- Via legítima para andamento fino: importação assistida (cliente interessado), e-mail encaminhado, acesso externo do **próprio cliente** (⚠️ avaliar termos antes de qualquer automação com credencial de cliente — por padrão **não automatizar**).
- LAI (Lei 12.527/2011) quando não houver outra via.

## 4. Redação do produto (importante)
- O mockup usa "Projeção de Votos", "Tendência de Aprovar/Rejeitar" e "Confiança da projeção". **Recomendação:** usar
  "Histórico em casos semelhantes", "Histórico favorável/desfavorável ao deferimento", "Base: n casos". Evita promessa de resultado,
  reduz risco jurídico/reputacional e é mais honesto estatisticamente (ver `04`, seção 7).
- Rodapé fixo: *"Análises baseadas em dados públicos e decisões anteriores. Não constituem previsão de resultado nem parecer jurídico."*

## 5. Fotos e bios de dirigentes
- Padrão: **iniciais**. Foto só se houver fonte oficial (`foto_url` + `foto_fonte`) e validação jurídica de reuso comercial.
- Bio: resumo factual com link para a fonte oficial; sem adjetivação nem inferência política.

## 6. Segurança
RLS em todas as tabelas de cliente; `service_role` fora do front; logs de auditoria; backups; MFA no admin; a lista de processos monitorados de um cliente é **sigilo comercial** (nunca cruzar entre clientes).

## 7. Contratos
DPA/termos com Supabase, GitHub, provedor de e-mail, Lovable e N8N (se nuvem). Conferir região e transferência internacional.
