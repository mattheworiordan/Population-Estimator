ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'places' do |place|
    place.search '/countries/:country_id/places/search', :action => 'search'
  end
  map.resources :countries, :has_many => [ :places ], :collection => { :search => :get }
  
  map.with_options :controller => 'land_mass_tile' do |tile|
    tile.view '/tiles/landmass/:x/:y/:zoom.png', :action => 'view'
  end
  
  map.namespace :admin do |admin|
    admin.resources :earth_masses_painter
  end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "countries"

  # See how all your routes  lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
