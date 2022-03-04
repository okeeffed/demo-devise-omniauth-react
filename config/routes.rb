Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  resources :users
  resources :home, only: %i[index create]
  resources :session, only: [:index]
  root 'home#index'
end
