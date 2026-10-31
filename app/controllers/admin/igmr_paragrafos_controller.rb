# frozen_string_literal: true

module Admin
  class IgmrParagrafosController < Admin::BaseController
    include Admin::ReturnToRedirect

    before_action :set_paragrafo, only: %i[show edit update]

    def referencia
    end

    def index
      @paragrafos = IgmrParagrafo.ordenados
      @proximo_numero = Liturgia::IgmrRotacao.numero_para(Date.current)
      @total_cadastrados = IgmrParagrafo.count
      @limite = IgmrParagrafo::LIMITE_ROTACAO
    end

    def sincronizar_cnbb
      default = admin_igmr_paragrafos_path
      fixture = Liturgia::IgmrFixtureImportService::FIXTURE_PATH
      unless File.file?(fixture)
        redirect_with_return_to(
          default: default,
          alert: "Fixture não encontrado (#{fixture.basename}). Rode o pipeline do PDF CNBB ou use bin/rails igmr:import_fixture em deploy."
        )
        return
      end

      res = Liturgia::IgmrFixtureImportService.call(update_existing: true, preserve_conferidos: true)
      redirect_with_return_to(default: default, notice: "Textos CNBB sincronizados: #{resumo_fixture(res)}.")
    end

    def show
      @return_to = safe_return_to_path
      @numero_hoje = Liturgia::IgmrRotacao.numero_para(Date.current)
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
      @return_to = safe_return_to_path
      @paragrafo = IgmrParagrafo.new(
        numero: params[:numero].presence,
        edicao: IgmrParagrafo::EDICAO_REFERENCIA
      )
    end

    def create
      @return_to = safe_return_to_path
      @paragrafo = IgmrParagrafo.new(paragrafo_params)
      if @paragrafo.save
        redirect_with_return_to(
          default: admin_igmr_paragrafos_path,
          notice: "IGMR n.º #{@paragrafo.numero} cadastrado."
        )
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @return_to = safe_return_to_path
    end

    def update
      @return_to = safe_return_to_path
      if @paragrafo.update(paragrafo_params)
        redirect_with_return_to(
          default: admin_igmr_paragrafos_path,
          notice: "IGMR n.º #{@paragrafo.numero} atualizado."
        )
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_paragrafo
      @paragrafo = IgmrParagrafo.find(params[:id])
    end

    def paragrafo_params
      params.require(:igmr_paragrafo).permit(:numero, :texto, :trecho_cartaz, :fonte, :edicao, :texto_conferido)
    end

    def resumo_fixture(res)
      parts = []
      parts << "#{res.criados} criado(s)" if res.criados.positive?
      parts << "#{res.atualizados} atualizado(s)" if res.atualizados.positive?
      parts << "#{res.ignorados} ignorado(s)" if res.ignorados.positive?
      parts.presence&.join(", ") || "Nenhuma alteração"
    end
  end
end
