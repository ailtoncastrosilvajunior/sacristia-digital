# frozen_string_literal: true

# Totais da competência via agregação SQL — sem carregar todos os eventos em memória.
class EsportulasCompetenciaResumo
  def self.call(competencia)
    new(competencia).call
  end

  def initialize(competencia)
    @competencia = competencia
  end

  def call
    linhas = linhas_por_sacerdote
    totais = {
      missas: linhas.sum { |l| l[:missas] },
      confissoes: linhas.sum { |l| l[:confissoes] },
      total_servicos: linhas.sum { |l| l[:total_servicos] },
      previsto: linhas.sum { |l| l[:previsto] },
      realizado: linhas.sum { |l| l[:realizado] },
      saldo: linhas.sum { |l| l[:saldo] },
      previsto_imediato: linhas.sum { |l| l[:previsto_imediato] }
    }
    [linhas, totais]
  end

  private

  def base_scope
    EventoEscala
      .where(competencia_mensal_id: @competencia.id)
      .nao_cancelados
      .where("evento_escala.valor_esportula > 0")
      .where.not(sacerdote_id: nil)
  end

  def linhas_por_sacerdote
    comp_id = ActiveRecord::Base.connection.quote(@competencia.id)
    realizado_sql = <<~SQL.squish
      COALESCE((
        SELECT SUM(e2.valor_esportula)
        FROM evento_escala e2
        INNER JOIN registro_esportulas r ON r.evento_escala_id = e2.id AND r.status = 'pago'
        WHERE e2.competencia_mensal_id = #{comp_id}
          AND e2.sacerdote_id = evento_escala.sacerdote_id
          AND e2.status <> 'cancelado'
          AND e2.valor_esportula > 0
          AND e2.esportula_modo = 'imediato'
      ), 0) AS realizado
    SQL

    previsto_imediato_sql = <<~SQL.squish
      COALESCE(SUM(CASE WHEN evento_escala.esportula_modo = 'imediato' THEN evento_escala.valor_esportula ELSE 0 END), 0) AS previsto_imediato
    SQL

    agregados = base_scope
      .joins(:tipo_servico)
      .group(:sacerdote_id)
      .select(
        :sacerdote_id,
        Arel.sql("COUNT(*) AS total_servicos"),
        Arel.sql("SUM(CASE WHEN tipo_servicos.nome ILIKE '%missa%' THEN 1 ELSE 0 END) AS missas"),
        Arel.sql("SUM(CASE WHEN tipo_servicos.nome ILIKE '%confiss%' THEN 1 ELSE 0 END) AS confissoes"),
        Arel.sql("COALESCE(SUM(evento_escala.valor_esportula), 0) AS previsto"),
        Arel.sql(previsto_imediato_sql),
        Arel.sql(realizado_sql)
      )

    sacerdote_ids = agregados.map(&:sacerdote_id)
    sacerdotes = Sacerdote.where(id: sacerdote_ids).index_by(&:id)

    agregados.filter_map do |row|
      sacerdote = sacerdotes[row.sacerdote_id]
      next unless sacerdote

      previsto = row.read_attribute("previsto").to_d
      previsto_imediato = row.read_attribute("previsto_imediato").to_d
      realizado = row.read_attribute("realizado").to_d
      {
        sacerdote: sacerdote,
        missas: row.read_attribute("missas").to_i,
        confissoes: row.read_attribute("confissoes").to_i,
        total_servicos: row.read_attribute("total_servicos").to_i,
        previsto: previsto,
        previsto_imediato: previsto_imediato,
        realizado: realizado,
        saldo: previsto_imediato - realizado
      }
    end.sort_by { |l| l[:sacerdote].nome.to_s.downcase }
  end
end
