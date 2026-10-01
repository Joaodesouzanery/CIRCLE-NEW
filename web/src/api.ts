import { createClient } from '@supabase/supabase-js'
import * as mocks from './mocks'
import type { AgendaRow, Agency, Director, Kpis, MyProcess, SimilarOutcome, TimelineEvent, VoteHistory } from './types'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined
const useMocks = import.meta.env.VITE_USE_MOCKS !== 'false' || !url || !key
export const supabase = !useMocks ? createClient(url!, key!) : null

const wait = <T,>(v: T) => new Promise<T>((r) => setTimeout(() => r(v), 250))
function must<T>(res: { data: T | null; error: { message: string } | null }): T {
  if (res.error) throw new Error(res.error.message)
  return res.data as T
}

// Camada de dados: só consome views v_* e rpc_* (contrato em docs/07).
export const api = {
  kpis: async (clientId: string): Promise<Kpis> =>
    supabase ? must(await supabase.from('v_kpis').select('*').eq('client_id', clientId).single()) : wait(mocks.kpis),
  searchProcess: async (nup: string): Promise<MyProcess | null> =>
    supabase ? (must(await supabase.from('v_my_processes').select('*').eq('nup', nup).limit(1)) as MyProcess[])[0] ?? null
             : wait(nup.replace(/\D/g, '') === mocks.processo.nup.replace(/\D/g, '') ? mocks.processo : null),
  timeline: async (pid: string): Promise<TimelineEvent[]> =>
    supabase ? must(await supabase.from('v_process_timeline').select('*').eq('process_id', pid).order('ocorrido_em', { ascending: false })) : wait(mocks.timeline),
  agenda: async (clientId: string): Promise<AgendaRow[]> =>
    supabase ? must(await supabase.from('v_agenda_client').select('*').eq('client_id', clientId).order('inicio')) : wait(mocks.agenda),
  similar: async (pid: string): Promise<SimilarOutcome> =>
    supabase ? must(await supabase.rpc('rpc_similar_outcome', { p_process_id: pid })) : wait(mocks.similar),
  votes: async (pid: string): Promise<VoteHistory[]> =>
    supabase ? must(await supabase.rpc('rpc_vote_history', { p_process_id: pid })) : wait(mocks.votes),
  directors: async (): Promise<Director[]> =>
    supabase ? must(await supabase.from('v_directors').select('*')) : wait(mocks.directors),
  agencies: async (): Promise<Agency[]> =>
    supabase ? must(await supabase.from('agencies').select('sigla,nome,setor,nivel_voto')) : wait(mocks.agencies),
}
export const DEFAULT_CLIENT = 'cs-infra'
