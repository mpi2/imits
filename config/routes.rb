TarMits::Application.routes.draw do
  root :to => "root#index"

  get 'admin' => 'Admin::Base#index', :as => :admin

  namespace :admin do
    resources :users do
      collection do
        match 'transform'
      end

      member do
        get 'history'
      end
    end

    resources :notifications do
      member do
        put 'retry'
        get 'history'
      end
    end

    resources :contacts

    resources :email_templates do
      collection do
        post 'preview'
      end

      member do
        get 'history'
      end
    end
  end

  resources :production_goals, :tracking_goals
  resources :centres

  resources :genes, :only => [:index] do
    member do
      get 'network_graph'
      get 'relationship_tree'
    end
  end

  resources :mi_plans do
    collection do
      get 'search_for_available_mi_attempt_plans'
      get 'search_for_available_phenotyping_plans'
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
  match 'notifications' => 'notifications#destroy', :via => :delete

  devise_for :users,
          :controllers => { :sessions => "sessions" },
          :path_names => { :sign_in => 'login', :sign_out => 'logout' } do
    get 'users' => 'users#index', :as => :users
    get 'user', :to => 'users#show', :as => :user
    put 'user', :to => 'users#update'
    match 'password_reset' => 'users#password_reset', :as => :password_reset
  end

  resources :sub_projects, :only => [:index, :create, :destroy]

  match 'quality_overviews' => "quality_overviews#index"
  match 'quality_overview_groupings' => "quality_overview_groupings#index"
  match 'quality_overviews/export_to_csv' => "quality_overviews#export_to_csv"
  match 'users_by_production_centre' => "root#users_by_production_centre", :as => :users_by_production_centre
  match 'consortia' => "root#consortia", :as => :consortia
  match 'debug_info' => 'root#debug_info'

  match 'reports' => "reports#index", :as => :reports

  match 'reports/notifications_by_gene' => 'reports#notifications_by_gene'

  match 'reports/mi_production' => "reports/mi_production#index"
  match 'reports/mi_production/(:action(.:format))' => "reports/mi_production#:action"

  match 'v2/reports' => 'reports#index'
  match 'v2/reports/(:action(.:format))'               => "v2/reports#:action"
  match 'v2/reports/mi_production'                     => "v2/reports/mi_production#index"
  match 'v2/reports/mi_production/(:action(.:format))' => "v2/reports/mi_production#:action"

  match 'v2/reports/mi_production/production_detail(.:format)' => "v2/reports/mi_production#production_detail", as: 'production_detail'
  match 'v2/reports/mi_production/gene_production_detail(.:format)' => "v2/reports/mi_production#gene_production_detail", as: 'gene_production_detail'
  match 'v2/reports/mi_production/consortia_production_detail(.:format)' => "v2/reports/mi_production#consortia_production_detail", as: 'consortia_production_detail'

  match 'v2/reports/mi_production/sliding_efficiency(.:format)' => "v2/reports/mi_production#sliding_efficiency", as: 'sliding_efficiency'
  match 'v2/reports/mi_production/genes_gt_mi_attempt_summary(.:format)' => "v2/reports/mi_production#genes_gt_mi_attempt_summary", as: 'genes_gt_mi_attempt_summary'
  match 'v2/reports/mi_production/all_mi_attempt_summary(.:format)' => "v2/reports/mi_production#all_mi_attempt_summary", as: 'all_mi_attempt_summary'
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

  get '/javascripts/dynamic_esc_qc_conflict_selects' => 'javascripts#dynamic_esc_qc_conflict_selects'

  get '/public_dump' => 'root#public_dump', :as => 'public_dump'

  ## TargRep interface
  namespace :targ_rep do
    resources :pipelines

    resources :gene_traps
    resources :targeted_alleles

    resources :alleles do
      get :history, :on => :member

      collection do
        get :attributes
      end
    end

    resources :genbank_files
    resources :targeting_vectors

    resources :es_cells do
      collection do
        get :mart_search
        get :attributes
        match :bulk_edit, :via => [:get, :post]
        match :update_multiple, :via => [:get, :put]
      end
    end

    resources :distribution_qcs

    get '/alleles/:id/escell-clone-genbank-file' => 'alleles#escell_clone_genbank_file', :as => 'escell_clone_genbank_file'
    get '/alleles/:id/targeting-vector-genbank-file' => 'alleles#targeting_vector_genbank_file', :as => 'targeting_vector_genbank_file'
    get '/alleles/:id/escell-clone-cre-genbank-file' => 'alleles#escell_clone_cre_genbank_file', :as => 'escell_clone_cre_genbank_file'
    get '/alleles/:id/targeting-vector-cre-genbank-file' => 'alleles#targeting_vector_cre_genbank_file', :as => 'targeting_vector_cre_genbank_file'
    get '/alleles/:id/escell-clone-flp-genbank-file' => 'alleles#escell_clone_flp_genbank_file', :as => 'escell_clone_flp_genbank_file'
    get '/alleles/:id/targeting-vector-flp-genbank-file' => 'allele#targeting_vector_flp_genbank_file', :as => 'targeting_vector_flp_genbank_file'
    get '/alleles/:id/escell-clone-flp-cre-genbank-file' => 'alleles#escell_clone_flp_cre_genbank_file', :as => 'escell_clone_flp_cre_genbank_file'
    get '/alleles/:id/targeting-vector-flp-cre-genbank-file' => 'alleles#targeting_vector_flp_cre_genbank_file', :as => 'targeting_vector_flp_cre_genbank_file'
    get '/alleles/:id/allele-image' => 'alleles#allele_image', :as => 'allele_image'
    get '/alleles/:id/allele-image-cre' => 'alleles#allele_image_cre', :as => 'allele_image_cre'
    get '/alleles/:id/allele-image-flp' => 'alleles#allele_image_flp', :as => 'allele_image_flp'
    get '/alleles/:id/allele-image-flp-cre' => 'alleles#allele_image_flp_cre', :as => 'allele_image_flp_cre'
    get '/alleles/:id/cassette-image' => 'alleles#cassette_image', :as => 'cassette_image'
    get '/alleles/:id/vector-image' => 'alleles#vector_image', :as => 'vector_image'
    get '/alleles/:id/vector-image-cre' => 'alleles#vector_image_cre', :as => 'vector_image_cre'
    get '/alleles/:id/vector-image-flp' => 'alleles#vector_image_flp', :as => 'vector_image_flp'
    get '/alleles/:id/vector-image-flp-cre' => 'alleles#vector_image_flp_cre', :as => 'vector_image_flp_cre'

    #connect ':controller/:action/:id.:format'
    #connect ':controller/:action.:format'

    root :to => "welcome#index"
  end

  match 'targ_rep/:controller(/:action(/:id)(.:format))'

end
