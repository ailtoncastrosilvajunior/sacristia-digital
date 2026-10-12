# frozen_string_literal: true

# Converte o vínculo evento -> equipe em evento -> plantao_periodo (por competência)
# e remove as tabelas globais de equipes.
class ReplaceEquipesByPlantaoPeriodos < ActiveRecord::Migration[8.1]
  def up
    # 1) Eventos que já tinham equipe: cria um bloco por (competência, equipe),
    #    copiando os ministros atuais da equipe (aproximação do que valia na época).
    pares = select_rows(<<~SQL)
      SELECT DISTINCT e.competencia_mensal_id, e.equipe_id
      FROM evento_escala e
      WHERE e.equipe_id IS NOT NULL
    SQL

    pares.each do |competencia_id, equipe_id|
      dia_inicio, dia_fim = select_rows("SELECT dia_inicio, dia_fim FROM equipes WHERE id = #{equipe_id.to_i}").first

      if dia_inicio.nil? || dia_fim.nil?
        dia_inicio, dia_fim = select_rows(<<~SQL).first
          SELECT MIN(EXTRACT(DAY FROM data))::int, MAX(EXTRACT(DAY FROM data))::int
          FROM evento_escala
          WHERE competencia_mensal_id = #{competencia_id.to_i} AND equipe_id = #{equipe_id.to_i}
        SQL
      end

      periodo_id = select_value(<<~SQL)
        INSERT INTO plantao_periodos (competencia_mensal_id, equipe_id, dia_inicio, dia_fim, created_at, updated_at)
        VALUES (#{competencia_id.to_i}, #{equipe_id.to_i}, #{dia_inicio.to_i}, #{dia_fim.to_i}, NOW(), NOW())
        RETURNING id
      SQL

      execute(<<~SQL)
        INSERT INTO plantao_periodo_ministros (plantao_periodo_id, ministro_id, ordem, created_at, updated_at)
        SELECT #{periodo_id.to_i}, ministro_id, ordem, NOW(), NOW()
        FROM equipe_ministros WHERE equipe_id = #{equipe_id.to_i}
      SQL

      execute(<<~SQL)
        UPDATE evento_escala SET plantao_periodo_id = #{periodo_id.to_i}
        WHERE competencia_mensal_id = #{competencia_id.to_i} AND equipe_id = #{equipe_id.to_i}
      SQL
    end

    # 2) Remove o legado
    remove_reference :evento_escala, :equipe, foreign_key: true, index: true
    remove_reference :plantao_periodos, :equipe, foreign_key: true, index: true
    drop_table :equipe_ministros
    drop_table :equipes
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Restaure o backup (pg_dump) para reverter a remoção de equipes."
  end
end
