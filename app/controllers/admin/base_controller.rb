# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authorize_admin!

    layout "admin"

    helper_method :lista_filtrada?

    private

    # Indica se a listagem está com busca rápida ou filtros aplicados.
    def lista_filtrada?(*filtros)
      params[:q].present? || filtros.any? { |f| params[f].present? }
    end

    # Busca textual simples (sem diferenciar maiúsculas) em colunas da tabela.
    def busca_em(scope, colunas)
      termo = params[:q].to_s.strip.downcase
      return scope if termo.blank?

      like = "%#{ActiveRecord::Base.sanitize_sql_like(termo)}%"
      scope.where(colunas.map { |c| "LOWER(#{c}) LIKE :q" }.join(" OR "), q: like)
    end

    def authorize_admin!
      return if current_user&.admin?
      flash[:alert] = "Acesso restrito a administradores."
      redirect_to root_path
    end
  end
end
