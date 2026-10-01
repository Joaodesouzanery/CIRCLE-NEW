"""Teste de conectividade com os portais das agências (Spike, bloco E).
Registra código HTTP, tempo, tamanho, sinais de WAF/captcha e o robots.txt. Respeita ≤ 1 req / 2 s por domínio.
Uso: CONTACT_EMAIL=voce@dominio python scripts/connectivity_check.py [saida_dir]
"""
import json, os, re, sys, time, urllib.parse, urllib.request

CONTACT = os.environ.get("CONTACT_EMAIL", "contato@example.invalid")
UA = f"CircleBot/0.1 (+monitoramento regulatorio; contato: {CONTACT})"
URLS = {
    "ANTAQ": ["https://www.gov.br/antaq/pt-br/acesso-a-informacao/institucional/reunioes-deliberativas"],
    "ANTT": ["https://www.gov.br/antt/pt-br", "https://dados.antt.gov.br/"],
    "ANEEL": ["https://www.gov.br/aneel/pt-br", "https://dadosabertos.aneel.gov.br/"],
    "ANVISA": ["https://www.gov.br/anvisa/pt-br/composicao/diretoria-colegiada/reunioes-da-diretoria/"],
    "ANP": ["https://www.gov.br/anp/pt-br", "https://dados.gov.br/"],
    "DOU/INLABS": ["https://inlabs.in.gov.br/"],
}
WAF = [("cloudflare", r"cloudflare|cf-ray"), ("akamai", r"akamai"), ("incapsula", r"incapsula|imperva"),
       ("captcha", r"captcha|hcaptcha|recaptcha"), ("acesso_negado", r"access denied|acesso negado|forbidden")]
out = sys.argv[1] if len(sys.argv) > 1 else "spike_out"
os.makedirs(out, exist_ok=True)
last = {}

def fetch(url):
    host = urllib.parse.urlparse(url).netloc
    wait = 2 - (time.time() - last.get(host, 0))
    if wait > 0: time.sleep(wait)
    last[host] = time.time()
    t0 = time.time()
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "text/html,application/pdf,*/*"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            body = r.read(2_000_000); hdr = str(r.headers)
            return dict(url=url, final=r.geturl(), status=r.status, seg=round(time.time() - t0, 2), bytes=len(body),
                        sinais=[n for n, rx in WAF if re.search(rx, hdr + body[:20000].decode("latin-1"), re.I)]), body
    except Exception as e:  # HTTPError/URLError/timeout
        code = getattr(e, "code", None)
        return dict(url=url, final=None, status=code, seg=round(time.time() - t0, 2), bytes=0, erro=f"{type(e).__name__}: {e}"[:200], sinais=[]), b""

rows = []
for ag, urls in URLS.items():
    for u in urls:
        r, body = fetch(u); r["agencia"] = ag; rows.append(r)
        if body: open(os.path.join(out, re.sub(r"\W+", "_", u)[:80] + ".html"), "wb").write(body[:500_000])
        p = urllib.parse.urlparse(u); rb, rbody = fetch(f"{p.scheme}://{p.netloc}/robots.txt")
        r["robots_status"] = rb["status"]
        if rbody: open(os.path.join(out, re.sub(r"\W+", "_", p.netloc) + "_robots.txt"), "wb").write(rbody)
json.dump(rows, open(os.path.join(out, "conectividade.json"), "w"), ensure_ascii=False, indent=2)
with open(os.path.join(out, "conectividade.md"), "w") as f:
    f.write("| Agência | URL | HTTP | Tempo(s) | Bytes | Sinais WAF/captcha | robots.txt | Erro |\n|---|---|---|---|---|---|---|---|\n")
    for r in rows:
        f.write(f"| {r['agencia']} | {r['url']} | {r['status']} | {r['seg']} | {r['bytes']} | {', '.join(r['sinais']) or '-'} | {r.get('robots_status')} | {r.get('erro','')} |\n")
print(open(os.path.join(out, "conectividade.md")).read())
