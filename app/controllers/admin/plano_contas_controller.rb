# frozen_string_literal: true

module Admin
  class PlanoContasController < Admin::BaseController
    before_action :set_plano_conta, only: [:show, :edit, :update]

    def index
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

    def show
    end

    def new
      @plano_conta = PlanoConta.new(natureza: params[:natureza].presence || "despesa")
    end

    def create
      @plano_conta = PlanoConta.new(plano_conta_params)
      if @plano_conta.save
        redirect_to admin_plano_contas_path, notice: "Conta criada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @plano_conta.update(plano_conta_params)
        redirect_to admin_plano_contas_path, notice: "Conta atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

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
