# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Perfil escala_extra", type: :request do
  include Devise::Test::IntegrationHelpers

  def criar_usuario(perfis:, nome: "Agendador")
    User.create!(email: "#{SecureRandom.hex(4)}@example.com", password: "senha1234", password_confirmation: "senha1234", nome: nome, perfis: perfis)
  end

  let(:agendador) { criar_usuario(perfis: %w[escala_extra]) }

  describe "validação do perfil" do
    it "é um perfil válido e exige nome" do
      expect(User::PERFIS_VALIDOS).to include("escala_extra")
      user = User.new(email: "a@example.com", password: "senha1234", perfis: %w[escala_extra])
      expect(user).not_to be_valid
      expect(user.errors[:nome]).to be_present
    end

    it "redireciona o perfil principal para a escala extra" do
      expect(agendador.perfil_principal_redirect).to eq(:escala_extra)
    end
  end

  describe "acesso" do
    before { sign_in agendador }

    it "leva a raiz para a área da escala extra" do
      get root_path
      expect(response).to redirect_to(escala_extra_root_path)
    end

    it "acessa a lista de eventos extra" do
      get escala_extra_root_path
      expect(response).to have_http_status(:ok)
    end

    it "é barrado em admin, coordenador e ministro sem loop de redirect" do
      [admin_root_path, admin_users_path, coordenador_root_path, ministro_root_path].each do |path|
        get path
        expect(response).to have_http_status(:found)
        expect(response.location).to end_with(root_path)
      end
      get root_path
      expect(response).to redirect_to(escala_extra_root_path)
    end
  end

  describe "espórtula" do
    it "não é aceita nos params do agendador" do
      sign_in agendador
      controller = EscalaExtra::EventosExtraController.new
      expect(controller.send(:campos_permitidos)).not_to include(:valor_esportula)
      expect(Admin::EventosExtraController.new.send(:campos_permitidos)).to include(:valor_esportula)
    end
  end

  describe "usuário comum" do
    it "não acessa a escala extra" do
      sign_in criar_usuario(perfis: %w[coordenador], nome: "Coord")
      get escala_extra_root_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "administrador" do
    it "continua acessando as duas áreas" do
      sign_in criar_usuario(perfis: %w[admin], nome: "Admin")
      get admin_eventos_extra_index_path
      expect(response).to have_http_status(:ok)
      get escala_extra_root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
