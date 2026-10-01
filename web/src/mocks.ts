import type { AgendaRow, Agency, Director, Kpis, MyProcess, SimilarOutcome, TimelineEvent, VoteHistory } from './types'

// DADOS FICTÍCIOS para demonstração visual. Não representam votos reais dos diretores citados.
export const kpis: Kpis = { processos_monitorados: 12, reunioes_30d: 5 }
export const processo: MyProcess = {
  process_id: 'p1', nup: '50500.123456/2024-78', agencia: 'ANTT', assunto: 'Concessão Rodoviária – Revisão de Tarifa',
  status: 'em_andamento', etapa_atual: 'deliberacao', interessados: ['CS Infra'], tipo: 'Revisão de tarifa', setor: 'Rodovia', tema: 'Tarifa', unidade: 'SUROD', relator: 'Guilherme Theo Sampaio',
}
export const timeline: TimelineEvent[] = [
  { event_id: 'e1', ocorrido_em: '2026-09-28', etapa: 'deliberacao', titulo: 'Deliberação', descricao: 'Incluído na pauta da Reunião de Diretoria para 05/10/2026', doc_rotulo: 'Pauta RD nº 1.245', doc_url: '#', origem: 'pauta' },
  { event_id: 'e2', ocorrido_em: '2026-09-12', etapa: 'nota_tecnica', titulo: 'Nota técnica', descricao: 'Nota Técnica SEI 234/2026/SUROD', doc_rotulo: 'NT 234/2026', doc_url: '#', origem: 'sei_import' },
  { event_id: 'e3', ocorrido_em: '2026-09-05', etapa: 'manifestacao', titulo: 'Manifestação', descricao: 'Manifestação da área técnica (SUROD)', doc_rotulo: 'Parecer técnico', doc_url: '#', origem: 'sei_import' },
  { event_id: 'e4', ocorrido_em: '2026-08-20', etapa: 'distribuicao', titulo: 'Distribuição', descricao: 'Processo distribuído ao Diretor Guilherme Theo Sampaio', doc_rotulo: 'Despacho', doc_url: '#', origem: 'dados_abertos' },
  { event_id: 'e5', ocorrido_em: '2026-08-15', etapa: 'autuacao', titulo: 'Autuação', descricao: 'Processo autuado na ANTT', doc_rotulo: 'Processo inicial', doc_url: '#', origem: 'dados_abertos' },
]
export const agenda: AgendaRow[] = [
  { agenda_item_id: 'a1', agencia: 'ANTT', orgao: 'Reunião de Diretoria', tipo_reuniao: 'ordinaria', inicio: '2026-10-05', status: 'confirmada', item_ref: '3.2', nup: '50500.123456/2024-78', assunto: 'Revisão de Tarifa', tema: 'CS Infra', fonte_url: '#' },
  { agenda_item_id: 'a2', agencia: 'ANTT', orgao: 'Reunião de Diretoria', tipo_reuniao: 'ordinaria', inicio: '2026-10-19', status: 'prevista', item_ref: '1.4', nup: '50500.987654/2024-11', assunto: 'Reequilíbrio Contratual', tema: 'CS Infra' },
  { agenda_item_id: 'a3', agencia: 'ANTAQ', orgao: 'Reunião de Diretoria', tipo_reuniao: 'ordinaria', inicio: '2026-10-21', status: 'prevista', item_ref: '2.1', assunto: 'Arrendamento Portuário', tema: 'CS Infra' },
  { agenda_item_id: 'a4', agencia: 'ANTT', orgao: 'Audiência Pública', tipo_reuniao: 'audiencia_publica', inicio: '2026-10-28', status: 'prevista', assunto: 'Modernização de Concessões Rodoviárias', tema: 'Concessões Rodoviárias' },
  { agenda_item_id: 'a5', agencia: 'ANTT', orgao: 'Reunião de Diretoria', tipo_reuniao: 'ordinaria', inicio: '2026-11-05', status: 'prevista', item_ref: '4.3', assunto: 'Revisão Ordinária', tema: 'CS Infra' },
]
export const similar: SimilarOutcome = { n_casos: 38, deferidos: 27, indeferidos: 9, parciais: 2, pct_deferimento: 72, evidencia: 'alta' }
export const votes: VoteHistory[] = [
  { person_id: 'd1', nome: 'Felipe Queiroz', cargo: 'Diretor - ANTT', n_casos: 67, pct_deferimento: 72, pct_indeferimento: 24, pct_abstencao: 4, evidencia: 'alta' },
  { person_id: 'd2', nome: 'Guilherme Theo Sampaio', cargo: 'Diretor-Geral - ANTT', n_casos: 62, pct_deferimento: 58, pct_indeferimento: 38, pct_abstencao: 4, evidencia: 'alta' },
  { person_id: 'd3', nome: 'Lucas Asfor Rocha Lima', cargo: 'Diretor - ANTT', n_casos: 59, pct_deferimento: 46, pct_indeferimento: 54, pct_abstencao: 0, evidencia: 'alta' },
]
const base = { agencia: 'ANTT', foto_url: null, foto_fonte: null }
export const directors: Director[] = [
  { ...base, person_id: 'd1', nome: 'Felipe Queiroz', cargo: 'Diretor - ANTT', bio_resumo: 'Advogado. Ex-Secretário de Transportes. Atuou na estruturação de concessões rodoviárias e na área de regulação de transportes.', n_processos: 67, pct_deferimento: 72, pct_indeferimento: 24, pct_abstencao: 4 },
  { ...base, person_id: 'd2', nome: 'Guilherme Theo Sampaio', cargo: 'Diretor-Geral - ANTT', bio_resumo: 'Engenheiro. Experiência em infraestrutura e concessões. Atuou em cargos de gestão no setor público e privado na área de transportes.', n_processos: 62, pct_deferimento: 58, pct_indeferimento: 38, pct_abstencao: 4 },
  { ...base, person_id: 'd3', nome: 'Lucas Asfor Rocha Lima', cargo: 'Diretor - ANTT', bio_resumo: 'Advogado. Especialista em regulação e políticas públicas de transporte. Experiência em temas de concessões e equilíbrio econômico-financeiro.', n_processos: 59, pct_deferimento: 46, pct_indeferimento: 54, pct_abstencao: 0 },
]
export const agencies: Agency[] = [
  { sigla: 'ANTT', nome: 'Agência Nacional de Transportes Terrestres', setor: 'Transportes', nivel_voto: 'L2' },
  { sigla: 'ANTAQ', nome: 'Agência Nacional de Transportes Aquaviários', setor: 'Portos e Hidrovias', nivel_voto: 'L1' },
  { sigla: 'ARTESP', nome: 'Agência de Transporte do Estado de São Paulo', setor: 'Transportes', nivel_voto: 'L0' },
]
