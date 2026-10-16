Rails.application.routes.draw do
  root "tickets#index"
  resources :tickets, only: [:index, :show, :new, :create] do
    member do
      patch :transition
      patch :assign
      post :reply
      post :simulate
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
