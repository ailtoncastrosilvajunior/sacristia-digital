# frozen_string_literal: true

# Helpers de busca/filtro de listagens compartilhados entre as áreas administrativas.
module Buscavel
  extend ActiveSupport::Concern

  included do
    helper_method :lista_filtrada?
  end

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
end
