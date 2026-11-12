# frozen_string_literal: true

class CreatePlanosAndInstituicoes < ActiveRecord::Migration[8.1]
  def change
    create_table :planos do |t|
      t.string :codigo, null: false
      t.string :nome, null: false
      t.text :descricao
      t.integer :preco_mensal_centavos, null: false, default: 0
      # text + JSON no model (mesmo padrão de liturgia_dias — PG remoto sem tipo jsonb)
      t.text :recursos, null: false, default: "{}"
      t.timestamps
    end
    add_index :planos, :codigo, unique: true

    create_table :instituicoes do |t|
      t.string :tipo, null: false, default: "comunidade"
      t.string :slug, null: false
      t.string :nome, null: false
      t.string :nome_curto
      t.string :slogan_rodape
      t.string :nome_recibos
      t.boolean :ativa, null: false, default: true
      t.string :assinatura_status, null: false, default: "ativa"
      t.timestamps
    end
    add_index :instituicoes, :slug, unique: true

    create_table :instituicao_planos do |t|
      t.references :instituicao, null: false, foreign_key: { to_table: :instituicoes }
      t.references :plano, null: false, foreign_key: { to_table: :planos }
      t.datetime :vigencia_inicio, null: false
      t.datetime :vigencia_fim
      t.integer :preco_mensal_centavos, null: false, default: 0
      t.text :recursos_snapshot, null: false, default: "{}"
      t.datetime :modulos_vigencia_inicio, null: false
      t.datetime :faturamento_inicio_em
      t.string :status, null: false, default: "vigente"
      t.string :motivo
      t.text :observacoes
      t.timestamps
    end

    add_index :instituicao_planos, %i[instituicao_id vigencia_fim],
              unique: true,
              where: "vigencia_fim IS NULL",
              name: "index_instituicao_planos_uma_vigencia_aberta"
  end
end
