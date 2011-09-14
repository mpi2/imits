Kermits2::Application.routes.draw do
  root :to => "root#index"

  resources :genes, :only => [:index]

  resources :mi_plans, :only => [:create] do
    collection do
      get 'gene_selection'
    end
  end

  resources :mi_attempts, :only => [:index, :new, :create, :show, :update] do
    member do
      get 'history'
    end
  end

  devise_for :users,
          :path_names => { :sign_in => 'login', :sign_out => 'logout' } do
    get 'users/edit', :to => 'devise/registrations#edit', :as => :edit_user_registration
    put '/users', :to => 'devise/registrations#update', :as => :user_registration
  end

  resources :es_cells, :only => [] do
    collection do
      get 'mart_search'
    end
  end

  match 'reports' => "reports#index", :as => :reports
  match 'reports/(:action(.:format))' => "reports#:action"
end
