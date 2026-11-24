Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'registrations' }
  root to: 'front#index'

  get :ping, to: 'front#ping'

  resources :time_entries, only: [] do
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
      delete :delete
    end
  end

  resources :users, only: %i[index] do
    collection do
      get :current_user_data
      post :sudo
      post :unsudo
      delete :cas_logout
    end
  end

  resources :timesheets, only: %i[index show] do
    collection do
      post :upsert
      post :delete
      post 'join/:code', action: :join
      get :index_admin
    end
    member do
      post :send_invitations
      delete :leave
      get :users
      get 'users/:user_id', to: 'timesheets#user'
      post :delete_users
      post :change_users_role
    end

    resources :periods, only: %i[index show] do
      member do
        get :credits
        get :stats
        post :set_credits
        post :clone
      end
      collection do
        post :upsert
        post :delete
      end
    end
  end

  # Pages of the front-end. Its files are left out: a missing one (an old tab
  # asks for a file of the build before a deploy) gets 404, not the page.
  match '*unmatched', to: 'front#index', via: %i[get],
                      constraints: ->(request) { !request.path_info.start_with?('/front_assets/') }
end
