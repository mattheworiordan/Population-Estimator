require './lib/build_land_mass_images'
load "#{Rails.root}/config/environment.rb"

##
# Allows import of any country with country code i.e. rake import:gb
namespace :build do
  task :land_mass_images do
    SLogger.info "Building land mass images linearly ..." do
      BuildLandMassImages.new.start
    end
  end
  
  # reduce task takes the land mass images at maximum zoom and stitches them together to create lower zoom level images
  task :reduce_land_mass_images => :environment do
    SLogger.info "Reducing Land Mass images linearly from highest zoom level" do
      ReduceLandMassImages.new.start # :limit_to => 5000, :overwrite_all => true
    end
  end
  
  task :land_mass_images_and_reduce => [:land_mass_images, :reduce_land_mass_images] 
end
