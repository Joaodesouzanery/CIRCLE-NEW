import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter, Route, Routes } from 'react-router-dom'
import Layout from './components/Layout'
import Home from './pages/Home'
import { Agencias, Agenda, Configuracoes } from './pages/Other'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="agenda" element={<Agenda />} />
          <Route path="agencias" element={<Agencias />} />
          <Route path="configuracoes" element={<Configuracoes />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </React.StrictMode>,
)
