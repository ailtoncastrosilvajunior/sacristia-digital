# frozen_string_literal: true

module Admin
  class LancamentosCaixaController < Admin::BaseController
    include Admin::ReturnToRedirect

    before_action :set_lancamento, only: [:show, :edit, :update, :estornar]
    before_action :load_form_collections, only: [:new, :create, :edit, :update]

    def index
      @ano = (params[:ano] || Date.current.year).to_i
      @mes = (params[:mes] || Date.current.month).to_i
      inicio = Date.new(@ano, @mes, 1)

      scope = LancamentoCaixa.includes(:conta_corrente, :itens_lancamento)
      scope = scope.where(data: inicio..inicio.end_of_month)
      scope = scope.where(natureza: params[:natureza]) if LancamentoCaixa::NATUREZAS.include?(params[:natureza])
      scope = scope.where(status: params[:status]) if LancamentoCaixa::STATUS.include?(params[:status])
      @lancamentos = scope.order(data: :desc, id: :desc).page(params[:page])
    end

    def show
      @return_to = safe_return_to_path
      if request.headers["Turbo-Frame"] == "lancamento_drawer"
        render partial: "show_drawer", layout: false
      end
    end

    def new
      @return_to = safe_return_to_path
      @lancamento = LancamentoCaixa.new(
        conta_corrente: ContaCorrente.padrao,
        data: data_padrao_novo_lancamento,
        natureza: params[:natureza].presence_in(LancamentoCaixa::NATUREZAS) || "entrada",
        status: "confirmado"
      )
      @lancamento.itens_lancamento.build
    end

    def create
      @lancamento = LancamentoCaixa.new(lancamento_params)
      if @lancamento.save
        redirect_with_return_to(
          default: admin_lancamentos_caixa_path(@lancamento),
          notice: "Lançamento registrado."
        )
      else
        @return_to = safe_return_to_path
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @return_to = safe_return_to_path
      if params[:natureza].present? && params[:natureza].in?(LancamentoCaixa::NATUREZAS)
        @lancamento.natureza = params[:natureza]
      end
      @lancamento.itens_lancamento.build if @lancamento.itens_lancamento.empty?
    end

    def update
      if @lancamento.update(lancamento_params)
        redirect_with_return_to(
          default: admin_lancamentos_caixa_path(@lancamento),
          notice: "Lançamento atualizado."
        )
      else
        @return_to = safe_return_to_path
        render :edit, status: :unprocessable_entity
      end
    end

    # JSON para o select de eventos do formulário: eventos do período,
    # com os da data preferida (params[:data]) em primeiro lugar.
    def eventos
      de = parse_data_param(params[:de])
      ate = parse_data_param(params[:ate]) || de
      return render(json: { grupos: [] }) unless de

      de, ate = ate, de if ate < de
      preferida = parse_data_param(params[:data])

      eventos = EventoEscala.nao_cancelados.includes(:tipo_servico, :sacerdote)
                            .where(data: de..ate).order(:data, :horario).limit(200).to_a
      do_dia, outros = preferida ? eventos.partition { |e| e.data == preferida } : [[], eventos]

      grupos = []
      grupos << { label: "Do dia #{I18n.l(preferida)}", opcoes: do_dia.map { |e| opcao_evento(e) } } if do_dia.any?
      grupos << { label: (do_dia.any? ? "Outros dias do período" : "Período"), opcoes: outros.map { |e| opcao_evento(e) } } if outros.any?
      render json: { grupos: grupos }
    end

    def estornar
      @lancamento.estornar!(user: current_user)
      redirect_to admin_lancamentos_caixa_path(@lancamento), notice: "Lançamento estornado."
    end

    private

    def set_lancamento
      @lancamento = LancamentoCaixa.includes(
        :conta_corrente,
        { evento_escala: :tipo_servico },
        { registro_esportula: { evento_escala: :tipo_servico } },
        { lote_pagamento_esportula: [:competencia_mensal, :evento_escalas] },
        itens_lancamento: :plano_conta
      ).find(params[:id])
    end

    def load_form_collections
      @contas_correntes = ContaCorrente.ativas.order(:nome)
      @contas_receita = PlanoConta.ativas.analiticas.por_natureza("receita").ordenadas
      @contas_despesa = PlanoConta.ativas.analiticas.por_natureza("despesa").ordenadas
    end

    # Eventos do dia do lançamento (hoje, por padrão) + o evento já vinculado.
    # Outros períodos são buscados via #eventos.
    def eventos_para_select
      @eventos_para_select ||= eventos_do_dia_para_form.map { |e| [rotulo_evento_escala_select(e), e.id] }
    end
    helper_method :eventos_para_select

    def data_inicial_eventos
      @lancamento&.data || Date.current
    end
    helper_method :data_inicial_eventos

    def eventos_do_dia_para_form
      eventos = EventoEscala.nao_cancelados.includes(:tipo_servico, :sacerdote)
                            .where(data: data_inicial_eventos).order(:horario).to_a
      ev_id = @lancamento&.evento_escala_id
      if ev_id && eventos.none? { |e| e.id == ev_id }
        vinculado = EventoEscala.includes(:tipo_servico, :sacerdote).find_by(id: ev_id)
        eventos << vinculado if vinculado
      end
      eventos
    end

    def parse_data_param(valor)
      Date.iso8601(valor.to_s)
    rescue ArgumentError
      nil
    end

    def opcao_evento(evento)
      { id: evento.id, label: rotulo_evento_escala_select(evento) }
    end

    def rotulo_evento_escala_select(evento)
      rotulo = "#{I18n.l(evento.data)} #{evento.horario.strftime('%H:%M')} — #{evento.tipo_servico.nome}"
      evento.sacerdote ? "#{rotulo} — #{evento.sacerdote.nome}" : rotulo
    end

    def data_padrao_novo_lancamento
      return Date.current unless params[:mes].present? && params[:ano].present?

      inicio = Date.new(params[:ano].to_i, params[:mes].to_i, 1)
      fim = inicio.end_of_month
      [[Date.current, fim].min, inicio].max
    end

    def lancamento_params
      params.require(:lancamento_caixa).permit(
        :conta_corrente_id, :natureza, :data, :status,
        :evento_escala_id, :contado_por, :fornecedor,
        :tem_documento_fiscal, :tem_recibo, :observacoes, :valor_total,
        itens_lancamento_attributes: [:id, :plano_conta_id, :descricao, :quantidade, :preco_unitario, :valor_desconto, :valor, :ordem, :_destroy]
      )
    end
  end
end
