import { useEffect, useState } from 'react'
export function useAsync<T>(fn: () => Promise<T>, deps: unknown[] = []) {
  const [state, set] = useState<{ data?: T; error?: string; loading: boolean }>({ loading: true })
  useEffect(() => {
    let alive = true
    set({ loading: true })
    fn().then((data) => alive && set({ data, loading: false })).catch((e) => alive && set({ error: String(e.message ?? e), loading: false }))
    return () => { alive = false }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps)
  return state
}
export const fmtDate = (s: string) => new Date(s.length === 10 ? s + 'T12:00:00' : s).toLocaleDateString('pt-BR')
