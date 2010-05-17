config = OpenStruct.new(YAML.load_file("#{Rails.root}/config/app.yml"))
::AppConfig = OpenStruct.new(config.send(Rails.env))

# Ensure the map accuracy is a power of 2
raise "Map accuracy in pixels is invalid, must be 1, 2, 4 or 8" if ![1,2,4,8].include?(AppConfig.gmap_accuracy)