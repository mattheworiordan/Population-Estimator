module ImportPlacesModule
  
  ##
  # Import States or Countries (in the case of GB) from ImportPlace model into the Place model and save
  # 
  # Params are Hash symbols
  #  :with_country_code => 'gb' (defaults to @country_code instance variables)
  #  :use_css_selectors_for => { 'name' => ':first' } (optional)
  #  :except_those_with_name => [ 'great britain', 'ireland' ] (optional)
  def import_states(args)
    country, country_code, ignore_names, manual_column_css_selectors = validate_and_get_common_params args
    
    # naming for config is gb_states
    config_params = OpenStruct.new(config_params = eval("ImportConfig.#{country_code}_states"))
    
    # Import places from ImportedPlace model which loads data from external source
    states = ImportedPlace.get_places(config_params.url, config_params.data_source, manual_column_css_selectors, ignore_names)
    
    # Store the imported places into the persistent places model
    Place.add_update_places_from_imported_places(states, country, PlaceType::State)
    
    # Now query the database so that the latest list of states can be returned in case they are needed
    states_in_db = Place.in_country_code(country_code).states.all
    
    SLogger.info "Imported #{states.count} states (or countries in kingdoms) into '#{country.name}', total #{states_in_db.count} states in database for '#{country.name}'"
    
    states_in_db
  end  
  
  ##
  # Import Counties from ImportPlace model into the Place model and save
  # 
  # Params are Hash symbols
  #  :with_country_code => 'gb' (defaults to @country_code instance variables)
  #  :with_config_option => 'major' (optional, adds this to the import.yml key to allow optional extra data to be imported)
  #  :use_css_selectors_for => { 'name' => ':first' } (optional)
  #  :except_those_with_name => [ 'great britain', 'ireland' ] (optional)
  #  :in_state => 'england' (optional)
  #  :match_parent => (optional) allows the parent object to be set, else the new county will be orphaned unless a match by in_state name is found if used
  #  :force_url_and_data_source => { "url" => "UK-England.html", "data_source" => "cities" } (optional, allows the naming convention to be ignored and a Hash parameter to be passed in)
  def import_counties(args)
    country, country_code, ignore_names, manual_column_css_selectors = validate_and_get_common_params args

    with_config_option = args[:with_config_option]      
    in_state = args[:in_state]
    match_parent = args[:match_parent]
    force_url_and_data_source = args[:force_url_and_data_source]
    raise ArgumentError, "Parent parameter is not a Place object" if (!match_parent.blank? && !match_parent.instance_of?(Place))
    
    state = case
      when !match_parent.blank? then match_parent
      when !in_state.blank? then Place.in_country_code(country_code).states.find_by_name(in_state)
      else nil
    end
    raise IndexError, "The state '#{in_state}' could not be found in the database" if ( state.blank? && !in_state.blank? ) 
    raise IndexError, "The parent '#{state}' is not a state or county and must be for a county" if ( !state.blank? && ![PlaceType::State,PlaceType::County].include?(state.place_type)) 
    
    if force_url_and_data_source.blank?
      # naming for counties config is gb_england_counties (using in_state) OR ie_counties if Ireland has no states and only counties
      in_state_config_suffix = in_state.blank? ? '' : '_' + in_state
      counties_suffix = with_config_option.blank? ? '' : "_#{with_config_option}"
      config_path = "#{country_code}#{in_state_config_suffix}_counties#{counties_suffix}"
      config_params = OpenStruct.new(eval("ImportConfig.#{config_path}"))
      raise ArgumentError, "Config path #{config_path} appears to be invalid as URL and or Data_source is missing" if (config_params.blank? || config_params.url.blank? || config_params.data_source.blank?)
    else
      config_params = OpenStruct.new(force_url_and_data_source)
      raise ArgumentError, "Forced URL and Data Source Hash #{force_url_and_data_source.inspect} appears to be invalid as URL and or Data_source is missing" if (config_params.url.blank? || config_params.data_source.blank?)
    end
    
    # Import places from ImportedPlace model which loads data from external source
    counties = ImportedPlace.get_places(config_params.url, config_params.data_source, manual_column_css_selectors, ignore_names)
    
    # Store the imported places into the persistent places model
    Place.add_update_places_from_imported_places(counties, country, PlaceType::County, state)
    
    # Now query the database so that the latest list of counties can be returned in case they are needed
    counties_in_db = Place.in_country_code(country_code).counties.all.select { |county| state ? county.parent == state : true }
    
    SLogger.info "Imported #{counties.count} counties into '#{country.name}#{(state.blank? ? '' : ', ' + state.name)}', total #{counties_in_db.count} counties in db now with a parent of '#{(state.blank? ? '' : ', ' + state.name)}'"
    
    counties_in_db
  end
  
  ##
  # Import Cities from ImportPlace model into the Place model and save
  # 
  # Params are Hash symbols
  #  :with_country_code => 'gb' (defaults to @country_code instance variables)
  #  :use_css_selectors_for => { 'name' => ':first' } (optional)
  #  :except_those_with_name => [ 'great britain', 'ireland' ] (optional)
  #  :in_state => 'england' (optional)
  #  :with_state_code (optional)
  #  :with_config_option => 'major' (optional, adds this to the import.yml key to allow optional extra data to be imported)
  #  :force_url_and_data_source => { "url" => "UK-England.html", "data_source" => "cities" } (optional, allows the naming convention to be ignored and a Hash parameter to be passed in)
  #  :match_parent => Allows a parent object to be passed in so that each new place is a child of this object.  
  def import_cities(args)
    
  end
  
  # Helper method to find a place based on the with_[name,abbreviation,id] parameter and executes a block passing in the matched places
  # Logs an error if no match
  def for_each_place_in(place_collection, nameHash, &block)
    raise ArgumentError, "with_* Hash is missing" if !nameHash.instance_of?(Hash)
    key = nameHash.keys.find { |key| key.to_s.match(/^with_[\w\d]+/i) }
    raise ArgumentError, "with_* parameter is missing" if key.blank?
    
    match_on = key.to_s.sub(/^with_/i, "")
    match_on_value = nameHash[key].downcase
    
    matched_cities = place_collection.select { |place| eval("place.#{match_on}").downcase == match_on_value }.each { |place| yield place }
    SLogger.error("No place was found for search on #{match_on} for value #{match_on_value}, therefore nothing has been imported") if matched_cities.count == 0

    matched_cities
  end
  
private 

  ##
  # Import Places is a private method called by import_cities and import_counties
  # This method retrieves ImportPlace models and transforms them into persistent Place models
  # 
  # Params are Hash symbols
  #  :place_type => PlaceType::City || PlaceType::County (required to define behaviour of this method)
  #  :with_country_code => 'gb' (defaults to @country_code instance variables)
  #  :use_css_selectors_for => { 'name' => ':first' } (optional)
  #  :except_those_with_name => [ 'great britain', 'ireland' ] (optional)
  #  :in_state => 'england' (optional)
  #  :with_state_code (optional)
  #  :with_config_option => 'major' (optional, adds this to the import.yml key to allow optional extra data to be imported)
  #  :force_url_and_data_source => { "url" => "UK-England.html", "data_source" => "cities" } (optional, allows the naming convention to be ignored and a Hash parameter to be passed in)
  #  :match_parent => Allows a parent object to be passed in so that each new place is a child of this object.
  def import_places(args)
    place_type = args[:place_type]
    raise ArgumentError, "The place type is not supported" if ![PlaceType::City,PlaceType::County].include?(place_type)
    
    # get default variables and check common parameters
    country, country_code, ignore_names, manual_column_css_selectors = validate_and_get_common_params(args)
      
    in_state = args[:in_state]
    with_config_option = args[:with_config_option]
    match_parents_on_abbreviation = args[:match_parents_on_abbreviation]
    match_parents_on_name = args[:match_parents_on_name]
    match_parent = args[:match_parent]
    force_url_and_data_source = args[:force_url_and_data_source]
    
    state = Place.in_country_code(country_code).states.find_by_name(in_state) unless in_state.blank?
    raise IndexError, "The state '#{in_state}' could not be found in the database" if (in_state.blank? && state.blank?) 
    
    raise ArgumentError, "Parent parameter is not a Place object" if (!match_parent.blank? && !match_parent.instance_of?(Place))
    raise ArgumentError, "Match Parents on Name parameter is not an Array of Places" if (!match_parents_on_name.blank? && !match_parents_on_name.instance_of?(Array))
    raise ArgumentError, "Match Parents on Abbreviation parameter is not an Array of Places" if (!match_parents_on_abbreviation.blank? && !match_parents_on_abbreviation.instance_of?(Array))
    
    raise ArgumentError, "Forced URL & Data Source needs to be a Hash" if (!force_url_and_data_source.blank? && !force_url_and_data_source.instance_of?(Hash))
    raise ArgumentError, "A config option suffix and forced URL & Data source cannot be passed in at the same time as one must take precedence over the other" if (!force_url_and_data_source.blank? && !with_config_option.blank?)
    
    if force_url_and_data_source.blank?
      # use naming convention for counties config => gb_england_counties (using in_state param) OR ie_counties if country has no states 
      in_state_config_suffix = in_state.blank? ? '' : "_#{in_state}"
      cities_suffix = with_config_option.blank? ? '' : "_#{with_config_option}"
      config_path = "#{country_code}#{in_state_config_suffix}_cities#{cities_suffix}"
      config_params = OpenStruct.new(eval("ImportConfig.#{config_path}"))
      raise ArgumentError, "Config path #{config_path} appears to be invalid as URL and or Data_source is missing" if (config_params.blank? || config_params.url.blank? || config_params.data_source.blank?)
    else
      config_params = OpenStruct.new(force_url_and_data_source)
      raise ArgumentError, "Forced URL and Data Source Hash #{force_url_and_data_source.inspect} appears to be invalid as URL and or Data_source is missing" if (config_params.url.blank? || config_params.data_source.blank?)
    end
    
    # Import places from ImportedPlace model which loads data from external source
    cities = ImportedPlace.get_places(config_params.url, config_params.data_source, manual_column_css_selectors, ignore_names)
    
    # Store the imported places into the persistent places model
    parent = case
      when !match_parent.blank? then match_parent
      when !match_parents_on_name.blank? then match_parents_on_name.index_by(&:name)
      when !match_parents_on_abbreviation.blank? then match_parents_on_abbreviation.index_by(&:abbreviation)
      when !state.blank? then state
      else nil
    end
    # SLogger.info "Parent keys: #{parent.keys.join(',')}" if parent.instance_of?(Hash)
    
    Place.add_update_places_from_imported_places(cities, country, PlaceType::City, parent)
    
    # Now query the database so that the latest list of cities matched to parent(s) can be returned in case they are needed
    # and build up a list of used parents for debug output
    parent_names = {}
    scope = Place.in_country_code(country_code)
    scope = scope.descendants_of(state) unless state.blank?
    cities_in_db = scope.cities_and_boroughs.all.select do |city|
      match = case
        when parent.instance_of?(Place) then 
          city.parent == parent ? city.parent : nil
        when parent.instance_of?(Hash) then
          city_key = !match_parents_on_name.blank? ? city.parent.name : city.parent.abbreviation
          parent.keys.include?(city_key) ? city.parent : nil
      end
      parent_names[city.parent.id] = city.parent.name if (match) 
      match
    end
    
    SLogger.info "Imported #{cities.count} cities into '#{country.name} => (#{parent_names.values.sort.first(15).join(',') + (parent_names.values.count > 10 ? '... ' + (parent_names.values.count-15).to_s + ' more' : '')})', total #{cities_in_db.count} child cities in db now"

    cities_in_db
  end

  # checks the common parameters shared by all import methods
  def validate_and_get_common_params(args)
    raise ArgumentError, "Country code parameter is missing and instance country_code set" if args[:with_country_code].blank? && !instance_variables.include?('@country_code')
    raise ArgumentError, "Use CSS Selectors for parameter must containa Hash" unless (args[:use_css_selectors_for].blank? || !args[:use_css_selectors_for].instance_of?(Hash))
    
    country_code = args[:with_country_code] ? args[:with_country_code]: @country_code
    
    country = Country.find_by_country_code(country_code.upcase)
    raise IndexError, "Country code #{country_code} is not valid and a country cannot be found" if (country.blank?)
    
    ignore_names = args[:except_those_with_name]
    ignore_names = [ignore_names] if (!ignore_names.blank? && !ignore_names.instance_of?(Array))
    manual_column_css_selectors = args[:use_css_selectors_for] ? args[:use_css_selectors_for] : {}
    
    return country, country_code, ignore_names, manual_column_css_selectors
  end
  
end