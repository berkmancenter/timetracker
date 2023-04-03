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
      get :view_other_timesheets
      get :current_user
      post :sudo
      post :destroy_multi
      post :toggle_admin_multi
    end
  end

  resources :periods do
    member do
      get :credits
      get :stats
      patch :set_credits
      patch :set_credits_multi
    end
  end
end
