import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../auth'

const nav = [
  { to: '/', label: 'Meus Processos', d: 'M7 3h7l5 5v13H7zM14 3v5h5' },
  { to: '/agenda', label: 'Agenda Regulatória', d: 'M4 6h16v14H4zM4 10h16M8 3v5M16 3v5' },
  { to: '/agencias', label: 'Agências e Diretores', d: 'M3 10l9-6 9 6M5 10v9M10 10v9M14 10v9M19 10v9M3 21h18' },
  { to: '/configuracoes', label: 'Configurações', d: 'M12 8a4 4 0 100 8 4 4 0 000-8zM12 2v3M12 19v3M2 12h3M19 12h3' },
]
const crumbs: Record<string, string> = { '/': 'Meus Processos', '/agenda': 'Agenda Regulatória', '/agencias': 'Agências e Diretores', '/configuracoes': 'Configurações' }

export default function Layout() {
  const { pathname } = useLocation()
  const { client, email, signOut } = useAuth()
  const isDemo = client?.nome.startsWith('[DEMO]')
  return (
    <div className="min-h-screen flex">
      <aside className="hidden md:flex w-64 shrink-0 flex-col bg-gradient-to-b from-navy-900 to-navy-950 text-white sticky top-0 h-screen self-start">
        <div className="px-5 pt-6 pb-8">
          {/* logo é branca sobre fundo preto: 'lighten' funde o preto com o azul-marinho */}
          <img src="/circle-logo.png" alt="Circle — Better Regulation" className="w-44 mix-blend-lighten" />
        </div>
        <nav className="flex-1 px-3 space-y-1">
          {nav.map((n) => (
            <NavLink key={n.to} to={n.to} end={n.to === '/'} className={({ isActive }) => `flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition ${isActive ? 'bg-brand text-white shadow-lg shadow-brand/30' : 'text-white/75 hover:bg-white/10'}`}>
              <svg viewBox="0 0 24 24" className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d={n.d} /></svg>
              {n.label}
            </NavLink>
          ))}
        </nav>
        <p className="px-5 py-4 text-[11px] text-white/40">Monitorar → Analisar → Antecipar</p>
      </aside>
      <div className="flex-1 min-w-0 flex flex-col">
        <header className="h-16 bg-white/80 backdrop-blur border-b border-black/5 flex items-center justify-between px-6 sticky top-0 z-10">
          <p className="text-sm text-ink-soft">Dashboard <span className="mx-2">›</span><span className="text-brand font-semibold">{crumbs[pathname] ?? ''}</span></p>
          <div className="flex items-center gap-3">
            <span className="rounded-lg border border-black/10 bg-white px-3 py-1.5 text-sm" aria-label="Cliente">{client?.nome ?? '—'}</span>
            <button aria-label="Notificações" className="relative p-2 rounded-lg hover:bg-canvas">
              <svg viewBox="0 0 24 24" className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M6 17V11a6 6 0 1112 0v6l1.5 2h-15zM10 21h4" /></svg>
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-bad" />
            </button>
            <button onClick={signOut} title={`${email ?? ''} — sair`} className="w-9 h-9 rounded-full bg-navy-900 text-white grid place-items-center text-sm font-semibold">{(email ?? '?')[0].toUpperCase()}</button>
          </div>
        </header>
        {isDemo && <div className="bg-warn-soft text-warn text-sm font-medium px-6 py-2 border-b border-warn/20">Dados de demonstração — NUPs 99999.*, diretores e decisões fictícios. Nenhuma informação real.</div>}
        <main className="flex-1 p-6"><Outlet /></main>
        <footer className="px-6 py-4 text-xs text-ink-faint border-t border-black/5 bg-white">Análises baseadas em dados públicos e decisões anteriores. Não constituem previsão de resultado nem parecer jurídico.</footer>
      </div>
    </div>
  )
}
