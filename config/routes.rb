Kermits2::Application.routes.draw do
  root :to => "root#index"

  resources :centres

  resources :genes, :only => [:index] do
    member do
      get 'network_graph'
      get 'relationship_tree'
    end
  end

  resources :mi_plans do
    collection do
      get 'gene_selection'
      delete 'destroy'
      get 'attributes'
    end
  end

  resources :mi_attempts, :only => [:index, :new, :create, :show, :update] do
    resource :phenotype_attempts, :only => [:new]
    collection do
      get 'attributes'
    end
  end

  resources :phenotype_attempts, :only => [:index, :create, :show, :update] do
    collection do
      get 'attributes'
    end
  end

  resources :contacts do
    collection do
      get 'check_email'
      get 'search_email'
    end
  end

  resources :notifications, :only => [:create]

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

  resources :sub_projects, :only => [:index, :create, :destroy]

  match 'quality_overviews' => "quality_overviews#index"
  match 'quality_overview_groupings' => "quality_overview_groupings#index"
  match 'quality_overviews/export_to_csv' => "quality_overviews#export_to_csv"
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

  match ':controller/:id/history' => ':controller#history'

  namespace :solr_update do
    namespace :queue do
      resources :items, :only => [:index, :destroy] do
        post :run, :on => :member
      end
    end
  end

end
