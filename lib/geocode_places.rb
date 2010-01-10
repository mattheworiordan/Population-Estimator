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
        SLogger.info "Geocoded #{index+1} places, pausing for #{@pause_for_seconds}s to maintain sensible throttle" 
        sleep @pause_for_seconds
      end
    end
  end

  ##
  # Simply geocode the place param and store the lat/long if available
  def geocode_and_save(place)
    geocoder = Graticule.service(:google).new AppConfig.google_api_key
    geocoder_alternative = Graticule.service(:yahoo).new AppConfig.yahoo_api_key
    name = get_full_name(place)
    
    location = geocode_locate_and_save(geocoder, place, name)
    location = geocode_locate_and_save(geocoder_alternative, place, name) if !location
    
    SLogger.warn "Unable to save #{name}, Location:(#{place.latitude}:#{place.longitude})" if !location
  end
  
private

  def geocode_locate_and_save(geocoder, place, name)
    location = nil
    
    begin
      location = geocoder.locate name
      place.latitude = location.latitude
      place.longitude = location.longitude
      if !place.save
        location = nil
      else 
        SLogger.info "#{name}, Location:(#{place.latitude}:#{place.longitude}) using #{geocoder.class.to_s.gsub(/.+::/,'')}" 
      end
    rescue Exception => e
      location = nil
      SLogger.warn "Error when geocoding #{name}, #{e.message}" 
    end
    
    location
  end
  
  def get_full_name(place)
    place.name + ", " + (place.parent ? get_full_name(place.parent) : place.country.name)
  end
end