Kermits2::Application.routes.draw do
  root :to => "root#index"

  resources :genes, :only => [:index]

  resources :mi_plans, :only => [:show, :create, :update, :destroy] do
    collection do
      get 'gene_selection'
      delete 'destroy'
    end
  end

  resources :mi_attempts, :only => [:index, :new, :create, :show, :update] do
    member do
      get 'history'
    end
  end

  devise_for :users,
          :path_names => { :sign_in => 'login', :sign_out => 'logout' } do
    get 'user', :to => 'users#show', :as => :user
    put 'user', :to => 'users#update'
  end

  get 'user/admin', :to => 'user/admin#index', :as => :user_admin
  post 'user/admin/transform', :to => 'user/admin#transform', :as => :transform_admin
  post 'user/admin/create_user', :to => 'user/admin#create_user', :as => :admin_create_user

  resources :es_cells, :only => [] do
    collection do
      get 'mart_search'
    end
  end

  match 'users_by_production_centre' => "root#users_by_production_centre", :as => :users_by_production_centre
  match 'consortia' => "root#consortia", :as => :consortia

  match 'reports' => "reports#index", :as => :reports
  match 'reports/(:action(.:format))' => "reports#:action"

  resources :report_caches, :only => [:show]
end
