# frozen_string_literal: true

Rails.application.routes.draw do
  constraints ControlHostConstraint do
    root 'custom_domains#index', as: :control_root
    resource :session, only: %i[new create destroy]
    resources :custom_domains, only: %i[create destroy] do
      post :refresh, on: :member
    end
  end

  constraints ->(request) { !ControlHostConstraint.matches?(request) } do
    root 'public_pages#show', as: :public_pages_root
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
