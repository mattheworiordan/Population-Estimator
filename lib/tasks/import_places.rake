require 'import_places.rb'
load "#{RAILS_ROOT}/config/environment.rb"

namespace :import do
  
  countries = Country.with_country_code.collect { |country| country.country_code }

  countries.each do |country_code|
    task "place_#{country_code}" => :environment do
      start = SLogger.info ("Importing Places within country #{country_code.capitalize}")
      eval("ImportPlaces#{country_code.capitalize}").new.import
      SLogger.info ("Completed import of #{country_code.capitalize}", start)
    end
  end
  
  task :places => :initialise_countries do
    tasks.each { |task| task.start if task.name.starts_with?("place_") }
  end
  
end
