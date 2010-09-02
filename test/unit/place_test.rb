require './test/test_helper'

class PlaceTest < ActiveSupport::TestCase

  def setup
    @gb = countries(:gb)
  end

  test "creation of new place" do
    place = Place.new(:name => "Imaginary place", :country_id => @gb.country_code, :population => 1, :place_type => PlaceType::State)
    assert(place.save, "Place was not saved correctly: #{place.errors.full_messages.to_sentence}")
  end

  test "named scopes" do
    assert(Place.name_containing_text('erpo').first == places(:liverpool), "Named scope search on name field not matching")
    assert(Place.name_containing_text('england').first != places(:liverpool), "Named scope search on name field is matching incorrectly")
  end

  test "creation of new place with missing fields" do
    place = Place.new()
    assert(!place.save, "Country was incorrectly saved with an empty name")

    place.name = "Catmandu"
    assert(!place.save, "Country was incorrectly saved with an empty country_id and population")
    assert(place.errors[:name].blank?, "name should be valid as it is filled in")
    assert(!place.errors[:country_id].blank?, "country_id should have an error as it is nil")
    assert(!place.errors[:population].blank?, "population should have an error as it is nil")
    assert(!place.errors[:place_type].blank?, "place_type should have an error as it is nil")
  end

  test "country belongs to is working" do
    place = Place.new(:name => "Wonkaland", :population => 20, :country => @gb, :place_type => PlaceType::State)
    assert(place.save, "Place was not saved correctly: #{place.errors.full_messages.to_sentence}")
  end

  test "that the tree functions are working" do
    wales = places(:wales)
    assert(!wales.has_children?, "Wales does not have children but ancestry indicates it does")

    england = places(:england)
    assert(england.has_children?, "England does not have children and should do")
    assert(england.children[0].has_children?, "England's child '#{england.children[0].name} does not have children and should do")

    yorkcity = Place.cities.find_by_name('York')
    assert_not_nil(yorkcity, 'Could not find York in fixture data')
    assert(yorkcity.parent.parent == england, "York city's parent's parent should be England according to fixture data but it's not")
  end

  test "ensure england has a country" do
    assert_not_nil(places(:england).country, "England does not have a country")
  end

  test "ensure named scope for country_code is case insensitive" do
    assert_not_nil(Place.in_country_code(@gb.country_code.camelize).first, "Great Britain is not being found by the case insensitive named scope")
  end

  test "that place type scopes are working" do
    assert(Place.states.first.place_type == PlaceType::State, "First state is not a state")
    assert(Place.counties.first.place_type == PlaceType::County, "First county is not a county")
    assert(Place.cities.first.place_type == PlaceType::City, "First city is not a city")
    assert([PlaceType::City,PlaceType::Borough].include?(Place.cities_and_boroughs.first.place_type), "First city or bourough is not of the right place type")
    assert(Place.boroughs.first.place_type == PlaceType::Borough, "First borough is not a borough")

    assert(Place.cities_and_boroughs.count == Place.boroughs.count + Place.cities.count, "Count of cities and boroughs is not matching")
    assert(Place.counties_cities_and_boroughs.count == Place.counties.count + Place.boroughs.count + Place.cities.count, "Count of counties, cities & boroughs not matching")

    assert(Place.without_lat_long.first.latitude == nil, "Named scope for without lat long failed")
  end

  test "ensure finders for name and abbreviation are case insensitive" do
    assert_not_nil(Place.in_country_code(@gb.country_code).find_by_name('EngLAND'), "England is not being found by the case insensitive named scope")
    assert_not_nil(Place.in_country_code(@gb.country_code).find_by_abbreviation('Eng'), "England is not being found by the case insensitive named scope")
  end

  test "that city children are automatically set to boroughs" do
    yorkcity = places(:york_city)
    # TODO: Replace with a simple create call once bug is fixed in ancestry library
    test_borough = yorkcity.children.build :name => 'Sample borough', :place_type => PlaceType::City, :population => 1, :country => @gb
    test_borough.save

    assert(test_borough.errors.count == 0, "Test borough was not saved: #{test_borough.errors.full_messages.to_sentence}")
    assert(test_borough.place_type == PlaceType::Borough, "Test bourough is not defined as a borough by the model")

    should_be_city = Place.new(:name => "WonkaCity", :population => 20, :country => @gb, :place_type => PlaceType::Borough)
    assert(should_be_city.save, "Could not save test should_be_city #{should_be_city.errors.full_messages.to_sentence}")
    assert(should_be_city.place_type == PlaceType::City, "A borough without a city parent should be set to city")
  end

  test "that place validates latitude and longitude" do
    wales = places(:wales)
    wales.latitude = wales.longitude = nil

    assert(wales.save, "With both lat & long nil Wales should be able to be saved #{wales.errors.full_messages.to_sentence}")

    wales.latitude = "not a number"
    assert(!wales.save, "Latitude is not a number so this should not have saved")

    wales.latitude = nil
    wales.longitude = "not a number"
    assert(!wales.save, "Longitude is not a number so this should not have saved")

    wales.longitude = 51.232
    assert(!wales.save, "Lat is null but long is a number so this should fail")

    wales.latitude = 23.232
    assert(wales.save, "Lat & long are valid so Wales should be able to be saved #{wales.errors.full_messages.to_sentence}")
  end

  test "latitude and longitude rectangle functions" do
    england = places(:england)
    england_rectangle = england.lat_long_rectangle_with_descendents
    assert_not_nil(england_rectangle)

    assert(england.latitude < england_rectangle.north, "England centre #{england.latitude} should be south of the north most point #{england_rectangle.north}")
    assert(england.latitude > england_rectangle.south, "England centre #{england.latitude} should be north of the south most point #{england_rectangle.south}")
    assert(england.longitude > england_rectangle.west, "England centre #{england.longitude} should be east of the west most point #{england_rectangle.west}")
    assert(england.longitude < england_rectangle.east, "England centre #{england.longitude} should be west of the north most point #{england_rectangle.east}")

    wales = places(:wales)
    wales_rectangle = wales.lat_long_rectangle_with_descendents

    assert(wales_rectangle.west == wales_rectangle.east, "Wales has no children to expand the rectangle so west & east should be the same")
    assert(wales_rectangle.north == wales_rectangle.south, "Wales has no children to expand the rectangle so north & south should be the same")

    # whilst I appreciate we should not test how countries interact with places model, a country is needed to test the class method lat_long_rectangle_with_children
    gb = countries(:gb)
    gb_rectangle = Place.lat_long_rectangle_with_descendents(gb)

    assert_not_nil(gb_rectangle, "No rectangle returned for #{gb.name}")
    assert(!gb_rectangle.east.blank? && (gb_rectangle.east > gb_rectangle.west), "Invalid longitudes returned in rectangle #{gb_rectangle.inspect} for #{gb.name}")
    assert(!gb_rectangle.north.blank? && (gb_rectangle.north > gb_rectangle.south), "Invalid latitudes returned in rectangle for #{gb.name}")
  end
end