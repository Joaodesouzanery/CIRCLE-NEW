import { useState } from 'react'
import { useAuth } from '../auth'

export default function Login() {
  const { signIn } = useAuth()
  const [email, setEmail] = useState(''); const [pw, setPw] = useState(''); const [err, setErr] = useState(''); const [busy, setBusy] = useState(false)
  const submit = async (e: React.FormEvent) => { e.preventDefault(); setBusy(true); setErr((await signIn(email, pw)) ?? ''); setBusy(false) }
  return (
    <div className="min-h-screen grid place-items-center bg-gradient-to-br from-navy-950 via-navy-900 to-navy-800 p-6">
      <form onSubmit={submit} className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-2xl space-y-4">
        <div className="bg-black rounded-xl p-3 grid place-items-center"><img src="/circle-logo.png" alt="Circle — Better Regulation" className="h-14" /></div>
        <h1 className="text-lg font-semibold">Entrar</h1>
        <label className="block text-sm">E-mail<input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} className="mt-1 w-full rounded-xl border border-black/10 px-3 py-2.5 outline-none focus:ring-2 focus:ring-brand/40" /></label>
        <label className="block text-sm">Senha<input type="password" required value={pw} onChange={(e) => setPw(e.target.value)} className="mt-1 w-full rounded-xl border border-black/10 px-3 py-2.5 outline-none focus:ring-2 focus:ring-brand/40" /></label>
        {err && <p className="text-sm text-bad">{err}</p>}
        <button disabled={busy} className="w-full rounded-xl bg-brand py-2.5 font-semibold text-white disabled:opacity-60">{busy ? 'Entrando…' : 'Entrar'}</button>
      </form>
    </div>
  )
}
