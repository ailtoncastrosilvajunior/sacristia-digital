# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def build_resource(hash = {})
      super
      if resource.new_record? && resource.perfis.blank?
        resource.perfis = ["ministro"]
      end
      resource
    end
  end
end
