Kermits2::Application.routes.draw do
  netzke

  root :to => "root#index"

  resources :mi_attempts, :only => [:index, :new, :create, :show, :update]

  devise_for :users,
          :path_names => { :sign_in => 'login', :sign_out => 'logout' } do
    get 'users/edit', :to => 'devise/registrations#edit', :as => :edit_user_registration
    put '/users', :to => 'devise/registrations#update', :as => :user_registration
  end

  resources :centres, :only => [:show, :index]
  resources :es_cells, :only => [:show, :index] do
    collection do
      get 'mart_search'
    end
  end

  match 'reports' => "reports#index", :as => :reports
  match 'reports/(:action(.:format))' => "reports#:action"
end
