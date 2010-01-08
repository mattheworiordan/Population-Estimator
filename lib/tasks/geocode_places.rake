namespace :geocode do
  
  task :places => :environment do
    start = SLogger.info ("Starting to Geocode places")
    GeocodePlaces.new.start
    SLogger.info ("Completed Geocoding places", start)
  end
  
end
