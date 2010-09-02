require './test/test_helper'

class GmapTileTest < ActiveSupport::TestCase

  test "Gmap tile has correct attributes" do
    rectangle = GmapTile.new(1, 2, 3) # x, y, zoom
    assert(rectangle.x == 1, "X attribute is not valid")
    assert(rectangle.y == 2, "Y attribute is not valid")
    assert(rectangle.zoom == 3, "Zoom attribute is not valid")
  end
end
