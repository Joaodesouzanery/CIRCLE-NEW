import { useEffect, useState } from 'react'
import { api } from '../api'
import { AgendaCard, DirectorsStrip, KpiCards, SearchBox, SimilarCard, Timeline, VoteHistoryCard } from '../components/ProcessWidgets'
import { useAsync } from '../hooks'
import type { MyProcess } from '../types'

export default function Home() {
  const [p, setP] = useState<MyProcess | null>(null)
  const ag = useAsync(() => api.agencies())
  useEffect(() => { api.searchProcess('50500.123456/2024-78').then(setP).catch(() => {}) }, [])
  const nivel = ag.data?.find((a) => a.sigla === p?.agencia)?.nivel_voto ?? 'L0'
  return (
    <div className="space-y-6 max-w-[1400px] mx-auto">
      <div className="grid xl:grid-cols-[1.4fr_1fr] gap-6"><SearchBox onFound={setP} /><KpiCards /></div>
      <div className="grid xl:grid-cols-[1fr_1.15fr] gap-6">{p && <Timeline p={p} />}<AgendaCard /></div>
      {p && <div className="grid xl:grid-cols-[1.2fr_1fr] gap-6"><VoteHistoryCard p={p} nivel={nivel} /><SimilarCard p={p} /></div>}
      <DirectorsStrip agencia={p?.agencia} />
    </div>
  )
}
