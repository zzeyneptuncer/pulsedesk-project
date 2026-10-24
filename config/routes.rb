Rails.application.routes.draw do
  root "tickets#index"
  resources :tickets, only: [:index, :show, :new, :create] do
    collection do
      post :simulate_agent_incident
    end
    member do
      patch :transition
      patch :assign
      post :reply
      post :simulate
      post :approve_hitl
      post :reject_hitl
    end
  end

  namespace :api do
    namespace :v1 do
      namespace :agent do
        resources :tickets, only: [:create]
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
