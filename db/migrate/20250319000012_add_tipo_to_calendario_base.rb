# frozen_string_literal: true

class AddTipoToCalendarioBase < ActiveRecord::Migration[8.1]
  def change
    add_column :calendario_base, :tipo, :string, default: "missa", null: false
  end
end
