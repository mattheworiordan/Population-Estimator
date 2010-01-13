# Simple rectangle object to store lat/long values for the rectangle
# And offer some functionality like centre
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
end