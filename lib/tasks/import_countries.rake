namespace :import do
  
  task :countries => :environment do
    imported_countries = ImportedCountry.all
    
    imported_countries.each do |import_country|
      country = Country.find(:first, :conditions => { :name => import_country.name })
      country = Country.new() unless (country)
      country.name = import_country.name
      country.population = import_country.population
      country.density_per_sq_km = import_country.density_per_sq_km
      country.source_update_date = import_country.source_update_date
      puts "Saved #{country.name}, population #{country.population.thousands}" if country.save
    end
  end
  
end
  