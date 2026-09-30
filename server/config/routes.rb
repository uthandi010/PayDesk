Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    post "auth/register", to: "auth#register"
    post "auth/login", to: "auth#login"

    resources :customers, only: [ :index, :show, :create, :update, :destroy ]
    resources :plans, only: [ :index, :show, :create, :update, :destroy ]

    resources :subscriptions, only: [ :index, :show, :create ] do
      member do
        patch :cancel
        post :renew
      end
    end

    resources :invoices, only: [ :index, :show ] do
      member do
        post :retry
        get :pdf
      end
    end

    get "dashboard/summary", to: "dashboard#summary"

    namespace :public do
      get "invoices/:token", to: "invoices#show", as: :invoice
      post "invoices/:token/pay", to: "invoices#pay"
    end
  end
end
