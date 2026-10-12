# frozen_string_literal: true

# A troca passa a ser combinada entre ministros: quem solicita indica o substituto e só ele precisa aceitar.
class TrocaEntreMinistros < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM solicitacao_trocas"
    remove_reference :solicitacao_trocas, :avaliado_por, foreign_key: { to_table: :users }, index: true
    rename_column :solicitacao_trocas, :avaliado_em, :respondido_em
    add_reference :solicitacao_trocas, :substituto, null: false, foreign_key: { to_table: :ministros }
  end

  def down
    remove_reference :solicitacao_trocas, :substituto, foreign_key: { to_table: :ministros }
    rename_column :solicitacao_trocas, :respondido_em, :avaliado_em
    add_reference :solicitacao_trocas, :avaliado_por, foreign_key: { to_table: :users }
  end
end
