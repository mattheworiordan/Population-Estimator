config = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/import.yml"))
::ImportConfig = OpenStruct.new(config.send(RAILS_ENV))