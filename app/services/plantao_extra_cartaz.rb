# frozen_string_literal: true

# Monta os dados do cartaz WhatsApp de um bloco de plantão extra.
class PlantaoExtraCartaz
  Dia = Struct.new(:data, :eventos, keyword_init: true)

  attr_reader :plantao, :competencia, :dias

  def self.build(plantao)
    new(plantao).tap(&:load!)
  end

  def initialize(plantao)
    @plantao = plantao
    @competencia = plantao.competencia_mensal
    @dias = []
  end

  def load!
    intervalo = datas_do_plantao
    return if intervalo.empty?

    eventos = @competencia.evento_escalas.extras.nao_cancelados
                          .where(data: intervalo.min..intervalo.max)
                          .includes(:tipo_servico, :sacerdote)
                          .por_data
                          .to_a

    por_data = eventos.group_by(&:data)
    @dias = intervalo.filter_map do |data|
      evs = por_data[data]
      next if evs.blank?

      Dia.new(data: data, eventos: evs)
    end
  end

  def periodo_rotulo
    mes = I18n.l(@competencia.periodo, format: "%B").upcase
    if @plantao.dia_inicio == @plantao.dia_fim
      "DIA #{@plantao.dia_inicio} DE #{mes}"
    else
      "DIAS #{@plantao.dia_inicio} e #{@plantao.dia_fim} DE #{mes}"
    end
  end

  def nomes_plantao
    nomes = @plantao.ministros.map(&:nome)
    case nomes.size
    when 0 then "—"
    when 1 then nomes.first
    when 2 then "#{nomes[0]} e #{nomes[1]}"
    else "#{nomes[0..-2].join(', ')} e #{nomes.last}"
    end
  end

  def vazio?
    @dias.empty?
  end

  private

  def datas_do_plantao
    @plantao.range_dias.filter_map do |dia|
      Date.new(@competencia.ano, @competencia.mes, dia)
    rescue ArgumentError
      nil
    end
  end
end
