class GeocodePlaces
  
  def initialize()
    @default_rows_to_process = 500
    @pause_after = 10
    @pause_for_seconds = 5
  end
  
  ##
  # Start Geocoding all Places which do not have a latitude or longitude
  # 
  # Options:
  #   [:limit_to]
  #     Number representing max number of items to geocode
  #
  def start(*options)
    # never geocode more than 500, but respect limit if passed in 
    limit_to = options[0][:limit_to] if ( (options.length > 0) && (options[0].instance_of(Hash)) )
    all_places = limit_to.blank? ? Place.without_lat_long.first(@default_rows_to_process) : Place.without_lat_long.first(limit_to)
    
    all_places.each_index do |index| 
      geocode_and_save all_places[index]
      if ( (index+1) % @pause_after == 0 )
        SLogger.info "Geocoded #{index+1} places, pausing to maintain sensible throttle" 
        sleep @pause_for_seconds
      end
    end
  end

  ##
  # Simply geocode the place param and store the lat/long if available
  def geocode_and_save(place)
    geocoder = Graticule.service(:google).new AppConfig.google_api_key
    name = get_full_name(place)
    
    location = nil
    
    begin
      location = geocoder.locate name
      place.latitude = location.latitude
      place.longitude = location.longitude
      SLogger.warning "Unable to save #{name}, Location:(#{place.latitude}:#{place.longitude})" if !place.save
      SLogger.info "#{name}, Location:(#{place.latitude}:#{place.longitude})" 
    rescue Exception => e
      location = nil
      SLogger.warning "Unable to geocode #{name}, #{e.message}" 
    end
    
    location
  end
  
private
  
  def get_full_name(place)
    (place.parent ? get_full_name(place.parent) : place.country.name) + ", " + place.name
  end
end