Rails.application.routes.draw do
  devise_for :users
  root to: 'front#index'

  get :ping, to: 'application#ping'

  resources :time_entries do
    collection do
      get :entries
      get :popular
      get :days
      get :months
      get :auto_complete
      post :edit
      patch :edit
    end
    member do
      get :delete
    end
  end

  resources :users do
    collection do
      get :current_user_data
      post :sudo
      post :unsudo
      post :toggle_admin
    end
  end

  resources :periods do
    member do
      get :credits
      get :stats
      post :stats
      post :set_credits
      post :clone
    end
    collection do
      post :upsert
      post :delete
    end
  end

  resources :timesheets do
    collection do
      post :upsert
      post :delete
      get 'join/:code', action: :join
    end
    member do
      post :send_invitations
      get :leave
      get :users
      post :delete_users
    end
  end

  match '*unmatched', to: 'front#index', via: %i[get]
end
