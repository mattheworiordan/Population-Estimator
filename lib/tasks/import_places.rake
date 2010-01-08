require 'import_places.rb'

namespace :import do
  
  task :places => :environment do
    start = SLogger.info ("Starting to Geo-code")
    ImportPlacesGb.new.import
    SLogger.info ("Completed GB Places Import", start)
    
    start = SLogger.info ("Starting Ireland Places Import")
    ImportPlacesIe.new.import
    SLogger.info ("Completed Ireland Places Import", start)
  end
  
end
