# encoding: UTF-8
class ImportPlacesIe
  
  include ImportPlacesModule
  
  def import()
    # set default country code for this import
    @country_code = 'ie'
    
    # TODO: Add :at_depth to import_* so that scope can be restricted to that depth
    ireland_counties = import_counties :except_those_with_name => "ireland"
    ireland_counties_all = import_counties :match_parents_on_abbreviation => ireland_counties, :except_those_with_name => "ireland", :except_those_with_parent_identifier => [""," "], :with_config_option => 'agglomerations'
    
    all_counties = ireland_counties.concat(ireland_counties_all)
    
    import_cities :match_parents_on_abbreviation => all_counties
    import_cities :match_parents_on_abbreviation => all_counties, :with_config_option => 'agglomerations'

  end
  
end