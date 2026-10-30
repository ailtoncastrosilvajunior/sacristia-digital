# frozen_string_literal: true

module Esportulas
  # Conferência espórtulas × 2.1: imediato dia a dia; acumulado em totais do mês.
  class ConferenciaMesService
    Linha = Struct.new(:key, :label, :subtitulo, :valores_por_dia, :total, :tipo, keyword_init: true)
    ResumoAcumulado = Struct.new(:previsto, :pago, :caixa_21, :delta, keyword_init: true)

    def self.call(competencia)
      new(competencia).call
    end

    def initialize(competencia)
      @competencia = competencia
      @inicio = competencia.periodo
      @fim = competencia.periodo_fim
      @dias = (@inicio..@fim).to_a
    end

    def call
      im = bloco_imediato
      ac = bloco_acumulado
      {
        competencia: @competencia,
        imediato: im,
        acumulado: ac,
        totais: {
          previsto: im[:totais][:previsto] + ac.previsto,
          pago_escala: im[:totais][:pago] + ac.pago,
          caixa_21: im[:totais][:caixa_21] + ac.caixa_21,
          delta_mes: im[:totais][:delta] + ac.delta
        }
      }
    end

    private

    def zeros_por_dia
      @zeros_por_dia ||= @dias.index_with { 0.to_d }
    end

    def escala_base_scope
      EventoEscala
        .where(competencia_mensal_id: @competencia.id)
        .nao_cancelados
        .where("evento_escala.valor_esportula > 0")
        .where.not(sacerdote_id: nil)
        .where(data: @inicio..@fim)
    end

    def escala_imediato_scope
      escala_base_scope.where(esportula_modo: "imediato")
    end

    def escala_acumulado_scope
      escala_base_scope.where(esportula_modo: "acumulado")
    end

    def conta_21_id
      @conta_21_id ||= PlanoConta.where(codigo: "2.1").pick(:id)
    end

    def preencher_hash_desde_somas(somas_por_data)
      hash = zeros_por_dia.dup
      somas_por_data.each do |data, total|
        hash[data] += total.to_d if hash.key?(data)
      end
      hash
    end

    def linha(key, label, subtitulo, valores, tipo)
      Linha.new(
        key: key,
        label: label,
        subtitulo: subtitulo,
        valores_por_dia: valores,
        total: valores.values.sum,
        tipo: tipo
      )
    end

    # --- Imediato (por dia) ---

    def bloco_imediato
      previsto = preencher_hash_desde_somas(escala_imediato_scope.group(:data).sum(:valor_esportula))
      pago = somas_pago_imediato_por_dia
      caixa_21 = preencher_hash_desde_somas(somas_caixa_imediato_por_dia)
      delta = @dias.index_with { |d| caixa_21[d] - previsto[d] }
      linhas = [
        linha(:previsto, "Previsto", "Eventos imediato na data do evento", previsto, :escala),
        linha(:pago, "Pago", "Marcado pago: data do LC ou do evento se sem LC", pago, :escala),
        linha(:caixa_21, "2.1 caixa", "Itens 2.1 confirmados na data do LC (sem lotes acumulados)", caixa_21, :caixa),
        linha(:delta, "Δ", "2.1 − previsto no mesmo dia", delta, :delta)
      ]
      {
        dias: @dias,
        linhas: linhas,
        totais: {
          previsto: linhas[0].total,
          pago: linhas[1].total,
          caixa_21: linhas[2].total,
          delta: linhas[3].total
        }
      }
    end

    def somas_pago_imediato_com_lancamento_por_dia
      RegistroEsportula.pagos
        .where(lote_pagamento_esportula_id: nil)
        .where.not(evento_escala_id: nil)
        .joins(:lancamento_caixa, :evento_escala)
        .merge(escala_imediato_scope)
        .merge(LancamentoCaixa.confirmados.where(data: @inicio..@fim))
        .group("lancamentos_caixa.data")
        .sum(:valor)
    end

    def somas_pago_imediato_sem_lancamento_por_dia
      escala_imediato_scope
        .where(
          id: RegistroEsportula.pagos
            .where(lote_pagamento_esportula_id: nil)
            .left_joins(:lancamento_caixa)
            .where(lancamentos_caixa: { id: nil })
            .select(:evento_escala_id)
        )
        .group(:data)
        .sum(:valor_esportula)
    end

    def somas_pago_imediato_por_dia
      hash = zeros_por_dia.dup
      [somas_pago_imediato_com_lancamento_por_dia, somas_pago_imediato_sem_lancamento_por_dia].each do |somas|
        somas.each { |data, total| hash[data] += total.to_d if hash.key?(data) }
      end
      hash
    end

    # Extrato 2.1 do dia, exceto LC gerado por lote acumulado (vai no bloco acumulado).
    def somas_caixa_imediato_por_dia
      return {} if conta_21_id.blank?

      ItemLancamento
        .joins(:lancamento_caixa)
        .merge(
          LancamentoCaixa.confirmados
            .where(data: @inicio..@fim)
            .where(lote_pagamento_esportula_id: nil)
        )
        .where(plano_conta_id: conta_21_id)
        .group("lancamentos_caixa.data")
        .sum(:valor)
    end

    # --- Acumulado (totais do mês) ---

    def bloco_acumulado
      previsto = escala_acumulado_scope.sum(:valor_esportula).to_d
      pago = LotePagamentoEsportula.pagos
        .where(competencia_mensal_id: @competencia.id)
        .sum(:valor)
        .to_d
      caixa_21 = total_caixa_acumulado
      ResumoAcumulado.new(
        previsto: previsto,
        pago: pago,
        caixa_21: caixa_21,
        delta: caixa_21 - previsto
      )
    end

    def total_caixa_acumulado
      return 0.to_d if conta_21_id.blank?

      ItemLancamento
        .joins(lancamento_caixa: :lote_pagamento_esportula)
        .merge(LancamentoCaixa.confirmados)
        .merge(LotePagamentoEsportula.pagos.where(competencia_mensal_id: @competencia.id))
        .where(plano_conta_id: conta_21_id)
        .sum(:valor)
        .to_d
    end
  end
end
