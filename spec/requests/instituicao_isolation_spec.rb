# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Isolamento entre instituições", type: :request do
  let(:inst_a) { Instituicao.find_by!(slug: "facedecristo") }
  let!(:inst_b) do
    Instituicao.create!(
      slug: "isolamento-spec",
      nome: "Instituição Spec",
      ativa: true,
      assinatura_status: "ativa",
      tipo: "comunidade"
    )
  end
  let!(:comp_b) do
    Current.instituicao = inst_b
    CompetenciaMensal.create!(ano: 2099, mes: 6, instituicao: inst_b)
  ensure
    Current.instituicao = inst_a
  end
  let(:admin) do
    User.create!(
      email: "admin-isolamento-#{SecureRandom.hex(4)}@example.com",
      password: "senha1234",
      password_confirmation: "senha1234",
      nome: "Admin",
      perfis: %w[admin],
      instituicao: inst_a
    )
  end

  before do
    host! "facedecristo.localhost"
    sign_in admin
  end

  it "não expõe competência de outra instituição no admin" do
    get admin_competencia_mensal_path(comp_b)
    expect(response).to have_http_status(:not_found)
  end

  it "não expõe ministro de outra instituição no coordenador" do
    Current.instituicao = inst_b
    outro = Ministro.create!(
      nome: "Outro Ministro",
      ativo: true,
      instituicao: inst_b,
      nascimento_dia: 1,
      nascimento_mes: 1
    )
    Current.instituicao = inst_a

    coordenador = User.create!(
      email: "coord-isolamento-#{SecureRandom.hex(4)}@example.com",
      password: "senha1234",
      password_confirmation: "senha1234",
      nome: "Coord",
      perfis: %w[coordenador],
      instituicao: inst_a
    )
    sign_in coordenador

    get coordenador_ministro_path(outro)
    expect(response).to have_http_status(:not_found)
  end
end
