import { useEffect, useState } from 'react'
import { api } from '../api'
import { useAuth } from '../auth'
import { AgendaCard, DirectorsStrip, KpiCards, SearchBox, SimilarCard, Timeline, VoteHistoryCard } from '../components/ProcessWidgets'
import { State } from '../components/ui'
import { useAsync } from '../hooks'
import type { MyProcess } from '../types'

export default function Home() {
  const { client } = useAuth()
  const [p, setP] = useState<MyProcess | null>(null)
  const procs = useAsync(() => api.myProcesses(client!.id), [client?.id])
  const cov = useAsync(() => api.coverage())
  useEffect(() => { if (!p && procs.data?.length) setP(procs.data[0]) }, [procs.data, p])
  const nivel = cov.data?.find((a) => a.sigla === p?.agencia)?.nivel_voto ?? 'L0'
  return (
    <div className="space-y-6 max-w-[1400px] mx-auto">
      <div className="grid xl:grid-cols-[1.4fr_1fr] gap-6"><SearchBox onFound={setP} /><KpiCards /></div>
      {p ? <div className="grid xl:grid-cols-[1fr_1.15fr] gap-6"><Timeline p={p} all={procs.data ?? []} onPick={setP} /><AgendaCard /></div>
         : <State loading={procs.loading} error={procs.error} empty="Nenhum processo monitorado ainda."><span /></State>}
      {p && <div className="grid xl:grid-cols-[1.2fr_1fr] gap-6"><VoteHistoryCard p={p} nivel={nivel} /><SimilarCard p={p} /></div>}
      <DirectorsStrip agencia={p?.agencia} />
    </div>
  )
}
