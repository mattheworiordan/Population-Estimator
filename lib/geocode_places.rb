class GeocodePlaces
  
  def initialize()
    @default_rows_to_process = 500
    @pause_after = 10
    @pause_for_seconds = 2
  end
  
  ##
  # Start Geocoding all Places which do not have a latitude or longitude
  # 
  # Options:
  #   [:limit_to]
  #     Number representing max number of items to geocode. (e.g. 50)
  #   [:overwrite]
  #     Ignore any previously geocoded places, do them all. (e.g. true)
  #
  def start(*options)
    # never geocode more than 500, but respect limit if passed in 
    limit_to = options[0][:limit_to] if ( (options.length > 0) && (options[0].instance_of?(Hash)) )
    overwrite_all = options[0].keys.include?(:overwrite_all) if ( (options.length > 0) && (options[0].instance_of?(Hash)) )
    
    scope = overwrite_all ? Place.all : Place.without_lat_long
    all_places = limit_to.blank? ? scope.first(@default_rows_to_process) : scope.first(limit_to)
    
    all_places.each_index do |index| 
      geocode_and_save all_places[index]
      if ( (index+1) % @pause_after == 0 )
        SLogger.info "\n---- Geocoded #{index+1}/#{all_places.count} places, pausing for #{@pause_for_seconds}s to maintain sensible throttle\n" 
        sleep @pause_for_seconds
      end
    end
  end

  ##
  # Simply geocode the place param and store the lat/long if available
  def geocode_and_save(place)
    raise ArgumentError, "Place must have a valid country code to be looked up" if place.country.country_code.blank?
    
    # geocoders to resolve lookups in order
    geocoders = [
      Graticule.service(:google).new(AppConfig.google_api_key),
      Graticule.service(:yahoo).new(AppConfig.yahoo_api_key),
      Graticule.service(:multimap).new(AppConfig.multimap_api_key)
    ]
    # Most geocoders prefer London, Greater London, Great Britain format
    #   however the following name is also used :locality=>"London, Greater London", :country='gb'
    name_searches = [ get_full_name(place), {:locality=>get_full_name(place), :country=>place.country.country_code} ]
    match_permutations = ( geocoders*name_searches.count ).zip( (name_searches*geocoders.count).sort { |a,b| a.instance_of?(String) ? -1 : 1 } )
    
    location_found = match_permutations.find do |perm|
      geocoder, name = perm
      geocode_locate_and_save(geocoder, place, name) 
    end
    
    SLogger.warn "Unable to save #{name}, Location:(#{place.latitude}:#{place.longitude})" if !location_found
  end
  
private

  def geocode_locate_and_save(geocoder, place, name)
    name_for_warnings = name.instance_of?(String) ? name : name[:locality]
    begin
      location = geocoder.locate(name)
      
      # ensure country matches
      if (location.country.to_s.downcase == place.country.country_code.downcase)
        place.latitude = location.latitude
        place.longitude = location.longitude
      
        if !place.save
          SLogger.warn "   * Error while saving #{place.name}, error #{place.errors.full_messages.join(',')}" 
        else 
          SLogger.info "#{name_for_warnings}, lat:long (#{place.latitude}:#{place.longitude}) using #{geocoder.class.to_s.gsub(/.+::/,'')}" 
          return location
        end
      else
        SLogger.info("   * No country match for #{name_for_warnings} using #{geocoder.class.to_s.gsub(/.+::/,'')}, expecting #{place.country.country_code}, got #{location.country} ")
      end
    rescue Exception => e
      SLogger.warn "   * Error when geocoding #{name_for_warnings}, #{e.message}" 
    end
    nil
  end
  
  # Get full name from ancestry i.e. London, Greater London, Great Britain
  def get_full_name(place)
    place.name + (place.parent ? ", " + get_full_name(place.parent) : "")
  end
end