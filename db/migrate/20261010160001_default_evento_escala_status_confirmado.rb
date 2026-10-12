class DefaultEventoEscalaStatusConfirmado < ActiveRecord::Migration[8.1]
  def change
    change_column_default :evento_escala, :status, from: "pendente", to: "confirmado"
  end
end
