# frozen_string_literal: true

module Admin
  class PlanoContasController < Admin::BaseController
    before_action :set_plano_conta, only: [:show, :edit, :update, :destroy]
    before_action :set_index_params

    def index
      carregar_arvore
    end

    def show
      redirect_to edit_admin_plano_conta_path(@plano_conta, **@index_params)
    end

    def new
      build_nova_conta
      render_drawer_form
    end

    def create
      @plano_conta = PlanoConta.new(plano_conta_params)
      if @plano_conta.save
        redirect_to admin_plano_contas_path(**@index_params), notice: "Conta criada com sucesso."
      else
        render partial: "drawer_form", layout: false, status: :unprocessable_entity
      end
    end

    def edit
      render_drawer_form
    end

    def update
      if @plano_conta.update(plano_conta_params)
        redirect_to admin_plano_contas_path(**@index_params), notice: "Conta atualizada com sucesso."
      else
        render partial: "drawer_form", layout: false, status: :unprocessable_entity
      end
    end

    def destroy
      if @plano_conta.destroy
        redirect_to admin_plano_contas_path(**@index_params), notice: "Conta excluída com sucesso."
      else
        msg = @plano_conta.errors.full_messages.presence&.to_sentence || "Não foi possível excluir esta conta."
        redirect_to admin_plano_contas_path(**@index_params), alert: msg
      end
    end

    private

    def carregar_arvore
      scope = PlanoConta.ordenadas
      scope = scope.where(natureza: params[:natureza]) if PlanoConta::NATUREZAS.include?(params[:natureza])

      if params[:q].present?
        termo = "%#{params[:q].strip}%"
        matches = scope.where("nome ILIKE ? OR codigo ILIKE ?", termo, termo)
        ids = plano_contas_ids_com_ancestrais(matches)
        scope = PlanoConta.where(id: ids).ordenadas
      end

      contas = scope.to_a
      @contas_por_pai = contas.group_by(&:conta_pai_id)
      @raizes = (@contas_por_pai[nil] || []).sort_by(&:codigo)
      @total_contas = contas.size
    end

    def build_nova_conta
      pai = PlanoConta.find_by(id: params[:conta_pai_id])
      natureza = pai&.natureza || params[:natureza].presence
      natureza = "despesa" unless PlanoConta::NATUREZAS.include?(natureza)

      @plano_conta = PlanoConta.new(
        natureza: natureza,
        conta_pai_id: pai&.id,
        sintetica: false,
        ativo: true
      )
    end

    def render_drawer_form
      if drawer_frame_request?
        render partial: "drawer_form", layout: false
      else
        redirect_to admin_plano_contas_path(**@index_params)
      end
    end

    def drawer_frame_request?
      request.headers["Turbo-Frame"] == "plano_conta_drawer"
    end

    def set_index_params
      @index_params = index_filter_params
    end

    def index_filter_params
      params.permit(:q, :natureza).to_h.compact_blank.symbolize_keys
    end

    def plano_contas_ids_com_ancestrais(contas)
      por_id = PlanoConta.pluck(:id, :conta_pai_id).to_h
      ids = contas.map(&:id).to_set

      contas.each do |c|
        pai_id = c.conta_pai_id
        while pai_id.present?
          ids.add(pai_id)
          pai_id = por_id[pai_id]
        end
      end
      ids.to_a
    end

    def set_plano_conta
      @plano_conta = PlanoConta.find(params[:id])
    end

    def plano_conta_params
      params.require(:plano_conta).permit(:codigo, :nome, :natureza, :sintetica, :conta_pai_id, :ordem, :ativo)
    end
  end
end
