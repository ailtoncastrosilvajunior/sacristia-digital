# frozen_string_literal: true

module Admin
  class SolicitacaoCadastrosController < Admin::BaseController
    before_action :set_solicitacao, only: [:show, :aprovar, :rejeitar]

    def index
      scope = busca_em(SolicitacaoCadastro.all, %w[nome nome_completo email telefone])
      status = SolicitacaoCadastro::STATUSES.include?(params[:status]) ? params[:status] : "pendente"
      status = nil if params[:status] == "todas"
      scope = scope.where(status: status) if status
      @status = status || "todas"
      @solicitacoes = scope.recentes
    end

    def show
      @ministros_disponiveis = Ministro.left_joins(:user).where(users: { id: nil }).ordenados_por_nome.to_a
      nomes = [@solicitacao.nome, @solicitacao.nome_completo].map { |n| n.to_s.squish.downcase }
      @ministro_sugerido = @ministros_disponiveis.find do |m|
        [m.nome, m.nome_completo].any? { |n| nomes.include?(n.to_s.squish.downcase) }
      end
    end

    def aprovar
      existente = Ministro.find_by(id: params[:ministro_id]) if params[:ministro_id].present?
      if @solicitacao.aprovar!(current_user, ministro_existente: existente)
        redirect_to admin_ministro_path(@solicitacao.ministro), notice: "Cadastro aprovado. O ministro já pode entrar com a senha que escolheu."
      else
        redirect_to admin_solicitacao_cadastro_path(@solicitacao),
                    alert: @solicitacao.errors.full_messages.to_sentence.presence || "Solicitação já avaliada."
      end
    end

    def rejeitar
      if @solicitacao.rejeitar!(current_user, motivo: params[:motivo])
        redirect_to admin_solicitacao_cadastros_path, notice: "Solicitação rejeitada."
      else
        redirect_to admin_solicitacao_cadastros_path, alert: "Solicitação já avaliada."
      end
    end

    private

    def set_solicitacao
      @solicitacao = SolicitacaoCadastro.find(params[:id])
    end
  end
end
