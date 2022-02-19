Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  resources :users, only: :show
  resources :events
  resources :attended_events, only: :create
  delete 'events/:event_id/attended_events', to: 'attended_events#destroy', as: :attended_event

  root 'events#index'
end
