# frozen_string_literal: true

class AddValorDescontoToItensLancamento < ActiveRecord::Migration[8.1]
  def up
    add_column :itens_lancamento, :valor_desconto, :decimal, precision: 12, scale: 2, default: "0.0", null: false

    say_with_time "Backfill valor_desconto a partir de qtd × preço − valor" do
      ItemLancamento.reset_column_information
      ItemLancamento.find_each do |item|
        bruto = (item.quantidade.to_d * item.preco_unitario.to_d).round(2)
        desconto = (bruto - item.valor.to_d).round(2)
        next if desconto <= 0.001

        item.update_column(:valor_desconto, desconto)
      end
    end
  end

  def down
    remove_column :itens_lancamento, :valor_desconto
  end
end
