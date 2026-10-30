# frozen_string_literal: true

module Admin
  class LiturgiaDiasController < Admin::BaseController
    before_action :set_liturgia_dia, only: [:show, :edit, :update, :validar, :reabrir, :sincronizar, :remover_imagem, :cartaz, :gerar_cartaz]

    def index
      @mes = parse_mes(params[:mes])
      registros = LiturgiaDia.where(data: @mes.beginning_of_month..@mes.end_of_month).index_by(&:data)
      @dias = (@mes.beginning_of_month..@mes.end_of_month).map { |d| [d, registros[d]] }
      @resumo = {
        validadas: registros.values.count(&:validada?),
        rascunhos: registros.values.count(&:rascunho?),
        divergentes: registros.values.count { |r| r.rascunho? && r.divergente? },
        faltando: @dias.count { |_, r| r.nil? }
      }
    end

    def show
      @igmr_numero = Liturgia::IgmrRotacao.numero_para(@liturgia_dia.data)
      @igmr_paragrafo = IgmrParagrafo.find_by(numero: @igmr_numero)
    end

    def cartaz
      unless @liturgia_dia.validada?
        redirect_to admin_liturgia_dia_path(@liturgia_dia), alert: "Valide a liturgia antes de gerar o cartaz."
        return
      end

      @cartaz = Liturgia::CartazBuilder.build(@liturgia_dia)
      render :cartaz, layout: "cartaz_whatsapp"
    end

    def gerar_cartaz
      unless @liturgia_dia.validada?
        redirect_to admin_liturgia_dia_path(@liturgia_dia), alert: "Valide a liturgia antes de gerar o cartaz."
        return
      end

      cartaz = Liturgia::CartazBuilder.build(@liturgia_dia)
      if cartaz.igmr_ausente?
        redirect_to cartaz_admin_liturgia_dia_path(@liturgia_dia),
                    alert: "Cadastre o IGMR n.º #{cartaz.igmr_numero} antes de gerar o PNG."
        return
      end

      Liturgia::CartazPngGenerator.new(@liturgia_dia).attach!
      redirect_to cartaz_admin_liturgia_dia_path(@liturgia_dia), notice: "Cartaz gerado e salvo no storage."
    rescue Liturgia::CartazPngGenerator::Erro => e
      redirect_to cartaz_admin_liturgia_dia_path(@liturgia_dia), alert: e.message
    end

    def edit
    end

    def update
      @liturgia_dia.assign_attributes(liturgia_dia_params)
      @liturgia_dia.leituras = leituras_params if params[:leituras].present?
      @liturgia_dia.reabrir_status_se_alterado!

      if @liturgia_dia.save
        redirect_to admin_liturgia_dia_path(@liturgia_dia), notice: "Liturgia salva. Revise e valide para liberar aos ministros."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Sem :data -> agenda a busca do mês inteiro em segundo plano; com :data -> busca o dia na hora.
    def buscar
      if params[:data].present?
        data = Date.parse(params[:data])
        resposta = Liturgia::SincronizarService.call(data)
        if resposta.ok?
          redirect_to admin_liturgia_dia_path(resposta.liturgia_dia), notice: mensagem_busca(resposta)
        else
          redirect_to admin_liturgia_dias_path(mes: data.strftime("%Y-%m")), alert: "Não foi possível buscar #{I18n.l(data)}: #{resposta.mensagem}"
        end
      else
        mes = parse_mes(params[:mes])
        inicio = [mes.beginning_of_month, Date.current].max
        dias = (mes.end_of_month - inicio).to_i + 1
        if dias <= 0
          redirect_to admin_liturgia_dias_path(mes: mes.strftime("%Y-%m")), alert: "Esse mês já passou."
        else
          LiturgiaSincronizarJob.perform_later(inicio, dias)
          redirect_to admin_liturgia_dias_path(mes: mes.strftime("%Y-%m")),
                      notice: "Busca de #{dias} dia(s) iniciada em segundo plano. Atualize a página em instantes."
        end
      end
    rescue Date::Error
      redirect_to admin_liturgia_dias_path, alert: "Data inválida."
    end

    def sincronizar
      resposta = Liturgia::SincronizarService.call(@liturgia_dia.data, forcar: true)
      if resposta.ok?
        notice = if resposta.status == :validada_automaticamente
                   "Leituras buscadas novamente. As fontes concordaram — liturgia validada automaticamente."
                 else
                   "Leituras buscadas novamente. A liturgia ficou em rascunho para conferência."
                 end
        redirect_to admin_liturgia_dia_path(@liturgia_dia), notice: notice
      else
        redirect_to admin_liturgia_dia_path(@liturgia_dia), alert: "Falha ao buscar: #{resposta.mensagem}"
      end
    end

    def validar
      if @liturgia_dia.leituras.blank?
        redirect_to admin_liturgia_dia_path(@liturgia_dia), alert: "Não há leituras para validar."
      elsif @liturgia_dia.santo_nome.blank?
        redirect_to admin_liturgia_dia_path(@liturgia_dia), alert: "Informe o nome do santo do dia antes de validar (imagem é opcional)."
      else
        @liturgia_dia.validar!(current_user)
        redirect_to admin_liturgia_dias_path(mes: @liturgia_dia.data.strftime("%Y-%m")), notice: "Liturgia de #{I18n.l(@liturgia_dia.data)} validada e liberada aos ministros."
      end
    end

    def reabrir
      @liturgia_dia.reabrir!
      redirect_to admin_liturgia_dia_path(@liturgia_dia), notice: "Liturgia retirada da área dos ministros (rascunho)."
    end

    def remover_imagem
      @liturgia_dia.imagem_santo.purge
      redirect_to edit_admin_liturgia_dia_path(@liturgia_dia), notice: "Imagem removida."
    end

    private

    def set_liturgia_dia
      @liturgia_dia = LiturgiaDia.with_attached_imagem_santo.with_attached_cartaz_whatsapp.find(params[:id])
    end

    def parse_mes(raw)
      Date.strptime("#{raw}-01", "%Y-%m-%d")
    rescue ArgumentError, TypeError
      Date.current.beginning_of_month
    end

    def mensagem_busca(resposta)
      case resposta.status
      when :ignorada then resposta.mensagem
      when :validada_automaticamente
        "Liturgia validada automaticamente (fontes concordaram)."
      else
        base = "Liturgia buscada (rascunho)."
        ld = resposta.liturgia_dia
        if ld.divergente?
          "#{base} Há divergências entre as fontes — confira antes de validar."
        elsif ld.santo_nome.blank?
          "#{base} Informe o nome do santo do dia para validar."
        else
          base
        end
      end
    end

    def liturgia_dia_params
      params.require(:liturgia_dia).permit(:titulo, :cor, :santo_nome, :santo_descricao, :observacoes, :imagem_santo)
    end

    def leituras_params
      params[:leituras].to_unsafe_h.values.map do |l|
        { "tipo" => l["tipo"].to_s, "rotulo" => l["rotulo"].to_s, "referencia" => l["referencia"].to_s.strip, "texto" => l["texto"].to_s.strip }
      end.reject { |l| l["referencia"].blank? && l["texto"].blank? }
    end
  end
end
