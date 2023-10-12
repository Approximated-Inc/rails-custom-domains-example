# frozen_string_literal: true

Rails.application.routes.draw do
  constraints AppDomainConstraint do
    root 'pages#index', as: :pages_root
    resources :pages, except: %i[index]
  end

  constraints !AppDomainConstraint do
    root 'public_pages#show', as: :public_pages_root
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
