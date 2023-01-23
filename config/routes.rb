Rails.application.routes.draw do
  root to: 'time_entries#index'

  resources :time_entries, only: %i[index] do
    collection do
      get :popular_categories
      get :popular_projects
      get :days
      get :months
      get :auto_complete
      get :choose_user
      post :edit
      patch :edit
    end
    member do
      get :entry_form
      get :clone
      get :delete
    end
  end

  resources :users do
    collection do
      get :view_other_timesheets
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
