class ImportPlacesIe
  
  include ImportPlacesModule
  
  def import()
    # set default country code for this import
    @country_code = 'ie'
    
    ireland_counties = import_counties :except_those_with_name => "ireland"
    ireland_counties_all = import_counties :match_parent => ireland_counties, :except_those_with_name => "ireland", :with_config_option => 'agglomerations'
    
    import_cities :match_parent => ireland_counties_all
    import_cities :match_parent => ireland_counties_all, :with_config_option => 'agglomerations'
  end
  
end