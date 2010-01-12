require 'import_places.rb'
load "#{RAILS_ROOT}/config/environment.rb"

namespace :import do
  
  countries = Country.with_country_code.collect { |country| country.country_code }
  country_symbols = countries.collect { |country_code| ("#{country_code}").intern }

  countries.each do |country_code|
    task "#{country_code}" => :environment do
      SLogger.info "Importing Places within country #{country_code.capitalize}..." do
        eval("ImportPlaces#{country_code.capitalize}").new.import
      end
    end
  end
  
  task :all => country_symbols
end
