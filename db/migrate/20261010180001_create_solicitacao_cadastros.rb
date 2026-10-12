# frozen_string_literal: true

class CreateSolicitacaoCadastros < ActiveRecord::Migration[8.1]
  def change
    create_table :solicitacao_cadastros do |t|
      t.string :nome, null: false
      t.string :email, null: false
      t.string :telefone
      t.string :sexo
      # Hash bcrypt (compatível com Devise). Nunca guarda a senha em texto puro.
      # É apagado quando a solicitação é aprovada ou rejeitada.
      t.string :encrypted_password
      t.string :status, null: false, default: "pendente"
      t.text :motivo_rejeicao
      t.references :ministro, foreign_key: true
      t.references :avaliado_por, foreign_key: { to_table: :users }
      t.datetime :avaliado_em

      t.timestamps
    end

    add_index :solicitacao_cadastros, :status
    add_index :solicitacao_cadastros, "LOWER(email)", name: "idx_solicitacao_cadastros_email_lower"
  end
end
