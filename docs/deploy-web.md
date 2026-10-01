# Deploy do front (`web/`) — Vercel (ainda NÃO feito)

Decisão: o front (React + Vite) fica neste repositório em `web/` e será publicado no **Vercel**. O Lovable não edita este código.

## Passos (quando for publicar)
1. Vercel → *Add New Project* → importar `CIRCLE-NEW`. **Root Directory: `web`**. Framework: Vite (build `npm run build`, saída `dist`).
2. *Environment Variables* (Production e Preview):
   - `VITE_SUPABASE_URL` = `https://hdzaorefzgkhzcdxrlzy.supabase.co`
   - `VITE_SUPABASE_ANON_KEY` = chave **publishable/anon** (Supabase → Project Settings → API Keys). **Nunca** a `service_role`.
   - `VITE_USE_MOCKS` = `false`
3. Rotas do SPA: adicionar `web/vercel.json` com rewrite `/(.*)` → `/index.html` (necessário para `/agenda`, `/agencias`).
4. Supabase → Authentication → URL Configuration: *Site URL* = domínio do Vercel; *Redirect URLs* = domínio de produção e `https://*-<time>.vercel.app/**` (previews).
5. Ativar *Leaked password protection* (Auth → Providers/Passwords).

## Rodar localmente
```
cd web && cp .env.example .env   # preencher VITE_SUPABASE_ANON_KEY (publishable)
npm install && npm run dev       # http://localhost:5173
```
`web/.env` está no `.gitignore`. A chave anon é pública por desenho (vai no navegador); a proteção é o RLS.
Sem `.env`, o app roda em modo offline com dados fictícios (`VITE_USE_MOCKS=true`).
