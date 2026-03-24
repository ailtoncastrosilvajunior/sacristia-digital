# frozen_string_literal: true

class AddPlantaoDiasToEquipes < ActiveRecord::Migration[8.1]
  def change
    add_column :equipes, :dia_inicio, :integer
    add_column :equipes, :dia_fim, :integer
  end
end
