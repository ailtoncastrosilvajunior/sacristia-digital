# frozen_string_literal: true

# `nome` segue sendo o nome curto (usado nas escalas); `nome_completo` guarda o nome inteiro.
class AddNomeCompletoToMinistrosAndSolicitacaoCadastros < ActiveRecord::Migration[8.1]
  def change
    add_column :ministros, :nome_completo, :string
    add_column :solicitacao_cadastros, :nome_completo, :string
  end
end
