import { useState } from 'react'
import { api } from '../api'
import { useAuth } from '../auth'
import { fmtDate, useAsync } from '../hooks'
import type { AgendaRow, MyProcess } from '../types'
import { Avatar, Bar, Card, Chip, Donut, State, voteLabel } from './ui'

export function SearchBox({ onFound }: { onFound: (p: MyProcess) => void }) {
  const { client } = useAuth()
  const [q, setQ] = useState(''); const [err, setErr] = useState(''); const [busy, setBusy] = useState(false)
  const submit = async (e: React.FormEvent) => {
    e.preventDefault()
    const d = q.replace(/\D/g, '')
    if (d.length !== 17) { setErr('NUP inválido. Formato: NNNNN.NNNNNN/AAAA-DD'); return }
    setErr(''); setBusy(true)
    const nup = `${d.slice(0, 5)}.${d.slice(5, 11)}/${d.slice(11, 15)}-${d.slice(15)}`
    try {
      const p = await api.findProcess(client!.id, nup)
      if (p) onFound(p); else setErr('Este processo não está entre os monitorados. Em breve você poderá solicitá-lo; a coleta nas fontes públicas é feita pela plataforma.')
    } catch (x) { setErr(String((x as Error).message)) } finally { setBusy(false) }
  }
  return (
    <Card title="Consultar Processo">
      <form onSubmit={submit} className="flex gap-3">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Digite o número do processo (ex.: 50500.123456/2024-78)" className="flex-1 min-w-0 rounded-xl border border-black/10 px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-brand/40" />
        <button disabled={busy} className="rounded-xl bg-brand px-6 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-60">Buscar</button>
      </form>
      {err && <p className="mt-2 text-sm text-warn">{err}</p>}
    </Card>
  )
}

export function KpiCards() {
  const { client } = useAuth()
  const { data } = useAsync(() => api.kpis(client!.id), [client?.id])
  const items = [['Processos monitorados', data?.processos_monitorados, 'processos do cliente'], ['Próximas reuniões relevantes', data?.reunioes_30d, 'nos próximos 30 dias']] as const
  return <div className="grid grid-cols-2 gap-4">{items.map(([t, v, s]) => (
    <div key={t} className="card"><p className="text-sm font-semibold">{t}</p><p className="mt-2 text-4xl font-bold text-navy-900">{v ?? '–'}</p><p className="text-sm text-ink-soft truncate">{s}</p></div>
  ))}</div>
}

const dot: Record<string, string> = { deliberacao: 'bg-ok', nota_tecnica: 'bg-brand', manifestacao: 'bg-ok', distribuicao: 'bg-ok', autuacao: 'bg-ok' }
export function Timeline({ p, all, onPick }: { p: MyProcess; all: MyProcess[]; onPick: (p: MyProcess) => void }) {
  const { data, loading, error } = useAsync(() => api.timeline(p.process_id), [p.process_id])
  return (
    <Card title="Andamentos do Processo" action={all.length > 1 && (
      <select value={p.process_id} onChange={(e) => onPick(all.find((x) => x.process_id === e.target.value)!)} className="rounded-lg border border-black/10 bg-white px-2 py-1 text-sm max-w-[220px]" aria-label="Processo">
        {all.map((x) => <option key={x.process_id} value={x.process_id}>{x.nup}</option>)}
      </select>)}>
      <div className="flex items-start gap-3 mb-4">
        <div className="w-12 h-12 shrink-0 rounded-xl bg-brand-soft grid place-items-center text-brand">▤</div>
        <div>
          <p className="font-semibold">Processo {p.agencia} {p.nup}</p>
          {p.status === 'em_andamento' && <Chip tone="ok">Em andamento</Chip>}
          <p className="text-sm text-ink-soft mt-1">{p.assunto}</p>
          <p className="text-sm text-ink-soft">Interessado: {p.interessados.join(', ')}</p>
          <div className="mt-1 flex gap-1.5 flex-wrap"><Chip>{p.agencia}</Chip>{p.setor && <Chip>{p.setor}</Chip>}{p.tema && <Chip tone="warn">{p.tema}</Chip>}</div>
        </div>
      </div>
      <State loading={loading} error={error} empty={data?.length === 0 && 'Sem andamentos públicos ainda. Importe o andamento do SEI para completar a linha do tempo.'}>
        <ol className="relative border-l-2 border-canvas ml-1.5 space-y-4">
          {data?.map((e) => (
            <li key={e.event_id} className="pl-5 relative">
              <span className={`absolute -left-[7px] top-1.5 w-3 h-3 rounded-full ring-4 ring-white ${dot[e.etapa] ?? 'bg-ink-faint'}`} />
              <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1 text-sm">
                <span className="text-ink-soft w-24">{fmtDate(e.ocorrido_em)}</span>
                <span className="font-semibold w-28">{e.titulo}</span>
                <span className="flex-1 min-w-[200px]">{e.descricao}</span>
                {e.doc_url && <a href={e.doc_url} target="_blank" rel="noreferrer" className="text-brand hover:underline">{e.doc_rotulo} ↗</a>}
                <Chip tone={e.origem === 'sei_import' ? 'warn' : 'neutral'}>{e.origem === 'sei_import' ? 'Importado' : 'Fonte pública'}</Chip>
              </div>
            </li>
          ))}
        </ol>
      </State>
    </Card>
  )
}

const stTone = { confirmada: 'ok', prevista: 'brand', realizada: 'neutral', cancelada: 'bad' } as const
const stLabel = { confirmada: 'Confirmada', prevista: 'Prevista', realizada: 'Realizada', cancelada: 'Cancelada' } as const
const relLabel = { processo_monitorado: 'Processo monitorado', interesse: 'Interesse cadastrado' } as const
export function AgendaTable({ rows, compact = false }: { rows: AgendaRow[]; compact?: boolean }) {
  return (
    <div className="overflow-x-auto"><table className="w-full text-sm">
      <thead><tr className="text-left text-xs uppercase text-ink-faint">{['Data', 'Agência', 'Reunião', 'Pauta / Processo', 'Tema', 'Status'].map((h) => <th key={h} className="py-2 pr-3 font-medium">{h}</th>)}</tr></thead>
      <tbody>{rows.map((r) => (
        <tr key={(r.agenda_item_id ?? r.meeting_id) + (r.relevancia ?? '')} className="border-t border-canvas align-top">
          <td className="py-3 pr-3 whitespace-nowrap">{fmtDate(r.inicio)}</td>
          <td className="py-3 pr-3 font-semibold whitespace-nowrap">{r.agencia}</td>
          <td className="py-3 pr-3 min-w-[110px] capitalize">{r.orgao}</td>
          <td className="py-3 pr-3">{r.item_ref ? <>Item {r.item_ref}{r.nup && <><br /><span className="text-ink-soft">Proc. {r.nup}</span></>}</> : '–'}{!compact && r.fonte_url && <> <a href={r.fonte_url} target="_blank" rel="noreferrer" className="text-brand">pauta ↗</a></>}</td>
          <td className="py-3 pr-3">{r.assunto ?? r.tema}{r.relevancia && <><br /><span className="text-ink-soft text-xs">{relLabel[r.relevancia]}</span></>}</td>
          <td className="py-3 whitespace-nowrap"><Chip tone={stTone[r.status]}>{stLabel[r.status]}</Chip></td>
        </tr>))}</tbody>
    </table></div>
  )
}

export function AgendaCard() {
  const { client } = useAuth()
  const { data, loading, error } = useAsync(() => api.agenda(client!.id), [client?.id])
  const [tab, setTab] = useState('Todas')
  const agencias = [...new Set(data?.map((r) => r.agencia))]
  const rows = (data ?? []).filter((r) => tab === 'Todas' || r.agencia === tab)
  return (
    <Card title="Agenda de Reuniões que Impactam o Cliente">
      <div className="flex gap-2 mb-3 flex-wrap">{['Todas', ...agencias].map((t) => (
        <button key={t} onClick={() => setTab(t)} className={`rounded-lg px-3 py-1.5 text-sm ${tab === t ? 'bg-brand-soft text-brand font-semibold ring-1 ring-brand' : 'bg-canvas'}`}>
          {t} ({t === 'Todas' ? data?.length ?? 0 : data?.filter((r) => r.agencia === t).length})</button>))}</div>
      <State loading={loading} error={error} empty={rows.length === 0 && 'Nenhuma reunião relevante.'}><AgendaTable rows={rows} compact /></State>
    </Card>
  )
}

export function SimilarCard({ p }: { p: MyProcess }) {
  const { data, loading, error } = useAsync(() => api.similar(p.process_id), [p.process_id])
  const votes = useAsync(() => api.votes(p.process_id), [p.process_id])
  return (
    <Card title="Taxa de Deferimento em Processos Semelhantes">
      <State loading={loading} error={error} empty={(!data || data.n_casos === 0) && 'Sem casos semelhantes na base.'}>
        {data && <div className="flex items-center gap-6 flex-wrap">
          <Donut pct={data.pct_deferimento ?? 0} label="deferimento" />
          <div className="flex-1 min-w-[240px]">
            <p className="text-sm mb-1">Baseado em <b>{data.n_casos}</b> casos de mesmo tipo (últimos 3 anos) <Chip tone={data.evidencia === 'baixa' ? 'warn' : 'ok'}>Evidência {data.evidencia}</Chip></p>
            <p className="text-xs text-ink-soft mb-2">{data.deferidos} deferidos · {data.indeferidos} indeferidos · {data.parciais} parciais</p>
            {votes.data && votes.data.length > 0 && <div className="rounded-xl border border-canvas divide-y divide-canvas">{votes.data.map((v) => (
              <div key={v.person_id} className="flex items-center justify-between px-3 py-2 text-sm"><span>{v.nome} <span className="text-ink-faint">(n={v.n_casos})</span></span><span><b className="text-ok">{v.pct_deferimento}%</b> <span className="text-ink-faint">· {v.pct_indeferimento}%</span></span></div>))}</div>}
          </div>
        </div>}
      </State>
    </Card>
  )
}

export function VoteHistoryCard({ p, nivel }: { p: MyProcess; nivel: 'L0' | 'L1' | 'L2' }) {
  const { data, loading, error } = useAsync(() => api.votes(p.process_id), [p.process_id])
  return (
    <Card title="Histórico dos Diretores em Casos Semelhantes">
      {nivel !== 'L2' ? <p className="text-sm text-ink-soft">Esta agência não publica o voto individual de cada diretor; exibimos o resultado das decisões e o relator.</p> :
      <State loading={loading} error={error} empty={data?.length === 0 && 'Dados insuficientes.'}>
        <div className="grid md:grid-cols-3 gap-4">{data?.map((v) => {
          const l = voteLabel(v.pct_deferimento, v.n_casos)
          const tone = l.tone === 'neutral' ? 'warn' : l.tone
          return (
            <div key={v.person_id}>
              <div className="flex items-center gap-3"><Avatar nome={v.nome} size={64} />
                <div className="min-w-0"><p className="font-semibold leading-tight">{v.nome}</p><p className="text-xs text-ink-soft">{v.cargo}</p><div className="mt-1"><Chip tone={l.tone}>{l.text}</Chip></div></div></div>
              <div className="mt-3"><Bar pct={v.pct_deferimento} tone={tone} /></div>
              <p className="mt-1 text-sm"><b>{v.pct_deferimento}%</b> deferimento · Base: {v.n_casos} casos · evidência {v.evidencia}</p>
            </div>)})}</div>
        <p className="mt-3 text-xs text-ink-faint">Relator deste processo: {p.relator ?? 'não informado'}. Baseado em decisões passadas em casos semelhantes; não é previsão de resultado.</p>
      </State>}
    </Card>
  )
}

export function DirectorsStrip({ agencia }: { agencia?: string }) {
  const { data, loading, error } = useAsync(() => api.directors())
  const list = (data ?? []).filter((d) => !agencia || d.agencia === agencia)
  return (
    <Card title="Histórico de Votos dos Diretores" action={<span className="text-sm text-ink-soft">Todos os pleitos decididos — últimos 3 anos</span>}>
      <State loading={loading} error={error} empty={list.length === 0 && 'Sem diretores cadastrados.'}>
        <div className="grid lg:grid-cols-3 gap-6">{list.map((d) => (
          <div key={d.person_id}>
            <div className="flex gap-3"><Avatar nome={d.nome} fotoUrl={d.foto_url} fotoFonte={d.foto_fonte} size={64} />
              <div className="min-w-0"><p className="font-semibold leading-tight">{d.nome}</p><p className="text-xs text-ink-soft">{d.cargo}</p><p className="mt-1 text-xs text-ink-soft line-clamp-3">{d.bio_resumo}</p></div></div>
            <div className="mt-3 grid grid-cols-4 text-center text-xs">
              <div><b className="block text-base">{d.n_processos}</b>processos</div>
              <div><b className="block text-base text-ok">{d.pct_deferimento}%</b>deferimento</div>
              <div><b className="block text-base text-warn">{d.pct_indeferimento}%</b>indeferimento</div>
              <div><b className="block text-base">{d.pct_abstencao}%</b>abstenção</div></div>
          </div>))}</div>
      </State>
    </Card>
  )
}
