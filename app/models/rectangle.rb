# Simple rectangle object to store lat/long values for the rectangle
# And offer some functionality like centre
#
# *Note on lat/longs*
# latitudes: go north (higher) to south (lower)
# longitudes: go east (higher) to west (lower)
#
class Rectangle
  attr_accessor :north, :south, :east, :west
  
  def initialize(north = nil, south = nil, east = nil, west = nil)
    @north, @south, @east, @west = north, south, east, west
  end
  
  def latitude_centre 
    (@north + @south) / 2 unless @north.nil?
  end
  
  def longitude_centre
    (@east + @west) / 2 unless @north.nil?
  end
  
  def valid?
    !(@north.nil? || @south.nil? || @east.nil? || @west.nil?)
  end
  
  def self.from_outside_of_rectangles(rectangles)
    north, south, east, west = nil
    rectangles.each do |rect| 
      north = rect.north if ( north.nil? || (rect.north > north) )
      south = rect.south if ( south.nil? || (rect.south < south) )
      east = rect.east if ( east.nil? || (rect.east > east) )
      west = rect.west if ( west.nil? || (rect.west < west) )
    end
    Rectangle.new(north,south,east,west)
  end
  
  # build a rectangle of the extents using the latitude and longitude attributes of the lat_long_list
  def self.from_lat_longs(lat_long_list)
    north, south, east, west = nil
    lat_long_list.each do |lat_long| 
      north = lat_long.latitude if ( north.nil? || (lat_long.latitude > north) )
      south = lat_long.latitude if ( south.nil? || (lat_long.latitude < south) )
      east = lat_long.longitude if ( east.nil? || (lat_long.longitude > east) )
      west = lat_long.longitude if ( west.nil? || (lat_long.longitude < west) )
    end
    Rectangle.new(north,south,east,west)
  end
end