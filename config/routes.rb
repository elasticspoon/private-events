Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  devise_scope :user do
    post 'users/sign_up' => 'users/registrations#create'
    get 'users/edit/update_password' => 'users/registrations#update_password'
    get 'users/edit/close_account' => 'users/registrations#close_account'
    put 'users/edit/close_account' => 'users/registrations#close_account_action'
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  get 'not_implemented', to: 'application#not_implemented'
  post 'not_implemented', to: 'application#not_implemented'

  resources :users, only: :show
  resources :events
  resources :user_event_permissions, only: :create
  delete 'user_event_permissions', to: 'user_event_permissions#destroy'

  root 'events#index'
end
