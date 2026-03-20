# frozen_string_literal: true

class CreateTiposServico < ActiveRecord::Migration[8.0]
  def change
    create_table :tipo_servicos do |t|
      t.string :nome, null: false
      t.string :tipo_escala, null: false, default: "ordinaria"
      t.string :cor_etiqueta, default: "#64748b"
      t.boolean :ativo, default: true, null: false

      t.timestamps
    end

    add_index :tipo_servicos, [:tipo_escala, :ativo]
  end
end
