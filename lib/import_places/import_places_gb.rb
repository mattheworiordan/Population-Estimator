# encoding: UTF-8
class ImportPlacesGb
  
  include ImportPlacesModule
  
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
    end 
    
    # Get all cities by the region urls set up 
    for_each_place_in gb_states, :with_abbreviation => ImportConfig.gb_england_abbreviation do |place|
      ImportConfig.gb_england_regions.each do |region_hash|
        region = OpenStruct.new(region_hash)
        region_counties = import_counties :in_state => 'england', :match_parent => place, :force_url_and_data_source => { "url"=>region.url, "data_source"=>region.county_data_source }
        import_cities :in_state => 'england', :match_parents_on_name => region_counties, :force_url_and_data_source => { "url"=>region.url, "data_source"=>region.city_data_source }
      end
    end 

    for_each_place_in gb_states, :with_abbreviation => ImportConfig.gb_northern_ireland_abbreviation do |place|
      import_cities :in_state => 'northern_ireland', :match_parent => place
    end 
    
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
    
  end
  
end