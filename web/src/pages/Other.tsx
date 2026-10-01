import { api, DEFAULT_CLIENT } from '../api'
import { AgendaTable, DirectorsStrip } from '../components/ProcessWidgets'
import { Card, Chip, State } from '../components/ui'
import { useAsync } from '../hooks'

export function Agenda() {
  const { data, loading, error } = useAsync(() => api.agenda(DEFAULT_CLIENT))
  return <Card title="Agenda Regulatória"><State loading={loading} error={error} empty={data?.length === 0 && 'Sem reuniões.'}><AgendaTable rows={data ?? []} /></State></Card>
}
export function Agencias() {
  const { data, loading, error } = useAsync(() => api.agencies())
  return (
    <div className="space-y-6">
      <Card title="Agências e cobertura"><State loading={loading} error={error}>
        <div className="grid md:grid-cols-3 gap-4">{data?.map((a) => (
          <div key={a.sigla} className="rounded-xl border border-canvas p-4"><p className="font-semibold">{a.sigla}</p><p className="text-sm text-ink-soft">{a.nome}</p>
            <div className="mt-2"><Chip tone={a.nivel_voto === 'L2' ? 'ok' : 'warn'}>Voto {a.nivel_voto}</Chip></div></div>))}</div></State></Card>
      <DirectorsStrip />
    </div>
  )
}
export function Configuracoes() {
  return <Card title="Configurações"><p className="text-sm text-ink-soft">Processos monitorados, interesses, importação de andamento do SEI e saúde das coletas (admin) — próxima etapa.</p></Card>
}
