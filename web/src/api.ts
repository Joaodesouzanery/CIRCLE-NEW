import { createClient } from '@supabase/supabase-js'
import * as mocks from './mocks'
import type { AgendaRow, ClientInfo, Coverage, Director, Kpis, MyProcess, SimilarOutcome, TimelineEvent, VoteHistory } from './types'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined
export const useMocks = import.meta.env.VITE_USE_MOCKS === 'true' || !url || !key
// Somente chave anon/publishable + JWT do usuário; o RLS faz o isolamento por cliente.
export const supabase = useMocks ? null : createClient(url!, key!)

const wait = <T,>(v: T) => new Promise<T>((r) => setTimeout(() => r(v), 150))
function must<T>(res: { data: T | null; error: { message: string } | null }): T {
  if (res.error) throw new Error(res.error.message)
  return res.data as T
}

// Camada de dados: só consome views v_* e rpc_* (contrato em docs/07).
export const api = {
  myClient: async (): Promise<ClientInfo | null> =>
    supabase ? (must(await supabase.from('clients').select('id,nome').limit(1)) as ClientInfo[])[0] ?? null : wait(mocks.client),
  kpis: async (clientId: string): Promise<Kpis> =>
    supabase ? must(await supabase.from('v_kpis').select('processos_monitorados,reunioes_30d').eq('client_id', clientId).single()) : wait(mocks.kpis),
  myProcesses: async (clientId: string): Promise<MyProcess[]> =>
    supabase ? must(await supabase.from('v_my_processes').select('*').eq('client_id', clientId).order('nup')) : wait([mocks.processo]),
  findProcess: async (clientId: string, nup: string): Promise<MyProcess | null> =>
    supabase ? (must(await supabase.from('v_my_processes').select('*').eq('client_id', clientId).eq('nup', nup).limit(1)) as MyProcess[])[0] ?? null
             : wait(nup === mocks.processo.nup ? mocks.processo : null),
  timeline: async (pid: string): Promise<TimelineEvent[]> =>
    supabase ? must(await supabase.from('v_process_timeline').select('*').eq('process_id', pid).order('ocorrido_em', { ascending: false })) : wait(mocks.timeline),
  agenda: async (clientId: string): Promise<AgendaRow[]> =>
    supabase ? must(await supabase.from('v_agenda_client').select('*').eq('client_id', clientId).gte('inicio', new Date(Date.now() - 86400000).toISOString()).order('inicio')) : wait(mocks.agenda),
  similar: async (pid: string): Promise<SimilarOutcome> =>
    supabase ? (must(await supabase.rpc('rpc_similar_outcome', { p_process_id: pid })) as SimilarOutcome[])[0] : wait(mocks.similar),
  votes: async (pid: string): Promise<VoteHistory[]> =>
    supabase ? must(await supabase.rpc('rpc_vote_history', { p_process_id: pid })) : wait(mocks.votes),
  // Estatística geral: todos os pleitos decididos nos últimos 3 anos (v_director_stats)
  directors: async (): Promise<Director[]> => {
    if (!supabase) return wait(mocks.directors)
    const [dirs, stats] = await Promise.all([
      supabase.from('v_directors').select('*').eq('ativo', true),
      supabase.from('v_director_stats').select('*'),
    ])
    const s = new Map((must(stats) as Director[]).map((x) => [x.person_id, x]))
    return (must(dirs) as Director[]).map((d) => ({ ...d, n_processos: s.get(d.person_id)?.n_processos ?? 0, pct_deferimento: s.get(d.person_id)?.pct_deferimento ?? 0, pct_indeferimento: s.get(d.person_id)?.pct_indeferimento ?? 0, pct_abstencao: s.get(d.person_id)?.pct_abstencao ?? 0 }))
  },
  coverage: async (): Promise<Coverage[]> =>
    supabase ? must(await supabase.rpc('rpc_agency_coverage')) : wait(mocks.coverage),
}
