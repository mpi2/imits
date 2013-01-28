Kermits2::Application.routes.draw do
  root :to => "root#index"

  get 'admin' => 'Admin::Base#index', :as => :admin

  namespace :admin do
    resources :users do
      collection do
        match 'transform'
      end
    end

    resources :notifications do
      member do
        put 'retry'
      end
    end
  end

  resources :production_goals
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

  namespace :mi_attempts do
    resources :distribution_centres do
      collection do
        get 'grid_redirect'
      end
    end

  end

  resources :mi_attempts, :only => [:index, :new, :create, :show, :update] do
    resource :phenotype_attempts, :only => [:new]
    collection do
      get 'attributes'
    end
  end

  namespace :phenotype_attempts do
    resources :distribution_centres do
      collection do
        get 'grid_redirect'
      end
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
    get 'users' => 'users#index', :as => :users
    get 'user', :to => 'users#show', :as => :user
    put 'user', :to => 'users#update'
    match 'password_reset' => 'users#password_reset', :as => :password_reset
  end

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
