namespace :import do

  task :gmap_tiles => :environment do
    SLogger.info "Importing Google Map tiles (API 3)..." do
      ImportGmapTiles.new.start # :overwrite_all => true,
    end
  end

end
