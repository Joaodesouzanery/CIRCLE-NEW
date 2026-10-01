// Formato idêntico às views/RPCs do contrato (docs/07).
export type Evidencia = 'alta' | 'media' | 'baixa'
export interface ClientInfo { id: string; nome: string }
export interface Kpis { processos_monitorados: number; reunioes_30d: number }
export interface MyProcess {
  process_id: string; nup: string; agencia: string; assunto: string; status: 'em_andamento' | 'concluido' | 'arquivado' | 'desconhecido'
  etapa_atual: string; interessados: string[]; apelido?: string | null; tipo: string | null; setor: string | null; tema: string | null; unidade: string | null; relator: string | null
}
export interface TimelineEvent {
  event_id: string; ocorrido_em: string; etapa: string; titulo: string; descricao: string | null
  unidade?: string | null; doc_rotulo?: string | null; doc_url?: string | null; origem: 'pauta' | 'ata' | 'dados_abertos' | 'dou' | 'sei_import' | 'email' | 'manual'
}
export interface AgendaRow {
  agenda_item_id: string | null; meeting_id: string; agencia: string; orgao: string; tipo_reuniao: string; inicio: string
  status: 'prevista' | 'confirmada' | 'realizada' | 'cancelada'; item_ref?: string | null; nup?: string | null; assunto?: string | null
  tema?: string | null; fonte_url?: string | null; retirado_de_pauta?: boolean | null; relevancia?: 'processo_monitorado' | 'interesse'
}
export interface SimilarOutcome { n_casos: number; deferidos: number; indeferidos: number; parciais: number; pct_deferimento: number | null; evidencia: Evidencia }
export interface VoteHistory { person_id: string; nome: string; cargo: string; n_casos: number; pct_deferimento: number; pct_indeferimento: number; pct_abstencao: number; evidencia: Evidencia }
export interface Director {
  person_id: string; agencia: string; nome: string; cargo: string; bio_resumo: string | null; foto_url?: string | null; foto_fonte?: string | null
  fonte_url?: string | null; n_processos: number; pct_deferimento: number; pct_indeferimento: number; pct_abstencao: number
}
export interface Coverage { sigla: string; nome: string; setor: string; esfera: string; nivel_voto: 'L0' | 'L1' | 'L2'; fontes_ativas: number; atualizado_em: string | null }
