class ImportPlacesGb
  
  include ImportPlacesModule
  
  # TODO: GeoIP lookup http://mobiforge.com/forum/developing/location/retrieve-latlong-google-geolocation-and-calculate-radius
  # TODO: Add tests
  # TODO: Show all data in tree so that Matt can see and we can work out what to do with it...
  # TODO: Consider adding batches to the import so a clean up can be done after import?
  # TODO: Check why some places such as Cheshire don't have a parent...
  # TODO: When Scotland is being added, the matches on name should only be on Scotland children, but this is not done on county level i.e. this call needs to only return scottish counties -> scotland_counties_in_db = Place.find(:all, :include => [ :country ], :conditions => ["countries.country_code = ? and place_type = ?", @country_code, PlaceType::County])
  
  def import()
    # set default country code for this import
    @country_code = 'gb'
    
    gb_states = import_states :except_those_with_name => "great britain and northern ireland"
    
    for_each_place_in gb_states, :with_abbreviation => ImportConfig.gb_england_abbreviation do |place|
      #English Counties
      english_counties = import_counties :in_state => 'england', :match_parent => place, :except_those_with_name => "england"
      # English Cities as we need to set London as parent to London suburbs 
      english_cities = import_cities :in_state => 'england', :match_parents_on_abbreviation => english_counties
      
      # Get London place
      for_each_place_in english_cities, :with_name => ImportConfig.gb_england_cities_london_name do |london|
        import_cities :in_state => 'england', :match_parent => london, :with_config_option => 'london_boroughs'
        import_cities :in_state => 'england', :match_parent => london, :with_config_option => 'london_boroughs_and_urban_areas'
      end
    end if false
    
    # Get all cities by the region urls set up 
    for_each_place_in gb_states, :with_abbreviation => ImportConfig.gb_england_abbreviation do |place|
      ImportConfig.gb_england_regions.each do |region_hash|
        region = OpenStruct.new(region_hash)
        region_counties = import_counties :in_state => 'england', :match_parents => place, :force_url_and_data_source => { "url"=>region.url, "data_source"=>region.county_data_source }
        import_cities :in_state => 'england', :match_parents_on_name => region_counties, :force_url_and_data_source => { "url"=>region.url, "data_source"=>region.city_data_source }
      end
    end if false

    for_each_place_in gb_states, :with_abbreviation => ImportConfig.gb_northern_ireland_abbreviation do |place|
      import_cities :in_state => 'northern_ireland', :match_parent => place
    end if false
    
    %w{ scotland wales }.each do |state|
      abbreviation = eval("ImportConfig.gb_#{state}_abbreviation")
      for_each_place_in gb_states, :with_abbreviation => abbreviation do |place|
        SLogger.info "Importing #{place.name}"
        [ [ :major, :match_parents_on_abbreviation ], [ :minor, :match_parents_on_name ] ].each do |key_pair| 
          option, match_on = key_pair
          counties = import_counties :in_state => state, :match_parent => place, :with_config_option => option.to_s
          import_cities :in_state => state, match_on => counties, :with_config_option => option.to_s 
        end
      end
    end
    
    return
    
    ## English Counties
    #
    # england_country = Place.find(:all, :include => [ :country ], :conditions => { "countries.country_code" => @country_code, :place_type => PlaceType::Country, :abbreviation => "ENG"} ).first
    #     raise "England country could not be found" if england_country.blank?
    #     
    #     english_counties = ImportedPlace.get_places(ImportConfig.gb_england_counties["url"], ImportConfig.gb_england_counties["data_source"], { }, %w{ england })
    #     Place.add_update_places_from_imported_places(english_counties, @country_code, PlaceType::County, england_country)
    #     
    #     english_counties_in_db = Place.find(:all, :include => [ :country ], 
    #       :conditions => ["abbreviation is not null and countries.country_code = ? and place_type = ?", @country_code, PlaceType::County])
    #       
    #     SLogger.info "Imported #{english_counties.count} English Counties, total #{english_counties_in_db.count} in database"
    
    ## English Cities
    #
    # english_cities = ImportedPlace.get_places(ImportConfig.gb_england_cities["url"], ImportConfig.gb_england_cities["data_source"], { }, [])
    #     Place.add_update_places_from_imported_places(english_cities, @country_code, PlaceType::City, english_counties_in_db.index_by(&:abbreviation))
    #     english_cities_in_db = Place.find(:all, :include => [ :country ], 
    #       :conditions => { "countries.country_code" => @country_code, :place_type => PlaceType::City })
    #     SLogger.info "Imported #{english_cities.count} English Cities, total #{english_cities_in_db.count} in database"
    
    ## London, two separate imports based on two sources
    #
    # london = english_cities_in_db.select { |place| place.name.strip.downcase == ImportConfig.gb_england_london_name.strip.downcase }.first
    #    london_boroughs = ImportedPlace.get_places(ImportConfig.gb_england_london_boroughs["url"], ImportConfig.gb_england_london_boroughs["data_source"], { }, [])
    #    Place.add_update_places_from_imported_places(london_boroughs, @country_code, PlaceType::Borough, london)
    #    SLogger.info "Imported #{london_boroughs.count} English London Boroughs into database in first pass, London has a population of #{london.population}"
    #    
    #    london_boroughs = ImportedPlace.get_places(ImportConfig.gb_england_london_boroughs_and_urban_areas["url"], ImportConfig.gb_england_london_boroughs_and_urban_areas["data_source"], { }, [])
    #    Place.add_update_places_from_imported_places(london_boroughs, @country_code, PlaceType::Borough, london)
    #    SLogger.info "Imported #{london_boroughs.count} English London Boroughs into second pass"
    
    
    ## English County Cities
    # Import all the county cities which has a longer list of cities with smaller populations by county
    #
    # ImportConfig.gb_england_regions.each do |region_hash|
    #     region = OpenStruct.new(region_hash)
    #     
    #     region_counties = ImportedPlace.get_places(region.url, region.county_data_source, { }, [])
    #     Place.add_update_places_from_imported_places(region_counties, @country_code, PlaceType::County, england_country)
    #     SLogger.info "Imported #{region_counties.count} counties for region '#{region.name}' - #{region_counties.map(&:name).join(',')}"
    #     
    #     # reload counties from db as some may have been added, and don't use region_counties as that can exclude some previously imported ones
    #     english_counties_index_by_name = Place.find(:all, :include => [ :country ], 
    #       :conditions => ["countries.country_code = ? and place_type = ?", @country_code, PlaceType::County]).index_by(&:name)
    #     region_cities = ImportedPlace.get_places(region.url, region.city_data_source, { }, [])
    #     Place.add_update_places_from_imported_places(region_cities, @country_code, PlaceType::City, english_counties_index_by_name)
    #     SLogger.info "Imported #{region_cities.count} cities for region '#{region.name}'"
    #     
    #     return
    #   end
    
    ## Northern Ireland Cities
    #
    northern_ireland_country = gb_countries_in_db = Place.find(:all, :include => [ :country ], :conditions => { "countries.country_code" => @country_code, :place_type => PlaceType::Country, :abbreviation => "NIR"} ).first
    raise "Northern Ireland country could not be found" if northern_ireland_country.blank?
    
    gb_northern_ireland_cities = ImportedPlace.get_places(ImportConfig.gb_northern_ireland_cities["url"], ImportConfig.gb_northern_ireland_cities["data_source"], { }, [])
    Place.add_update_places_from_imported_places(gb_northern_ireland_cities, @country_code, PlaceType::City, northern_ireland_country)
    SLogger.info "Imported #{gb_northern_ireland_cities.count} Northern Ireland Cities"
    
    ## Scotland Counties
    #
    scotland_country = Place.find(:all, :include => [ :country ], :conditions => { "countries.country_code" => @country_code, :place_type => PlaceType::Country, :abbreviation => "SCO"} ).first
    raise "Scotland country could not be found" if scotland_country.blank?
    
    scotland_counties = ImportedPlace.get_places(ImportConfig.gb_scotland_counties_major["url"], ImportConfig.gb_scotland_counties_major["data_source"], { }, %w{ scotland })
    Place.add_update_places_from_imported_places(scotland_counties, @country_code, PlaceType::County, scotland_country)
    SLogger.info "Imported #{scotland_counties.count} Scotland counties in first pass"
    
    scotland_counties = ImportedPlace.get_places(ImportConfig.gb_scotland_counties_minor["url"], ImportConfig.gb_scotland_counties_minor["data_source"], { }, %w{ scotland })
    Place.add_update_places_from_imported_places(scotland_counties, @country_code, PlaceType::County, scotland_country)
    
    scotland_counties_in_db = Place.find(:all, :include => [ :country ], 
      :conditions => ["countries.country_code = ? and place_type = ?", @country_code, PlaceType::County])
    SLogger.info "Imported #{scotland_counties.count} Scotland counties in second pass"
    
    ## Scotland Cities
    #
    scotland_cities = ImportedPlace.get_places(ImportConfig.gb_scotland_cities_major["url"], ImportConfig.gb_scotland_cities_major["data_source"], { }, [])
    Place.add_update_places_from_imported_places(scotland_cities, @country_code, PlaceType::City, scotland_counties_in_db.index_by(&:name))
    SLogger.info "Imported #{scotland_counties.count} Scotland cities in first pass"
    
    scotland_cities = ImportedPlace.get_places(ImportConfig.gb_scotland_cities_minor["url"], ImportConfig.gb_scotland_cities_minor["data_source"], { }, [])
    Place.add_update_places_from_imported_places(scotland_cities, @country_code, PlaceType::City, scotland_counties_in_db.index_by(&:name))
    
    SLogger.info "Imported #{scotland_counties.count} Scotland cities in second pass"
    
    ## Wales Counties
    #
    wales_country = Place.find(:all, :include => [ :country ], :conditions => { "countries.country_code" => @country_code, :place_type => PlaceType::Country, :abbreviation => "WAL"} ).first
    raise "Wales country could not be found" if wales_country.blank?
    
    wales_counties = ImportedPlace.get_places(ImportConfig.gb_wales_counties_major["url"], ImportConfig.gb_wales_counties_major["data_source"], { }, %w{ wales })
    Place.add_update_places_from_imported_places(wales_counties, @country_code, PlaceType::County, wales_country)
    SLogger.info "Imported #{wales_counties.count} Wales counties in first pass"
    
    wales_counties = ImportedPlace.get_places(ImportConfig.gb_wales_counties_minor["url"], ImportConfig.gb_wales_counties_minor["data_source"], { }, %w{ scotland })
    Place.add_update_places_from_imported_places(wales_counties, @country_code, PlaceType::County, wales_country)
    
    wales_counties_in_db = Place.find(:all, :include => [ :country ], 
      :conditions => ["countries.country_code = ? and place_type = ?", @country_code, PlaceType::County])
    SLogger.info "Imported #{wales_counties.count} Wales counties in second pass"
    
    ## Wales Cities
    #
    wales_cities = ImportedPlace.get_places(ImportConfig.gb_wales_cities_major["url"], ImportConfig.gb_wales_cities_major["data_source"], { }, [])
    Place.add_update_places_from_imported_places(wales_cities, @country_code, PlaceType::City, wales_counties_in_db.index_by(&:abbreviation))
    SLogger.info "Imported #{scotland_counties.count} Wales cities in first pass"
    
    wales_cities = ImportedPlace.get_places(ImportConfig.gb_wales_cities_minor["url"], ImportConfig.gb_wales_cities_minor["data_source"], { }, [])
    Place.add_update_places_from_imported_places(scotland_cities, @country_code, PlaceType::City, wales_counties_in_db.index_by(&:name))
    
    SLogger.info "Imported #{wales_cities.count} Wales cities in second pass"
    
  end
  
end