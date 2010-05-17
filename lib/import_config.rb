config = OpenStruct.new(YAML.load_file("#{Rails.root}/config/import.yml"))
::ImportConfig = OpenStruct.new(config.send(Rails.env))