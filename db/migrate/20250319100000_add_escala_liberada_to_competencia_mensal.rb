# frozen_string_literal: true

class AddEscalaLiberadaToCompetenciaMensal < ActiveRecord::Migration[8.1]
  def change
    add_column :competencia_mensal, :escala_liberada, :boolean, default: false, null: false
  end
end
