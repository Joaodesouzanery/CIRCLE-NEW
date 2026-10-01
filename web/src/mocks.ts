import type { AgendaRow, ClientInfo, Coverage, Director, Kpis, MyProcess, SimilarOutcome, TimelineEvent, VoteHistory } from './types'

// MODO OFFLINE (VITE_USE_MOCKS=true): dados 100% fictícios. Nenhuma pessoa real.
export const client: ClientInfo = { id: 'demo', nome: '[DEMO] CS Infra' }
export const kpis: Kpis = { processos_monitorados: 3, reunioes_30d: 4 }
export const processo: MyProcess = {
  process_id: 'p1', nup: '99999.123456/2024-78', agencia: 'DEMO-A', assunto: '[DEMO] Concessão Rodoviária – Revisão de Tarifa',
  status: 'em_andamento', etapa_atual: 'deliberacao', interessados: ['[DEMO] CS Infra'], tipo: 'Revisão de tarifa', setor: 'Rodovia', tema: 'Tarifa', unidade: 'SUROD-DEMO', relator: '[DEMO] Diretor B', apelido: '[DEMO] Revisão de tarifa',
}
export const timeline: TimelineEvent[] = [
  { event_id: 'e5', ocorrido_em: '2026-09-28', etapa: 'deliberacao', titulo: 'Deliberação', descricao: '[DEMO] Incluído na pauta da Reunião de Diretoria nº 16', doc_rotulo: 'Pauta RD nº 16', doc_url: 'https://demo.invalid/pauta/16', origem: 'pauta' },
  { event_id: 'e4', ocorrido_em: '2026-09-12', etapa: 'nota_tecnica', titulo: 'Nota técnica', descricao: '[DEMO] Nota Técnica SEI 234/2026', doc_rotulo: 'NT 234/2026', doc_url: 'https://demo.invalid/proc/nt', origem: 'sei_import' },
  { event_id: 'e3', ocorrido_em: '2026-09-05', etapa: 'manifestacao', titulo: 'Manifestação', descricao: '[DEMO] Manifestação da área técnica', doc_rotulo: 'Parecer técnico', doc_url: 'https://demo.invalid/proc/parecer', origem: 'sei_import' },
]
export const agenda: AgendaRow[] = [
  { meeting_id: 'm1', agenda_item_id: 'a1', agencia: 'DEMO-A', orgao: 'diretoria', tipo_reuniao: 'ordinaria', inicio: '2026-10-05T13:00:00Z', status: 'confirmada', item_ref: '3.2', nup: '99999.123456/2024-78', assunto: '[DEMO] Revisão de Tarifa', fonte_url: 'https://demo.invalid/pauta/16', relevancia: 'processo_monitorado' },
  { meeting_id: 'm4', agenda_item_id: null, agencia: 'DEMO-A', orgao: 'audiência pública', tipo_reuniao: 'audiencia_publica', inicio: '2026-10-28T13:00:00Z', status: 'prevista', tema: '[DEMO] Modernização de Concessões', relevancia: 'interesse' },
]
export const similar: SimilarOutcome = { n_casos: 40, deferidos: 28, indeferidos: 10, parciais: 2, pct_deferimento: 70, evidencia: 'alta' }
export const votes: VoteHistory[] = [
  { person_id: 'd1', nome: '[DEMO] Diretor A', cargo: 'Diretor-Geral - DEMO-A', n_casos: 40, pct_deferimento: 70, pct_indeferimento: 25, pct_abstencao: 5, evidencia: 'alta' },
  { person_id: 'd2', nome: '[DEMO] Diretor B', cargo: 'Diretor - DEMO-A', n_casos: 38, pct_deferimento: 79, pct_indeferimento: 21, pct_abstencao: 0, evidencia: 'alta' },
  { person_id: 'd3', nome: '[DEMO] Diretor C', cargo: 'Diretor - DEMO-A', n_casos: 37, pct_deferimento: 62, pct_indeferimento: 38, pct_abstencao: 0, evidencia: 'alta' },
]
export const directors: Director[] = votes.map((v) => ({ person_id: v.person_id, agencia: 'DEMO-A', nome: v.nome, cargo: v.cargo, bio_resumo: '[DEMO] Biografia fictícia, apenas para demonstrar o layout.', n_processos: 58, pct_deferimento: v.pct_deferimento, pct_indeferimento: v.pct_indeferimento, pct_abstencao: v.pct_abstencao }))
export const coverage: Coverage[] = [
  { sigla: 'DEMO-A', nome: '[DEMO] Agência A', setor: 'Transportes', esfera: 'federal', nivel_voto: 'L2', fontes_ativas: 1, atualizado_em: new Date().toISOString() },
  { sigla: 'DEMO-B', nome: '[DEMO] Agência B', setor: 'Portos', esfera: 'federal', nivel_voto: 'L1', fontes_ativas: 1, atualizado_em: null },
]
