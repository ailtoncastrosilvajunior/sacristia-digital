# frozen_string_literal: true

class InstituicaoIdNotNull < ActiveRecord::Migration[8.1]
  TABLES = AddInstituicaoIdToOperationalTables::TABLES

  def change
    TABLES.each do |table|
      change_column_null table, :instituicao_id, false
    end
  end
end
