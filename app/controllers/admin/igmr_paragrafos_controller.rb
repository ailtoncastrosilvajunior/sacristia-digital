# frozen_string_literal: true

module Admin
  class IgmrParagrafosController < Admin::BaseController
    before_action :set_paragrafo, only: %i[edit update]

    def index
      @paragrafos = IgmrParagrafo.ordenados
      @proximo_numero = Liturgia::IgmrRotacao.numero_para(Date.current)
      @total_cadastrados = IgmrParagrafo.count
      @limite = IgmrParagrafo::LIMITE_ROTACAO
    end

    def importar
      if request.post?
        arquivo = params[:arquivo]
        if arquivo.blank?
          flash.now[:alert] = "Selecione um arquivo CSV."
          return render :importar, status: :unprocessable_entity
        end

        @resultado = Liturgia::IgmrImportService.call(
          arquivo.tempfile,
          atualizar_existentes: params[:atualizar_existentes] == "1"
        )
        if @resultado.ok?
          redirect_to admin_igmr_paragrafos_path,
                      notice: "Importação concluída: #{@resultado.resumo}."
        else
          flash.now[:alert] = "Importação com problemas: #{@resultado.resumo}."
          render :importar, status: :unprocessable_entity
        end
      end
    end

    def new
      @paragrafo = IgmrParagrafo.new(numero: params[:numero].presence)
    end

    def create
      @paragrafo = IgmrParagrafo.new(paragrafo_params)
      if @paragrafo.save
        redirect_to admin_igmr_paragrafos_path, notice: "IGMR n.º #{@paragrafo.numero} cadastrado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @paragrafo.update(paragrafo_params)
        redirect_to admin_igmr_paragrafos_path, notice: "IGMR n.º #{@paragrafo.numero} atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_paragrafo
      @paragrafo = IgmrParagrafo.find(params[:id])
    end

    def paragrafo_params
      params.require(:igmr_paragrafo).permit(:numero, :texto, :fonte, :texto_conferido)
    end
  end
end
