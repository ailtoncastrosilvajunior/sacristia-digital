# frozen_string_literal: true

module Admin
  # Impressão da escala do mês para o admin: mesmo relatório do painel do ministro,
  # mas com qualquer competência (liberada ou não) e sem exigir vínculo com ministro.
  class EscalaMensalController < Admin::BaseController
    include EscalaMensalImpressao

    before_action :carregar_escala

    private

    def carregar_escala
      @competencias = CompetenciaMensal.ordenados.limit(48).to_a
      @competencia = resolve_competencia
      return redirect_to(admin_root_path, alert: "Nenhuma competência cadastrada.") if @competencia.blank?

      montar_escala_mensal
      # Impressão genérica: sem destaque de nome (o destaque só existe no painel do ministro).
      @meu_id = nil
    end
  end
end
