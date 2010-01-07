require 'test_helper'

class ImportedCountryTest < ActiveSupport::TestCase
  
  test "import countries into model array" do
    countries = ImportedCountry.all
    assert_not_nil(countries, "Countries not imported")
    assert(countries.count > 0, "Zero countries imported")
    
    assert(!countries.first.name.blank?, "Name is blank for first country")
    assert(!countries.first.population.blank?, "Population is blank for first country #{countries.first.name}")
  end
end
