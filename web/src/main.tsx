import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { AuthProvider, useAuth } from './auth'
import Layout from './components/Layout'
import Home from './pages/Home'
import Login from './pages/Login'
import { Agencias, Agenda, Configuracoes } from './pages/Other'
import './index.css'

function Gate() {
  const { ready, email, client } = useAuth()
  if (!ready) return <div className="min-h-screen grid place-items-center text-ink-soft">Carregando…</div>
  if (!email) return <Login />
  if (!client) return <div className="min-h-screen grid place-items-center text-ink-soft p-6 text-center">Sua conta ainda não está vinculada a nenhum cliente. Fale com o administrador da plataforma.</div>
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Home />} />
        <Route path="agenda" element={<Agenda />} />
        <Route path="agencias" element={<Agencias />} />
        <Route path="configuracoes" element={<Configuracoes />} />
      </Route>
    </Routes>
  )
}
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode><BrowserRouter><AuthProvider><Gate /></AuthProvider></BrowserRouter></React.StrictMode>,
)
