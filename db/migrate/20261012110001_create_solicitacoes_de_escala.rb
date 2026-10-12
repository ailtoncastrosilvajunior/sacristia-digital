# frozen_string_literal: true

# Pedidos do ministro sobre a escala: troca de uma celebração e oferta de apoio no plantão.
class CreateSolicitacoesDeEscala < ActiveRecord::Migration[8.1]
  def change
    create_table :solicitacao_trocas do |t|
      t.references :escala_ministro, null: false, foreign_key: true
      t.text :motivo
      t.string :status, null: false, default: "pendente"
      t.references :avaliado_por, foreign_key: { to_table: :users }
      t.datetime :avaliado_em

      t.timestamps
    end
    add_index :solicitacao_trocas, :status

    create_table :oferta_apoios do |t|
      t.references :ministro, null: false, foreign_key: true
      t.references :competencia_mensal, null: false, foreign_key: { to_table: :competencia_mensal }
      t.date :data, null: false
      t.string :status, null: false, default: "pendente"
      t.references :avaliado_por, foreign_key: { to_table: :users }
      t.datetime :avaliado_em

      t.timestamps
    end
    add_index :oferta_apoios, %i[ministro_id data], unique: true
    add_index :oferta_apoios, :status
  end
end
