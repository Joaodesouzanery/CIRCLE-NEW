import { api } from '../api'
import { useAuth } from '../auth'
import { AgendaTable, DirectorsStrip } from '../components/ProcessWidgets'
import { Card, Chip, State } from '../components/ui'
import { fmtDate, useAsync } from '../hooks'

export function Agenda() {
  const { client } = useAuth()
  const { data, loading, error } = useAsync(() => api.agenda(client!.id), [client?.id])
  return <Card title="Agenda Regulatória"><State loading={loading} error={error} empty={data?.length === 0 && 'Sem reuniões.'}><AgendaTable rows={data ?? []} /></State></Card>
}
const cob = { L2: ['ok', 'Voto individual (L2)'], L1: ['brand', 'Relator e resultado (L1)'], L0: ['warn', 'Somente resultado (L0)'] } as const
export function Agencias() {
  const { data, loading, error } = useAsync(() => api.coverage())
  return (
    <div className="space-y-6">
      <Card title="Agências e cobertura"><State loading={loading} error={error}>
        <div className="grid md:grid-cols-3 gap-4">{data?.map((a) => (
          <div key={a.sigla} className="rounded-xl border border-canvas p-4"><p className="font-semibold">{a.sigla}</p><p className="text-sm text-ink-soft">{a.nome}</p>
            <div className="mt-2 flex flex-wrap gap-1.5"><Chip tone={cob[a.nivel_voto][0]}>{cob[a.nivel_voto][1]}</Chip><Chip>{a.fontes_ativas} {a.fontes_ativas === 1 ? 'fonte ativa' : 'fontes ativas'}</Chip></div>
            <p className="mt-2 text-xs text-ink-faint">Atualizado em: {a.atualizado_em ? fmtDate(a.atualizado_em) : 'sem coleta ainda'}</p></div>))}</div></State></Card>
      <DirectorsStrip />
    </div>
  )
}
export function Configuracoes() {
  return <Card title="Configurações"><p className="text-sm text-ink-soft">Processos monitorados, interesses, importação de andamento do SEI e saúde das coletas (admin) — próxima etapa.</p></Card>
}
