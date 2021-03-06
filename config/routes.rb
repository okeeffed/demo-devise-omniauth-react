Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions',
                            registrations: 'users/registrations' }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      resources :documents, only: %i[index create update destroy]
      resources :example, only: %i[index]
    end
  end

  # Defines the root path route ("/")
  resources :users
  resources :home, only: %i[index create]
  root 'home#index'
end
