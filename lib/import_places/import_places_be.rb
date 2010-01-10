class ImportPlacesBe
  
  include ImportPlacesModule
  
  def import()
    # set default country code for this import
    @country_code = 'be'
    
    # TODO: Add :at_depth to import_* so that scope can be restricted to that depth
    counties = import_counties :except_those_with_name => "Belgium"
    counties_all = import_counties :match_parents_on_abbreviation => counties, :except_those_with_parent_identifier => [""," "], :with_config_option => 'agglomerations'
    
    # get complete list of counties together
    counties = counties.concat(counties_all)
    strip_text_in_brackets = /\s[\[\(\{].*/
    
    # iterate through lists and get url & text for provinces
    for_each_css_on_url_match ImportConfig.be_provinces_list do |province_name, url, config|
      province = counties.find { |province| province_name.gsub(strip_text_in_brackets,"") == province.name.gsub(strip_text_in_brackets,"") }
      # Brussels is the only exception where it is not a province so needs to be a root element??
      province_match = { :match_parent => province } unless province.blank?

      districts = import_counties( { :except_row => :last, :force_url_and_data_source => { "url"=>url, "data_source"=>config.data_source } }.merge( province_match ? province_match : {} ) )
      
      # brussels does not mach becaus of extra info in brackets, strip
      districts.each { | district | district.name.gsub!(strip_text_in_brackets,"") } if province.blank?
      
      import_cities :match_parents_on_name => districts, :force_url_and_data_source => { "url"=>url, "data_source"=>config.city_data_source }
    end
    
    return
    
    

    all_counties = ireland_counties.concat(ireland_counties_all)
    
    import_cities :match_parents_on_abbreviation => all_counties
    import_cities :match_parents_on_abbreviation => all_counties, :with_config_option => 'agglomerations'

  end
  
end