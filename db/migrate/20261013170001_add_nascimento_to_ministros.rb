# frozen_string_literal: true

# Data de nascimento "parcial": dia e mês são obrigatórios (aniversariantes), o ano é opcional
# e só pode ser divulgado se o ministro autorizar (exibir_ano_nascimento).
class AddNascimentoToMinistros < ActiveRecord::Migration[8.1]
  def change
    %i[ministros solicitacao_cadastros].each do |tabela|
      change_table tabela, bulk: true do |t|
        t.integer :nascimento_dia
        t.integer :nascimento_mes
        t.integer :nascimento_ano
        t.boolean :exibir_ano_nascimento, default: false, null: false
      end
    end

    add_index :ministros, %i[nascimento_mes nascimento_dia]
  end
end
