# frozen_string_literal: true

class AddCoordenadorToEscalaMinistros < ActiveRecord::Migration[8.0]
  def change
    add_column :escala_ministros, :coordenador, :boolean, default: false, null: false
  end
end
