# frozen_string_literal: true

module InstituicaoScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :instituicao

    validates :instituicao_id, presence: true

    before_validation :atribuir_instituicao_atual, on: :create

    scope :da_instituicao_atual, lambda {
      if Current.instituicao
        where(instituicao_id: Current.instituicao.id)
      else
        none
      end
    }
  end

  private

  def atribuir_instituicao_atual
    self.instituicao_id ||= Current.instituicao&.id
  end
end
