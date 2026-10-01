# 12 — Teste de conectividade com os portais (Spike, bloco E)

**Status: INCONCLUSIVO.** O teste foi rodado no ambiente de desenvolvimento do Claude Code (sandbox cloud) e **todas** as URLs falharam com
`Tunnel connection failed: 403 Forbidden` — é o *proxy de saída do sandbox* negando o destino (política de rede do ambiente), **não** evidência de que o portal bloqueia IPs.
O mesmo sandbox também nega `*.supabase.co` diretamente no navegador. Portanto a hipótese "portais .gov.br bloqueiam datacenter/fora do Brasil" **continua não confirmada**.

## Como confirmar (1 clique)
GitHub → Actions → **spike-conectividade** → *Run workflow*. Ele roda `scripts/connectivity_check.py` num runner do GitHub
(IP de datacenter nos EUA — o pior caso), imprime a tabela (HTTP, tempo, bytes, sinais de WAF/captcha, robots.txt) e anexa os arquivos baixados como *artifact*.
(Opcional: definir a variável de repositório `CONTACT_EMAIL` para compor o User-Agent.)

## Decisão a tomar com o resultado
- HTTP 200 nos portais → manter GitHub Actions (ADR-1).
- 403/timeout/WAF → coleta precisa sair de IP brasileiro: runner self-hosted ou container em região de São Paulo (Cloud Run `southamerica-east1`, Fly `gru`). Reabrir ADR-1.

Resultado local (sandbox): ver `scripts/connectivity_check.py` — 9 URLs, 9× 403 do proxy.
