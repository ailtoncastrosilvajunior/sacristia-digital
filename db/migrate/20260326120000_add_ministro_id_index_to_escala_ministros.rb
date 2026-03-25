# frozen_string_literal: true

class AddMinistroIdIndexToEscalaMinistros < ActiveRecord::Migration[8.1]
  def change
    add_index :escala_ministros, :ministro_id
  end
end
