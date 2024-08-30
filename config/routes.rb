Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  root to: 'front#index'

  get :ping, to: 'application#ping'

  resources :time_entries do
    collection do
      get :entries
      get :popular
      get :days
      get :months
      get :auto_complete
      get :totals
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
      get :cas_logout
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
      get :where_admin, action: :index_where_admin
      get :index_admin
    end
    member do
      post :send_invitations
      get :leave
      get :users
      post :delete_users
      post :change_users_role
    end
  end

  match '*unmatched', to: 'front#index', via: %i[get]
end
