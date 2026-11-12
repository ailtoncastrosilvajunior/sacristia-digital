# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Gates de plano por instituição", type: :request do
  let!(:plano_enxuto) do
    Plano.find_or_create_by!(codigo: "escala_liturgia") do |p|
      p.nome = "Escala e liturgia"
      p.preco_mensal_centavos = 0
      p.recursos = Plano::RECURSOS_ESCALA_LITURGIA
    end
  end
  let!(:inst) do
    Instituicoes::Provisioner.call(
      slug: "gates-spec",
      nome: "Gates Spec",
      plano_codigo: "escala_liturgia"
    ).instituicao
  end
  let(:admin) do
    User.create!(
      email: "admin-gates-#{SecureRandom.hex(4)}@example.com",
      password: "senha1234",
      password_confirmation: "senha1234",
      nome: "Admin",
      perfis: %w[admin],
      instituicao: inst
    )
  end

  before do
    host! "gates-spec.localhost"
    sign_in admin
  end

  it "permite competência MESC" do
    get admin_competencia_mensal_index_path
    expect(response).to have_http_status(:ok)
  end

  it "bloqueia extrato financeiro sem módulo caixa" do
    get admin_extrato_financeiro_path
    expect(response).to have_http_status(:not_found)
  end

  it "bloqueia espórtulas sem módulo" do
    get competencia_admin_registros_esportula_index_path
    expect(response).to have_http_status(:not_found)
  end
end
