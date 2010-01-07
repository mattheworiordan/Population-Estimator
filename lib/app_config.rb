config = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/app.yml"))
::AppConfig = OpenStruct.new(config.send(RAILS_ENV))