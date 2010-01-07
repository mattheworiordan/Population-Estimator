namespace :import do
  
  task :places => :environment do
    # start = SLogger.info ("Starting GB Places Import")
    # uk = ImportPlacesGb.new
    # uk.import
    # SLogger.info ("Completed GB Places Import", start)
    
    start = SLogger.info ("Starting Ireland Places Import")
    uk = ImportPlacesIe.new
    uk.import
    SLogger.info ("Completed Ireland Places Import", start)
  end
  
end
