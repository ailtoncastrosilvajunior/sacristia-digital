# frozen_string_literal: true

# Escala do mês (montagem dos dias + impressão/PDF) compartilhada entre o painel do ministro
# e o admin. Toda manutenção do relatório impresso fica aqui e em
# painel_ministro/escala_mensal/imprimir.html.erb.
#
# O controller que incluir este módulo precisa definir @competencias e @competencia
# e chamar montar_escala_mensal antes de `imprimir`.
module EscalaMensalImpressao
  extend ActiveSupport::Concern

  # Linha do dia. plantao_rowspan só vem preenchido no primeiro dia exibido do bloco de plantão.
  Dia = Struct.new(:data, :eventos, :extras, :plantao, :plantao_rowspan, :plantao_continuacao, keyword_init: true)

  def imprimir
    # A tabela impressa só tem dias com celebrações ordinárias.
    @dias = @dias.select { |d| d.eventos.any? }
    agrupar_plantao!(@dias)
    @total_linhas = @dias.sum { |d| d.eventos.size }
    @fonte_pt = fonte_para_impressao
    render template: "painel_ministro/escala_mensal/imprimir", layout: "impressao"
  end

  private

  def montar_escala_mensal
    eventos = @competencia.evento_escalas
                          .ordinarios.nao_cancelados
                          .includes(:sacerdote, :tipo_servico, escala_ministros: :ministro)
                          .por_data
                          .select(&:requer_ministros?)
    extras = @competencia.evento_escalas
                         .extras.nao_cancelados
                         .includes(:sacerdote, :tipo_servico, escala_ministros: :ministro)
                         .por_data.to_a
    por_dia = eventos.group_by(&:data)
    extras_por_dia = extras.group_by(&:data)
    plantoes = @competencia.plantao_periodos.includes(:ministros).ordenados.to_a

    @dias = (por_dia.keys | extras_por_dia.keys).sort.map do |data|
      Dia.new(data: data, eventos: por_dia[data] || [], extras: extras_por_dia[data] || [],
              plantao: plantoes.find { |p| p.cobre_dia?(data) })
    end
    agrupar_plantao!(@dias)
  end

  # Mescla células de "Escala Extra" entre dias consecutivos do mesmo bloco.
  def agrupar_plantao!(dias)
    dias.each_with_index do |dia, i|
      dia.plantao_continuacao = false
      anterior = i.positive? ? dias[i - 1] : nil
      if dia.plantao && anterior&.plantao == dia.plantao
        dia.plantao_continuacao = true
      else
        dia.plantao_rowspan = dia.eventos.size
        j = i + 1
        while dia.plantao && dias[j]&.plantao == dia.plantao
          dia.plantao_rowspan += dias[j].eventos.size
          j += 1
        end
      end
    end
  end

  # Auto: tenta caber o mês numa página A4 retrato. "grande": fonte maior, pode usar 2 páginas.
  def fonte_para_impressao
    return 13.0 if params[:tamanho] == "grande"

    linhas = @total_linhas + @dias.size * 0.15 + 4
    (700.0 / (linhas * 1.75)).clamp(8.0, 13.0).round(1)
  end

  def resolve_competencia
    if params[:competencia_mensal_id].present?
      c = @competencias.find { |x| x.id == params[:competencia_mensal_id].to_i }
      return c if c
    end
    hoje = Date.current
    @competencias.find { |c| c.ano == hoje.year && c.mes == hoje.month } || @competencias.first
  end
end
