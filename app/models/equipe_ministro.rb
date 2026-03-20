# frozen_string_literal: true

class EquipeMinistro < ApplicationRecord
  belongs_to :equipe
  belongs_to :ministro

  validates :ministro_id, uniqueness: { scope: :equipe_id }
end
