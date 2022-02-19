Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  resources :users, only: :show
  resources :events
  resources :attended_events, only: %i[create destroy]
  # delete 'attended_events', to: 'attended_events#destroy'

  root 'events#index'
end
