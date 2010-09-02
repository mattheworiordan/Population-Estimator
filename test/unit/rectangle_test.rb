require './test/test_helper'

# *Note on lat/longs*
# latitudes: go north (higher) to south (lower)
# longitudes: go east (lower) to west (higher)
#
class RectangleTest < ActiveSupport::TestCase

  test "creation of new rectangle" do
    north = 1
    south = -1
    east = -1
    west = 1

    rectangle = Rectangle.new(north, south, east, west) # n,s,e,w
    assert(rectangle.north == north, "North should be #{north}")
    assert(rectangle.south == south, "South should be #{south}")
    assert(rectangle.east == east, "East should be #{east}")
    assert(rectangle.west == west, "West should be #{west}")
  end

  test "outside rectangle from rectangles" do
    # test to ensure the outside rectangle encompasses all inside rectangles
    rects = [Rectangle.new(1,0,0,1), Rectangle.new(4,1,5,1), Rectangle.new(1,0,-2,3)]
    outside_rectangle = Rectangle.from_outside_of_rectangles(rects)
    assert(outside_rectangle.south == 0, "South of outside rectangle should be 0, was #{outside_rectangle.south}")
    assert(outside_rectangle.north == 4, "North of outside rectangle should be 4, was #{outside_rectangle.north}")
    assert(outside_rectangle.east == 5, "East of outside rectangle should be 5, was #{outside_rectangle.east}")
    assert(outside_rectangle.west == 1, "West of outside rectangle should be 1, was #{outside_rectangle.west}")
  end

  test "outside rectangle from points" do
    points = [
      OpenStruct.new({:longitude => 0, :latitude => 0}),
      OpenStruct.new({:longitude => 1, :latitude => 2}),
      OpenStruct.new({:longitude => -1, :latitude => 1}),
      OpenStruct.new({:longitude => -2, :latitude => -1}),
      ]
    outside_rectangle = Rectangle.from_lat_longs(points)
    assert(outside_rectangle.south == -1, "South of outside rectangle should be -1, was #{outside_rectangle.south}")
    assert(outside_rectangle.north == 2, "North of outside rectangle should be 2, was #{outside_rectangle.north}")
    assert(outside_rectangle.east == 1, "East of outside rectangle should be 1, was #{outside_rectangle.east}")
    assert(outside_rectangle.west == -2, "West of outside rectangle should be -2, was #{outside_rectangle.west}")
  end
end