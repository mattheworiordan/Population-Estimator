require 'build_land_mass_images'
require 'build_land_mass_images_mapreduce'
load "#{RAILS_ROOT}/config/environment.rb"

##
# Allows import of any country with country code i.e. rake import:gb
namespace :build do
  
  task :land_mass_images_mapreduce => [:environment, :mapreduce_notice, :mapreduce] 
  
  task :land_mass_images_mapreduce_with_server => [:mapreduce_start, :mapreduce, :mapreduce_stop]
  
  task :mapreduce_start do 
    `skynet start`
  end

  task :mapreduce_stop do 
    `skynet stop`
  end

  task :mapreduce_notice do
    puts "Please note that you must start map reduce server (skynet) by runing rake:mapreduce_start"
  end
  
  task :mapreduce => :environment do
    SLogger.info "Building land mass images using map reduce ..." do
      results = BuildLandMassImagesMapreduce.run
      results = results.map { |val| "Col #{val[0]}:#{val[1]}" }.join(', ')
      SLogger.info("Results: #{results}")
    end
  end
  
end
