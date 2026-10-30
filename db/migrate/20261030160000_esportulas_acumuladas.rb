# frozen_string_literal: true

class EsportulasAcumuladas < ActiveRecord::Migration[8.0]
  def change
    create_table :destinatarios_esportula do |t|
      t.string :nome, null: false
      t.boolean :ativo, default: true, null: false
      t.text :observacoes
      t.timestamps
    end

    add_column :calendario_base, :esportula_modo, :string, default: "imediato", null: false
    add_reference :calendario_base, :destinatario_esportula, foreign_key: { to_table: :destinatarios_esportula }

    add_reference :evento_escala, :calendario_base, foreign_key: { to_table: :calendario_base }
    add_column :evento_escala, :esportula_modo, :string, default: "imediato", null: false
    add_column :evento_escala, :esportula_destinatario_tipo, :string, default: "sacerdote", null: false
    add_reference :evento_escala, :esportula_destinatario_sacerdote, foreign_key: { to_table: :sacerdotes }
    add_reference :evento_escala, :destinatario_esportula, foreign_key: { to_table: :destinatarios_esportula }
    add_column :evento_escala, :esportula_destinatario_manual, :boolean, default: false, null: false

    create_table :lote_pagamento_esportulas do |t|
      t.references :competencia_mensal, null: false, foreign_key: { to_table: :competencia_mensal }
      t.string :destinatario_tipo, null: false
      t.references :destinatario_esportula, foreign_key: { to_table: :destinatarios_esportula }
      t.references :destinatario_sacerdote, foreign_key: { to_table: :sacerdotes }
      t.decimal :valor, precision: 12, scale: 2, null: false, default: 0
      t.date :data_pagamento
      t.string :status, default: "pendente", null: false
      t.string :forma_pagamento
      t.timestamps
    end

    create_table :lote_pagamento_esportula_eventos do |t|
      t.references :lote_pagamento_esportula, null: false, foreign_key: { to_table: :lote_pagamento_esportulas }
      t.references :evento_escala, null: false, foreign_key: { to_table: :evento_escala }
      t.timestamps
      t.index [:evento_escala_id], unique: true, name: "idx_lote_esportula_evento_unico"
    end

    add_reference :registro_esportulas, :lote_pagamento_esportula, foreign_key: true
    add_reference :lancamentos_caixa, :lote_pagamento_esportula, foreign_key: true
    add_index :lancamentos_caixa, :lote_pagamento_esportula_id, unique: true,
              where: "lote_pagamento_esportula_id IS NOT NULL",
              name: "index_lancamentos_caixa_on_lote_esportula_unique"
  end
end
