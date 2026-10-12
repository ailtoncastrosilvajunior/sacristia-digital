# frozen_string_literal: true

# O apoio ao plantão passa a valer na hora (sem aprovação do admin): status "ativa" ou "cancelada".
class ApoioSemAprovacao < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE oferta_apoios SET status = 'ativa' WHERE status IN ('pendente', 'aceita')"
    execute "UPDATE oferta_apoios SET status = 'cancelada' WHERE status = 'recusada'"
    change_column_default :oferta_apoios, :status, from: "pendente", to: "ativa"
    remove_reference :oferta_apoios, :avaliado_por, foreign_key: { to_table: :users }, index: true
    remove_column :oferta_apoios, :avaliado_em
  end

  def down
    add_column :oferta_apoios, :avaliado_em, :datetime
    add_reference :oferta_apoios, :avaliado_por, foreign_key: { to_table: :users }
    change_column_default :oferta_apoios, :status, from: "ativa", to: "pendente"
  end
end
