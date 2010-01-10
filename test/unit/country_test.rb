require 'test_helper'

class CountryTest < ActiveSupport::TestCase

  test "creation of new country" do
    country = Country.new(:name => "Sample Country")
    assert(country.save, "Country was not saved correctly: #{country.errors.full_messages.to_sentence}")
  end
  
  test "creation of new country with empty name" do
    country = Country.new()
    assert(!country.save, "Country was saved with an empty name")
  end
  
  test "ensure country has unique name" do
    country = Country.new(:name => "Unique Name")
    country2 = Country.new(:name => "Unique Name")
    assert(country.save, "First country with unique name could not be saved: #{country.errors.full_messages.to_sentence}")
    assert(!country2.save, "Second country without a unique name was saved successfully")
    assert_not_nil(country2.errors.on(:name), ":name should be invalid as it is not unique")    
  end
  
  test "ensure country has places" do
    assert(countries(:gb).places.size > 0, "Great Britain does not have any places")
  end
  
  test "the named scopes" do
    assert_not_nil(Country.in_country_code('gb').first, "Country not found in the named scope in_country_code")
    assert_not_nil(Country.with_country_code.first, "Country not found in the named scope with_country_code")
    assert(Country.with_country_code.find_by_name("Great Britain").country_code == "gb", "Could not find GB in with_country_code scope")
    assert(Country.with_country_code.count != Country.all.count, "Countries with country codes match those without country codes")
  end
  
  test "that searches are case insensitive using finder methods" do
    assert_not_nil(Country.find_by_country_code('gB'), "Country code search appears to be case sensitive")
  end
end
