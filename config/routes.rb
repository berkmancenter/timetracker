Rails.application.routes.draw do
  root to: 'front#index'

  resources :time_entries do
    collection do
      get :entries
      get :popular
      get :days
      get :months
      get :auto_complete
      get :choose_user
      post :edit
      patch :edit
    end
    member do
      get :delete
    end
  end

  resources :users do
    collection do
      get :current_user
      post :sudo
      post :delete
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

  match '*unmatched', to: 'front#index', via: %i[get]
end
