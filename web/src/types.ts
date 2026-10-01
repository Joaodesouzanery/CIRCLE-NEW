// Formato idêntico às views/RPCs do contrato (docs/07). Troque mocks por chamadas reais sem mudar componentes.
export type Evidencia = 'alta' | 'media' | 'baixa'
export interface Kpis { processos_monitorados: number; reunioes_30d: number }
export interface MyProcess {
  process_id: string; nup: string; agencia: string; assunto: string; status: 'em_andamento' | 'concluido' | 'arquivado' | 'desconhecido'
  etapa_atual: string; interessados: string[]; apelido?: string; tipo: string; setor: string; tema: string; unidade: string; relator: string
}
export interface TimelineEvent {
  event_id: string; ocorrido_em: string; etapa: string; titulo: string; descricao: string
  unidade?: string; doc_rotulo?: string; doc_url?: string; origem: 'pauta' | 'ata' | 'dados_abertos' | 'dou' | 'sei_import' | 'email' | 'manual'
}
export interface AgendaRow {
  agenda_item_id: string; agencia: string; orgao: string; tipo_reuniao: string; inicio: string
  status: 'prevista' | 'confirmada' | 'realizada' | 'cancelada'; item_ref?: string; nup?: string; assunto?: string
  tema?: string; fonte_url?: string; retirado_de_pauta?: boolean
}
export interface SimilarOutcome { n_casos: number; deferidos: number; indeferidos: number; parciais: number; pct_deferimento: number | null; evidencia: Evidencia }
export interface VoteHistory { person_id: string; nome: string; cargo: string; n_casos: number; pct_deferimento: number; pct_indeferimento: number; pct_abstencao: number; evidencia: Evidencia }
export interface Director {
  person_id: string; agencia: string; nome: string; cargo: string; bio_resumo: string; foto_url?: string | null; foto_fonte?: string | null
  fonte_url?: string; n_processos: number; pct_deferimento: number; pct_indeferimento: number; pct_abstencao: number
}
export interface Agency { sigla: string; nome: string; setor: string; nivel_voto: 'L0' | 'L1' | 'L2' }
