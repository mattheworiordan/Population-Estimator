require 'rubygems'
require 'RMagick'
require 'ostruct'
require 'map_area_colour'
require 'import_gmap_tiles'

class BuildLandMassImages
  def initialize()
    @accuracy_pixels = AppConfig.gmap_accuracy
    @tile_size = AppConfig.gmap_tile_size
  end
  
  ##
  # Build all land mass images from the Google Map images at the maximum zoom level
  #
  # Option hash
  #   :limit_to => allows maximum number of tiles to be processed.  Default process all tiles
  #   :overwrite => overwrite existing images by setting this to any value
  def start(*options)
    limit_to = options[0][:limit_to].to_s if ( (options.length > 0) && (options[0].instance_of?(Hash)) )
    overwrite = options[0].keys.include?(:overwrite) if ( (options.length > 0) && (options[0].instance_of?(Hash)) )
    
    tiles_across = 2**AppConfig.gmap_max_zoom
    tiles_processed = 0
    tiles_limit = limit_to && limit_to.match(/^\d+$/) ? limit_to.to_i : nil
    
    get_tile_pairs.each do |pair|
      x, y, zoom = pair
      tiles_processed += 1 if build_land_mass_image(x, y, zoom, overwrite)
      SLogger.info("Update, processed #{tiles_across} items") if (tiles_processed % tiles_across == tiles_across-1)
      break if (!tiles_limit.nil? && tiles_limit <= tiles_processed)
    end
    
    SLogger.info("\nDone.  Processed #{tiles_processed} tiles. ")
  end
  
  # Build land mass image from Google Map image
  # Returns true if image created 
  def build_land_mass_image(x, y, zoom, overwrite = false)
    land_mass_tile_path = self.class.tile_path(x, y, zoom, @accuracy_pixels)
    
    # exit if file already exists
    return false if (!overwrite && File.exists?(land_mass_tile_path))
    
    begin
      # load the tile image
      tile = Magick::Image.read(ImportGmapTiles.tile_path(x,y,zoom)).first

      # set up a new blank tile for writing
      tile_height_pixels = @tile_size/@accuracy_pixels
      land_mass_tile = Magick::Image.new(tile_height_pixels, tile_height_pixels) do
        self.background_color = "transparent"
      end

      land_mass_draw = Magick::Draw.new()
      land_mass_draw.fill = AppConfig.land_mass_land_colour
      draw_on_image_needed = nil

      (0...tile_height_pixels).each do |point_x| 
        (0...tile_height_pixels).each do |point_y| 
          pixels = tile.get_pixels(point_x*@accuracy_pixels, point_y*@accuracy_pixels, @accuracy_pixels, @accuracy_pixels)
          if MapAreaColour.new(pixels).is_land?
            land_mass_draw.point(point_x, point_y) 
            draw_on_image_needed = true
          end
        end
      end

      # draw land mass points
      land_mass_draw.draw(land_mass_tile) if draw_on_image_needed
    
      # save square
      land_mass_tile.write land_mass_tile_path
      
    rescue Exception => e
      SLogger.warn("Could not save land mass image for position #{x}:#{y} (zoom #{zoom}).  Error '#{e.message}'")
      false
    end
  end
  
  # get x,y tile pairs for all tiles at maximum zoom level
  def get_tile_pairs
    tiles_across = 2**AppConfig.gmap_max_zoom
    (0...tiles_across).map { |x| (0...tiles_across).map { |y| [x, y, AppConfig.gmap_max_zoom] } }.flatten(1)
  end
  
  class << self
    def replace_tile_vars(str, x, y, zoom, accuracy_pixels)
  		str.gsub(/\$x/, x.to_s).gsub(/\$y/, y.to_s).gsub(/\$z/, zoom.to_s).gsub(/\$px/, accuracy_pixels.to_s)
  	end
	
  	def tile_path(x, y, zoom, accuracy_pixels)
  	   Rails.root.join('db', AppConfig.land_mass_db_path, replace_tile_vars(AppConfig.land_mass_file_path, x, y, zoom, accuracy_pixels))
  	end
  end
end

# m = BuildLandMassImages.new()
# m.start(:limit_to => 16)