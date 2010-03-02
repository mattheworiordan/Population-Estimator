namespace :build do
  
  task :reduce_land_mass_images => :environment do
    SLogger.info "Reducing Land Mass images from highest zoom level" do
      ReduceLandMassImages.new.start # :limit_to => 5000, :overwrite_all => true
    end
  end
  
end
