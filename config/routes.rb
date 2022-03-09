Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions',
                            registrations: 'users/registrations' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  resources :users
  resources :home, only: %i[index create]
  resources :session, only: [:index]
  resources :documents, only: %i[index create update destroy]
  root 'home#index'
end
