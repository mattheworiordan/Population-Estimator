PopulationEstimator::Application.routes.draw do
  match '/countries/:country_id/places/search' => 'places#search', :as => :search
  resources :countries do
    collection do
      get :search
    end
    resources :places
  end

  match '/tiles/landmass/:x/:y/:zoom.png' => 'land_mass_tile#view', :as => :view
  namespace :admin do
    resources :earth_masses_painter
  end

  root :to => 'countries#index'
end
