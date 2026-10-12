# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    # Cadastro aberto desativado: novos ministros usam o pré-cadastro com aprovação do admin.
    prepend_before_action :bloquear_cadastro_publico, only: [:new, :create]

    protected

    def bloquear_cadastro_publico
      redirect_to novo_pre_cadastro_path
    end


    def after_update_path_for(_resource)
      root_path
    end

    def build_resource(hash = {})
      super
      if resource.new_record? && resource.perfis.blank?
        resource.perfis = ["ministro"]
      end
      resource
    end
  end
end
