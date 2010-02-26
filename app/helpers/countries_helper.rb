module CountriesHelper
  def map_xpath
    "#map"
  end
    
  def zoom_map_out_to_world()
    javascript_tag_with_wait "zoomMapToWorld($('#{map_xpath}').get(0));"
  end
  
  def zoom_map_to_rect(rect)
    javascript_tag_with_wait "zoomMapTo ($('#{map_xpath}').get(0), #{rect.north}, #{rect.south}, #{rect.east}, #{rect.west}, #{rect.latitude_centre}, #{rect.longitude_centre});"
  end
  
  private
  
  def javascript_tag_with_wait(javascript)
    wait_until_load = !request.xhr? # if XHR request, we don't need to wait until the page has loaded
    javascript_tag (wait_until_load ? "$(document).ready (function() {" : "") + javascript + (wait_until_load ? "})" : "")
  end
end
