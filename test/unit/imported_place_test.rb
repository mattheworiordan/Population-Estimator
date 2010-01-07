require 'test_helper'

class ImportedPlaceTest < ActiveSupport::TestCase
  
  test "import UK places into model array" do
    uk_countries = ImportedPlace.get_places(ImportConfig.gb_states["url"], ImportConfig.gb_states["data_source"], { }, ["great britain and northern ireland"])
    
    assert_not_nil(uk_countries, "UK countries not imported")
    assert(uk_countries.count > 0, "Zero countries imported")
    
    assert(!uk_countries.first.name.blank?, "Name is blank for first country")
    assert(!uk_countries.first.population.blank?, "Population is blank for first country #{uk_countries.first.name}")
  end
  
  test "import England places and ensure model matches to parents" do
    gb_countries = ImportedPlace.get_places(ImportConfig.gb_states["url"], ImportConfig.gb_states["data_source"], { }, ["great britain and northern ireland"])
    assert_not_nil(gb_countries, "GB countries not imported")
    
    country = Country.find_by_country_code('gb')
    assert_not_nil(country, "Could not find GB country in database")
    
    Place.add_update_places_from_imported_places(gb_countries, country, PlaceType::State)
    gb_countries_in_db = Place.states.in_country_code('gb')
    assert(gb_countries_in_db.count > 0, "No GB countries stored in database")
    
    english_counties = ImportedPlace.get_places(ImportConfig.gb_england_counties["url"], ImportConfig.gb_england_counties["data_source"], { }, %w{ england })
    Place.add_update_places_from_imported_places(english_counties, country, PlaceType::County, gb_countries_in_db.index_by(&:abbreviation))
    
    england = Place.states.find_by_abbreviation('ENG')
    assert_not_nil(england, "England could not be found in the database")
    
    london = Place.counties.find_by_abbreviation('LON')
    assert_not_nil(london, "London could not be found in the database")
    assert(london.parent == england, "London's (country) parent should be England, but is #{london.parent.name} instead")
  end
  
end
