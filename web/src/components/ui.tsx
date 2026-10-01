import type { ReactNode } from 'react'

export function Card({ title, icon, action, children, className = '' }: { title: string; icon?: ReactNode; action?: ReactNode; children: ReactNode; className?: string }) {
  return (
    <section className={`card ${className}`}>
      <header className="flex items-center justify-between mb-4">
        <h2 className="flex items-center gap-2 font-semibold text-[17px] text-ink">{icon}{title}</h2>
        {action}
      </header>
      {children}
    </section>
  )
}
export function State({ loading, error, empty, children }: { loading: boolean; error?: string; empty?: string | false; children: ReactNode }) {
  if (loading) return <div className="space-y-2 animate-pulse">{[0, 1, 2].map((i) => <div key={i} className="h-8 rounded-lg bg-canvas" />)}</div>
  if (error) return <p className="text-sm text-bad">Erro ao carregar: {error}</p>
  if (empty) return <p className="text-sm text-ink-soft">{empty}</p>
  return <>{children}</>
}
const tones = { ok: 'bg-ok-soft text-ok', brand: 'bg-brand-soft text-brand', warn: 'bg-warn-soft text-warn', bad: 'bg-bad-soft text-bad', neutral: 'bg-canvas text-ink-soft' }
export const Chip = ({ tone = 'neutral', children }: { tone?: keyof typeof tones; children: ReactNode }) => <span className={`chip ${tones[tone]}`}>{children}</span>

const palette = ['#173F86', '#0E9F6E', '#7A4BD6', '#C2571A', '#0A7EA4']
export function Avatar({ nome, fotoUrl, fotoFonte, size = 64 }: { nome: string; fotoUrl?: string | null; fotoFonte?: string | null; size?: number }) {
  const initials = nome.replace(/\[.*?\]/g, '').split(' ').filter((p) => p && !['de', 'da', 'do', 'dos', 'das'].includes(p.toLowerCase())).slice(0, 2).map((p) => p[0]).join('').toUpperCase() || '?'
  const bg = palette[[...nome].reduce((a, c) => a + c.charCodeAt(0), 0) % palette.length]
  // Foto só com fonte oficial registrada (docs/06); caso contrário, iniciais.
  if (fotoUrl && fotoFonte) return <img src={fotoUrl} alt={nome} title={`Fonte: ${fotoFonte}`} style={{ width: size, height: size }} className="shrink-0 rounded-full object-cover ring-4 ring-white shadow" />
  return <div style={{ width: size, height: size, background: `linear-gradient(135deg, ${bg}, #0B2350)`, fontSize: size * 0.34 }} className="shrink-0 rounded-full grid place-items-center text-white font-semibold ring-4 ring-white shadow">{initials}</div>
}
export function Bar({ pct, tone }: { pct: number; tone: 'ok' | 'warn' | 'bad' }) {
  const c = { ok: 'bg-ok', warn: 'bg-warn', bad: 'bg-bad' }[tone]
  return <div className="h-1.5 rounded-full bg-canvas overflow-hidden"><div className={`h-full rounded-full ${c}`} style={{ width: `${pct}%` }} /></div>
}
export function Donut({ pct, label }: { pct: number; label: string }) {
  const r = 52, c = 2 * Math.PI * r
  return (
    <svg viewBox="0 0 140 140" className="w-40 h-40" role="img" aria-label={`${pct}% ${label}`}>
      <circle cx="70" cy="70" r={r} fill="none" stroke="#C9D1E0" strokeWidth="22" />
      <circle cx="70" cy="70" r={r} fill="none" stroke="#0E9F6E" strokeWidth="22" strokeDasharray={`${(pct / 100) * c} ${c}`} transform="rotate(-90 70 70)" />
      <text x="70" y="76" textAnchor="middle" className="fill-ink font-bold" fontSize="24">{pct}%</text>
    </svg>
  )
}
// Rótulo neutro por regra de docs/04 §7 (n<10 => dados insuficientes)
export function voteLabel(pct: number, n: number): { text: string; tone: 'ok' | 'warn' | 'bad' | 'neutral' } {
  if (n < 10) return { text: 'Dados insuficientes', tone: 'neutral' }
  if (pct >= 60) return { text: 'Histórico favorável ao deferimento', tone: 'ok' }
  if (pct <= 40) return { text: 'Histórico desfavorável ao deferimento', tone: 'bad' }
  return { text: 'Indefinido', tone: 'warn' }
}
