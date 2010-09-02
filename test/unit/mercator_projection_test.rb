require './test/test_helper'

# *Note on lat/longs*
# latitudes: go north (higher) to south (lower)
# longitudes: go east (lower) to west (higher)
#
class MercatorProjectionTest < ActiveSupport::TestCase
  def close(floats, floats2)
    # Compare two sets of floats.
    lat_actual = (floats[0] - floats2[0]).abs
    lng_actual = (floats[1] - floats2[1]).abs
    assert lat_actual < 1, "Mismatch latitude: #{floats[0]}, #{floats2[0]}"
    assert lng_actual < 1, "Mismatch longitude: #{floats[1]}, #{floats2[1]}"
    true
  end
  
  test "conversion of lat/long to pixels and back" do
    data = [ 
      [3, 39.81447, -98.565388, 463, 777],
      [3, 40.609538, -80.224528, 568, 771],

      [0, -90, 180, 256, 330],
      [0, -90, -180, 0, 330],
      [0, 90, 180, 256, -74],
      [0, 90, -180, 0, -74],

      [1, -90, 180, 512, 660],
      [1, -90, -180, 0, 660],
      [1, 90, 180, 512, -148],
      [1, 90, -180, 0, -148],

      [2, -90, 180, 1024, 1319],
      [2, -90, -180, 0, 1319],
      [2, 90, 180, 1024, -295],
      [2, 90, -180, 0, -295]
    ]

    data.each do |zoom, lat, lng, x, y|
      assert (MercatorProjection::lat_long_to_px(lat, lng, zoom) == [x, y]), "Lat Long did not match #{lat}, #{lng}"
      assert close(MercatorProjection::px_to_lat_long(x, y, zoom), [lat, lng]), "X Y did not match #{x}, #{y}"
    end
  end
end