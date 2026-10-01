import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { api, supabase, useMocks } from './api'
import type { ClientInfo } from './types'

interface Ctx { ready: boolean; email: string | null; client: ClientInfo | null; signOut: () => Promise<void>; signIn: (e: string, p: string) => Promise<string | null> }
const AuthCtx = createContext<Ctx>(null!)
export const useAuth = () => useContext(AuthCtx)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false)
  const [email, setEmail] = useState<string | null>(useMocks ? 'demo@offline' : null)
  const [client, setClient] = useState<ClientInfo | null>(null)

  useEffect(() => {
    if (!supabase) { api.myClient().then((c) => { setClient(c); setReady(true) }); return }
    const load = async (mail: string | null) => {
      setEmail(mail)
      setClient(mail ? await api.myClient().catch(() => null) : null)
      setReady(true)
    }
    supabase.auth.getSession().then(({ data }) => load(data.session?.user.email ?? null))
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => { load(s?.user.email ?? null) })
    return () => sub.subscription.unsubscribe()
  }, [])

  const signIn = async (e: string, p: string) => {
    const { error } = await supabase!.auth.signInWithPassword({ email: e, password: p })
    return error ? 'E-mail ou senha inválidos.' : null
  }
  const signOut = async () => { await supabase?.auth.signOut() }
  return <AuthCtx.Provider value={{ ready, email, client, signIn, signOut }}>{children}</AuthCtx.Provider>
}
