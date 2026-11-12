# frozen_string_literal: true

class LiturgiaCartaz < ApplicationRecord
  include InstituicaoScoped

  self.table_name = "liturgia_cartazes"

  belongs_to :liturgia_dia

  has_one_attached :cartaz_whatsapp

  validates :liturgia_dia_id, uniqueness: { scope: :instituicao_id }
end
