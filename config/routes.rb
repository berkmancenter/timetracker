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
      post :sudo
      post :clear_user
      patch :edit
    end
    member do
      get :entry_form
      get :clone
      get :delete
    end
  end
end
