namespace :import do
  
  task :gmap_tiles => :environment do
    SLogger.info "Importing Google Map tiles (API 3)..." do
      ImportGmapTiles.new.start :limit_to => 5000 # :overwrite_all => true, 
    end
  end
  
end
