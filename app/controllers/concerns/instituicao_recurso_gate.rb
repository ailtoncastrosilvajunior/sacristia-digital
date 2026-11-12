# frozen_string_literal: true

# Declara `before_action` que retorna 404 quando o módulo não está no plano vigente da instituição.
module InstituicaoRecursoGate
  extend ActiveSupport::Concern

  class_methods do
    def require_instituicao_modulo!(chave)
      before_action do
        require_instituicao_recurso!(chave)
      end
    end
  end
end
