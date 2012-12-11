Kermits2::Application.routes.draw do
  root :to => "root#index"

  resources :genes, :only => [:index]

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
          :controllers => { :sessions => "sessions" },
          :path_names => { :sign_in => 'login', :sign_out => 'logout' } do
    get 'user', :to => 'users#show', :as => :user
    put 'user', :to => 'users#update'
  end

  get 'user/admin', :to => 'user/admin#index', :as => :user_admin
  post 'user/admin/transform', :to => 'user/admin#transform', :as => :transform_admin
  post 'user/admin/create_user', :to => 'user/admin#create_user', :as => :admin_create_user

  resources :sub_projects, :only => [:index, :create, :destroy]

  match 'gene/:id/network_graph' => "genes#network_graph"
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

  match '/es_cells/mart_search' => 'TargRep::EsCells#mart_search', :as => 'mart_search'

  ## TargRep interface
  namespace :targ_rep do
    resources :pipelines
    
    resources :alleles do
      get :history, :on => :member
    end

    resources :genbank_files
    resources :targeting_vectors
    
    resources :es_cells do
      match  :bulk_edit, :on => :collection, :via => [:get, :post]
      put    :update_multiple, :on => :collection
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
