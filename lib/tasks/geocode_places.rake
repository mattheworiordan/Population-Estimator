namespace :geocode do
  
  task :places => :environment do
    start = SLogger.info ("Starting to Geocode places")
    GeocodePlaces.new.start :limit_to => 5000 # :overwrite_all => true, 
    SLogger.info ("Completed Geocoding places", start)
  end
  
end
