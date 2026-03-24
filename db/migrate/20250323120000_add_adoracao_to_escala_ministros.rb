# frozen_string_literal: true

class AddAdoracaoToEscalaMinistros < ActiveRecord::Migration[8.1]
  def change
    add_column :escala_ministros, :adoracao, :boolean, default: false, null: false
  end
end
