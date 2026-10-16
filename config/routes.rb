# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, path: "", path_names: {
    sign_in: "entrar",
    sign_out: "sair",
    sign_up: "cadastrar"
  }, controllers: { registrations: "users/registrations" }

  root "dashboard#index"

  # Pré-cadastro público de ministro (precisa de aprovação do admin)
  get "cadastro-ministro", to: "pre_cadastros#new", as: :novo_pre_cadastro
  post "cadastro-ministro", to: "pre_cadastros#create", as: :pre_cadastros
  get "cadastro-ministro/enviado", to: "pre_cadastros#enviado", as: :pre_cadastro_enviado

  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :ministros
    resources :solicitacao_cadastros, path: "solicitacoes-cadastro", only: [:index, :show] do
      member do
        post :aprovar
        post :rejeitar
      end
    end
    resources :sacerdotes
    resources :tipo_servicos, path: "tipo-servicos"
    resources :calendario_base, path: "calendario-base"
    resources :competencia_mensal, path: "competencia-mensal" do
      member do
        post :gerar_escala
        post :regenerar_escala
      end
      resources :plantao_periodos, path: "plantao", except: [:show] do
        collection { post :copiar_anterior }
      end
    end
    resources :evento_escala, path: "eventos-escala", only: [:show, :new, :create, :edit, :update, :destroy] do
      member do
        get :escalar_ministros
        patch :update_escalar_ministros
      end
    end
    resources :eventos_extra, path: "eventos-extra"
    resources :liturgia_dias, path: "liturgia", only: [:index, :show, :edit, :update] do
      collection { post :buscar }
      member do
        post :validar
        post :reabrir
        post :sincronizar
        delete :remover_imagem
      end
    end
    resources :registros_esportula, path: "esportulas"
    get "relatorios", to: "relatorios#index"
  end

  # path e helpers permanecem /sacerdote e sacerdote_*; módulo PainelSacerdote evita colisão Zeitwerk com o model Sacerdote
  scope path: "sacerdote", module: "painel_sacerdote", as: "sacerdote" do
    root "dashboard#index"
  end

  # Agendadores da escala extra: acesso restrito ao CRUD de eventos extra
  namespace :escala_extra, path: "escala-extra" do
    root "eventos_extra#index"
    resources :eventos_extra, path: "eventos-extra" do
      member { get :drawer }
    end
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
    get "escala-do-mes", to: "escala_mensal#show", as: :escala_mensal
    get "escala-do-mes/imprimir", to: "escala_mensal#imprimir", as: :escala_mensal_imprimir
    get "liturgia", to: "liturgia#index", as: :liturgia_index
    get "liturgia/:data", to: "liturgia#show", as: :liturgia, constraints: { data: /\d{4}-\d{2}-\d{2}/ }
    resources :solicitacao_trocas, path: "trocas", only: [:create, :destroy] do
      member do
        patch :aceitar
        patch :recusar
      end
    end
    resources :oferta_apoios, path: "apoios", only: [:create, :destroy]
    resources :servicos, only: [:show] do
      member do
        patch :confirmar
      end
    end
  end
end
