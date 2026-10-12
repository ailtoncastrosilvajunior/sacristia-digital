# frozen_string_literal: true

# Estrutura do plantão extra por competência:
# - plantao_periodo_ministros: ministros de cada bloco de dias (cópia por competência)
# - evento_escala.plantao_periodo_id: bloco que cobre o evento extra
# - escala_ministros: ministro_original_id + motivo_troca (substituições direto na escala)
class AddPlantaoPorCompetenciaStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :plantao_periodo_ministros do |t|
      t.references :plantao_periodo, null: false, foreign_key: true
      t.references :ministro, null: false, foreign_key: true
      t.integer :ordem, null: false, default: 0

      t.timestamps
    end
    add_index :plantao_periodo_ministros, %i[plantao_periodo_id ministro_id],
              unique: true, name: "idx_plantao_periodo_ministros_unico"

    add_reference :evento_escala, :plantao_periodo, foreign_key: true, null: true

    add_reference :escala_ministros, :ministro_original,
                  foreign_key: { to_table: :ministros }, null: true
    add_column :escala_ministros, :motivo_troca, :string

    add_index :escala_ministros, %i[evento_escala_id ministro_id],
              unique: true, name: "idx_escala_ministros_evento_ministro"
  end
end
