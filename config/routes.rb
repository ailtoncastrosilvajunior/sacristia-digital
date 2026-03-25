# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, path: "", path_names: {
    sign_in: "entrar",
    sign_out: "sair",
    sign_up: "cadastrar"
  }, controllers: { registrations: "users/registrations" }

  root "dashboard#index"

  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :ministros
    resources :sacerdotes
    resources :tipo_servicos, path: "tipo-servicos"
    resources :calendario_base, path: "calendario-base"
    resources :equipes
    resources :competencia_mensal, path: "competencia-mensal" do
      member do
        post :gerar_escala
        post :regenerar_escala
      end
    end
    resources :evento_escala, path: "eventos-escala", only: [:show, :new, :create, :edit, :update, :destroy] do
      member do
        get :escalar_ministros
        patch :update_escalar_ministros
      end
    end
    resources :eventos_extra, path: "eventos-extra"
    resources :registros_esportula, path: "esportulas"
    get "relatorios", to: "relatorios#index"
  end

  namespace :sacerdote do
    root "dashboard#index"
  end

  namespace :coordenador do
    root "dashboard#index"
    resources :ministros, only: [:index, :show]
    resources :competencia_mensal, path: "competencia-mensal", only: [:index, :show]
    resources :eventos_extra, path: "eventos-extra"
  end

  # path e helpers permanecem /ministro e ministro_*; módulo PainelMinistro evita colisão Zeitwerk com o model Ministro
  scope path: "ministro", module: "painel_ministro", as: "ministro" do
    root "dashboard#index"
    get "meus-servicos", to: "servicos#index"
    resources :servicos, only: [:show] do
      member do
        patch :confirmar
      end
    end
  end
end
