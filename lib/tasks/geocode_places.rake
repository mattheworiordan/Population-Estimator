namespace :geocode do
  
  task :all => :environment do
    SLogger.info "Geocoding places..." do
      GeocodePlaces.new.start :limit_to => 5000 # :overwrite_all => true, 
    end
  end
  
end
