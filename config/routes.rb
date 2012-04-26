Kermits2::Application.routes.draw do
  root :to => "root#index"

  resources :genes, :only => [:index]

  resources :mi_plans do
    collection do
      get 'gene_selection'
      delete 'destroy'
    end
  end

  resources :mi_attempts, :only => [:index, :new, :create, :show, :update] do
    resource :phenotype_attempts, :only => [:new]
    member do
      get 'history'
    end
  end

  resources :phenotype_attempts, :only => [:index, :create, :show, :update]
  
  resources :contacts do
    collection do
      get 'check_email'
      get 'search_email'
    end
  end
  
  resources :notifications, :only => [:create, :show] 
  
  match 'notifications' => 'notifications#delete', :via => :delete

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
  match 'debug_info' => 'root#debug_info'

  match 'reports' => "reports#index", :as => :reports

  match 'reports/mi_production' => "reports/mi_production#index"
  match 'reports/mi_production/(:action(.:format))' => "reports/mi_production#:action"

  match 'reports/production/mgp' => "reports/production/mgp#index"
  match 'reports/production/mgp/(:action(.:format))' => "reports/production/mgp#:action"

  match 'reports/(:action(.:format))' => "reports#:action"

  resources :report_caches, :only => [:show]

end
