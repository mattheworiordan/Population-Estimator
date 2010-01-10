module ImportPlacesModule
  
  ##
  # Import states or countries (in the case of GB) from ImportedPlace model into the Place model and persists
  # Supports all options in #import_places
  #
  def import_states(options)
    import_places PlaceType::State, options
  end  
  
  ##
  # Imports counties from ImportedPlace model into the Place model and persists to database
  # Supports all options in #import_places
  #
  def import_counties(options)
    import_places PlaceType::County, options
  end
  
  ##
  # Imports cities from ImportPlace model into the Place model and persists to database
  # 
  # Supports all options in #import_places
  #
  def import_cities(options)
    import_places PlaceType::City, options
  end
  
  # Helper method to find a place based on the with_[name,abbreviation,id] parameter and executes a block passing in the matched places
  # Logs an error if no match
  #
  def for_each_place_in(place_collection, name_hash, &block) 
    raise ArgumentError, "with_* Hash is missing" if !name_hash.instance_of?(Hash)
    key = name_hash.keys.find { |key| key.to_s.match(/^with_[\w\d]+/i) }
    raise ArgumentError, "with_* parameter is missing" if key.blank?
    
    match_on = key.to_s.sub(/^with_/i, "")
    match_on_value = name_hash[key].downcase
    
    matched_cities = place_collection.select { |place| eval("place.#{match_on}").downcase == match_on_value }.each { |place| yield place }
    SLogger.error("No place was found for search on #{match_on} for value #{match_on_value}, therefore nothing has been imported") if matched_cities.count == 0

    matched_cities
  end
  
  def for_each_css_on_url_match(configuration) # yield text, url, config
    config = OpenStruct.new(configuration)
    raise ArgumentError, "css_selector or url is missing from configuration" unless (!config.css_selector.blank? && !config.url.blank?)
    
    full_url = "#{ImportConfig.city_population_url}#{config.url}"
    page = nil
    begin
      page = Nokogiri::HTML.parse( open( full_url ) ) 
      # test that we can at least see the body tag which will raise an exception if missing
      page.css("body").first
    rescue Exception => e
      raise "Could not load or parse HTML for '#{full_url}', #{e.message}"
    end
    
    page.css("#{config.css_selector}").map do |elem| 
      yield elem.inner_text.strip, elem['href'], config
    end
  end
  
  ##
  # This method is a generic import method called by import_cities and import_counties, and not typically called directly 
  # This method retrieves ImportedPlace models and transforms them into persistent Place models
  # The param place_type must contain one of: PlaceType::City, PlaceType::County
  # 
  # The following options are supported:
  #
  # [:with_country_code]
  #   Defaults to @country_code instance variables if not used.  (e.g. 'gb')
  #   
  # [:use_css_selectors_for] 
  #   Allows a column's CSS selector to be hard coded for this import.  (e.g. { 'name' => ':first' })
  #
  # [:except_those_with_name]
  #   Filters rows with a name matching the text.  (e.g. [ 'great britain', 'ireland' ])
  #
  # [:except_those_with_parent_identifier]
  #   Filters rows with a parent identifier matching the text.  (e.g. [ 'LON', '' ])
  #
  # [:except_row]
  #   Filters on of the following options [:last,:first]
  #
  # [:in_state]
  #   Used in retrieving import.yml config settings and helps improve scope for queries.  (e.g. 'england')
  #
  # [:with_state_code]
  #   Improves scope for queries if applicable. (e.g. 'ENG')
  #
  # [:with_config_option]
  #   Adds this to the import.yml key to support additional data to be imported i.e. major/minor cities.  (e.g. 'major')
  #
  # [:force_url_and_data_source]
  #   Allows the naming convention for import.yml settings to be ignored and a Hash parameter to be passed in.  (e.g. { "url" => "UK-England.html", "data_source" => "cities" })
  #
  # [:match_parent]
  #   Allows a parent Place object to be passed in so that each new Place is a child of the parent Place
  #
  # [:match_parent_on_name]
  #   Allows an Array of Place objects to be passed in and used as parent if there is a match on name.  An error is logged if a match is not found.
  #
  # [:match_parent_on_abbreviation]
  #   Allows an Array of Place objects to be passed in and used as parent if there is a match on abbreviation.  An error is logged if a match is not found.
  #
  def import_places(place_type, options)
    raise ArgumentError, "The place type is not supported" if ![PlaceType::City,PlaceType::County,PlaceType::State].include?(place_type)
    # SLogger.info options.keys.zip(options.values).join(',')
    
    all_options = %w{ with_country_code use_css_selectors_for except_those_with_name except_those_with_parent_identifier in_state with_config_option force_url_and_data_source match_parent match_parents_on_abbreviation match_parents_on_name except_row }
    invalid_options = options.keys.reject { |option| all_options.include?(option.to_s) }
    raise ArgumentError, "The option(s) #{invalid_options.join(',')} do not exist.  Please check the spelling of options." if !invalid_options.empty?
    
    # get critical country code and check we have a match
    country_code = options[:with_country_code] ? options[:with_country_code]: @country_code
    country = Country.find_by_country_code(country_code.upcase)
    raise IndexError, "Country code #{country_code} is not valid and a country cannot be found" if (country.blank?)
    
    # get option variables into local variables
    ignore_names = options[:except_those_with_name]
    ignore_names = [ignore_names] if (!ignore_names.blank? && !ignore_names.instance_of?(Array))
    ignore_parent_identifiers = options[:except_those_with_parent_identifier]
    ignore_parent_identifiers = [ignore_parent_identifiers] if (!ignore_parent_identifiers.blank? && !ignore_parent_identifiers.instance_of?(Array))
    except_row = options[:except_row]
    manual_column_css_selectors = options[:use_css_selectors_for] ? options[:use_css_selectors_for] : {}    
    in_state, with_config_option, force_url_and_data_source = options[:in_state], options[:with_config_option], options[:force_url_and_data_source]
    match_parent, match_parents_on_abbreviation, match_parents_on_name = options[:match_parent], options[:match_parents_on_abbreviation], options[:match_parents_on_name]
    state = Place.in_country_code(country_code).states.find_by_name(in_state) unless in_state.blank?
    raise IndexError, "The state '#{in_state}' could not be found in the database" if (!in_state.blank? && state.blank?) 
    
    # warn about invalid use of arguments
    raise ArgumentError, "Parent parameter is not a Place object" if (!match_parent.blank? && !match_parent.instance_of?(Place))
    raise ArgumentError, "Match Parents on Name parameter is not an Array of Places" if (!match_parents_on_name.blank? && !match_parents_on_name.instance_of?(Array))
    raise ArgumentError, "Match Parents on Abbreviation parameter is not an Array of Places" if (!match_parents_on_abbreviation.blank? && !match_parents_on_abbreviation.instance_of?(Array))
    
    raise ArgumentError, "Forced URL & Data Source needs to be a " if (!force_url_and_data_source.blank? && !force_url_and_data_source.instance_of?(Hash))
    raise ArgumentError, "A config option suffix and forced URL & Data source cannot be passed in at the same time as one must take precedence over the other" if (!force_url_and_data_source.blank? && !with_config_option.blank?)
    raise ArgumentError, "Use CSS Selectors for parameter must containa Hash" unless (options[:use_css_selectors_for].blank? || !options[:use_css_selectors_for].instance_of?(Hash))
    
    # get the config settings from import.yml represented as ImportConfig
    if force_url_and_data_source.blank?
      # use naming convention for config => gb_england_counties (using in_state param) OR ie_counties if place has no states 
      in_state_config_suffix = in_state.blank? ? '' : "_#{in_state}"
      places_suffix = with_config_option.blank? ? '' : "_#{with_config_option}"
      config_paths = { 
          PlaceType::State => "#{country_code}_states",
          PlaceType::County => "#{country_code}#{in_state_config_suffix}_counties#{places_suffix}",
          PlaceType::City => "#{country_code}#{in_state_config_suffix}_cities#{places_suffix}"
      }
      config_path = config_paths[place_type]
      config_params = OpenStruct.new(eval("ImportConfig.#{config_path}"))
      raise ArgumentError, "Config path #{config_path} appears to be invalid as URL and or Data_source is missing" if (config_params.blank? || config_params.url.blank? || config_params.data_source.blank?)
    else
      config_params = OpenStruct.new(force_url_and_data_source)
      raise ArgumentError, "Forced URL and Data Source Hash #{force_url_and_data_source.inspect} appears to be invalid as URL and or Data_source is missing" if (config_params.url.blank? || config_params.data_source.blank?)
    end
    
    # Import places from ImportedPlace model which loads data from external source
    places = ImportedPlace.get_places(config_params.url, config_params.data_source, manual_column_css_selectors, ignore_names, ignore_parent_identifiers)
    places = places.from(1) if except_row == :first
    places = places.to(places.count-2) if except_row == :last
    
    # Get the parent object or Hash of objects from array based on indexer
    parent = case
      when !match_parent.blank? then match_parent
      when !match_parents_on_name.blank? then match_parents_on_name.index_by(&:name)
      when !match_parents_on_abbreviation.blank? then match_parents_on_abbreviation.index_by(&:abbreviation)
      when !state.blank? then state
      else nil
    end
    # SLogger.info "Parent keys: #{parent.keys.join(',')}" if parent.instance_of?(Hash)
    
    # Store the imported places into the persistent places model
    Place.add_update_places_from_imported_places(places, country, place_type, parent)
    
    # Now query the database so that the latest list of places matched to parent(s) can be returned 
    #   and build up a list of used parents for logging purposes
    parent_names = {}
    scope = Place.in_country_code(country_code) 
    scope = scope.descendants_of(state) unless state.blank? # futher refine scope if we have a state 
    
    # iterate through all places in scope and match parents
    places_in_db = scope.all.select do |place|
      match = case
        when parent.instance_of?(Place) then 
          place.parent == parent ? place.parent : nil
        when parent.instance_of?(Hash) then
          place_key = (!match_parents_on_name.blank? ? place.parent.name : place.parent.abbreviation) if place.parent
          parent.keys.include?(place_key) ? place.parent : nil
        else
          # if we don't have parents to match, then everything is considered a match if is_root?
          place.is_root? ? place : nil
      end
      parent_names[place.parent.id] = place.parent.name if (match && place.parent) 
      match
    end
    
    SLogger.info "Imported #{places.count} #{place_type.pluralize} in '#{country.country_code}', parents #{parent_names.values.sort.first(10).join(',') + (parent_names.values.count > 10 ? '... ' + (parent_names.values.count-10).to_s + ' more' : '')}.  Total #{places_in_db.count} child #{place_type.pluralize} in db"

    places_in_db
  end
end