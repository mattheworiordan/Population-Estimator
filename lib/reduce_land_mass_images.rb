require 'rubygems'
require 'RMagick'
require 'ostruct'
require 'lib/import_gmap_tiles'

class ReduceLandMassImages
  def initialize()

  end
  
  ##
  # Reduce the land mass images generated from the Google Map tiles into tiles comprising of the square 2x2 
  #   of the parent tile.  For example, 4 tiles from zoom level 2 will be used to create one tile at zoom level 1
  #
  # This script assumes that all tiles at the maximum zoom level exist
  #
  # Option hash
  #   :limit_to => allows maximum number of tiles to be processed.  Default process all tiles
  #   :overwrite => overwrite existing images by setting this to any value
  def start(*options)
    limit_to = options[0][:limit_to].to_s if ( (options.length > 0) && (options[0].instance_of?(Hash)) )
    overwrite = options[0].keys.include?(:overwrite) if ( (options.length > 0) && (options[0].instance_of?(Hash)) )
    
    update_log_every  = 100
    tiles_processed   = 0
    tiles_limit       = limit_to && limit_to.match(/^\d+$/) ? limit_to.to_i : nil
    
    get_tiles.each do |tile| 
      tiles_processed += 1 if build_reduced_land_mass_image(tile.x, tile.y, tile.zoom, tile.accuracy_pixels, overwrite)
      SLogger.info("Update, processed #{update_log_every} items") if (tiles_processed % update_log_every == update_log_every-1)
      break if (!tiles_limit.nil? && tiles_limit <= tiles_processed)
    end 
    
    SLogger.info("\nDone.  Processed #{tiles_processed} tiles. ")
  end
  
  # Build land mass image from Google Map image
  # Returns true if image created 
  def build_reduced_land_mass_image(x, y, zoom, accuracy_pixels, overwrite = false)
    land_mass_tile_path = LandMassTile.tile_path(x, y, zoom, accuracy_pixels)
    
    # exit if file already exists
    return false if (!overwrite && File.exists?(land_mass_tile_path))
    
    begin
      # build up square of 4 children tiles
      child_tiles = (0..1).map { |this_x| (0..1).map { |this_y| OpenStruct.new(:x => this_x+x*2, :offset_x => this_x, :y => this_y+y*2, :offset_y => this_y, :zoom => zoom+1) } }.flatten(1)
      
      reduce_tiles = child_tiles.select do |tile| 
        tile.accuracy_pixels = accuracy_pixels 
        tile.path = LandMassTile.tile_path(tile.x, tile.y, tile.zoom, tile.accuracy_pixels)
        tile.exists = File.exists?(tile.path)
        tile.img = Magick::Image.read(tile.path).first if tile.exists
        tile.exists  # remove image if tile does not exist
      end
      
      stitch_tiles = child_tiles.select do |tile| 
        tile.accuracy_pixels = accuracy_pixels * 2
        tile.path = LandMassTile.tile_path(tile.x, tile.y, tile.zoom, tile.accuracy_pixels)
        tile.exists = File.exists?(tile.path)
        tile.img = Magick::Image.read(tile.path).first if tile.exists
        tile.exists  # remove image if tile does not exist
      end unless reduce_tiles.length == 4
      
      if (reduce_tiles.length == 4)
        # We are building a land mass tile from children with the same number of pixels in the tile
        #  which means we need to "squeeze" 4 tiles into 1
        new_tile = Magick::Image.new(AppConfig.gmap_tile_size / accuracy_pixels * 2, AppConfig.gmap_tile_size / accuracy_pixels * 2) do
          self.background_color = "transparent"
        end
        
        child_tile_size = new_tile.columns / 2
        reduce_tiles.each do |tile|
          raise "Tile#{tile.path} is incorrectly #{tile.img.columns} wide / high" if ( (tile.img.columns != child_tile_size) || (tile.img.rows != child_tile_size) ) 
          pixels = tile.img.export_pixels(0, 0, tile.img.columns, tile.img.rows, "RGBA")
          new_tile.import_pixels(tile.offset_x * child_tile_size, tile.offset_y * child_tile_size, tile.img.columns, tile.img.rows, "RGBA", pixels)
        end
        
        # now resize down to single tile size
        reduced_tile = new_tile.resize(AppConfig.gmap_tile_size / accuracy_pixels, AppConfig.gmap_tile_size / accuracy_pixels)
        
        reduced_tile.write land_mass_tile_path
      elsif (stitch_tiles.length == 4)
        # We are building a land mass tile from children with a lower accuracy level i.e. we need to 
        #   build up this tile by stitching 4 children tiles together
        
        new_tile = Magick::Image.new(AppConfig.gmap_tile_size / accuracy_pixels, AppConfig.gmap_tile_size / accuracy_pixels) do
          self.background_color = "transparent"
        end
        
        child_tile_size = new_tile.columns / 2
        stitch_tiles.each do |tile|
          raise "Tile#{tile.path} is incorrectly #{tile.img.columns} wide / high" if ( (tile.img.columns != child_tile_size) || (tile.img.rows != child_tile_size) ) 
          pixels = tile.img.export_pixels(0, 0, tile.img.columns, tile.img.rows, "RGBA")
          new_tile.import_pixels(tile.offset_x * child_tile_size, tile.offset_y * child_tile_size, tile.img.columns, tile.img.rows, "RGBA", pixels)
        end
        
        new_tile.write land_mass_tile_path
      else
        reduce_tiles_info = reduce_tiles.map{|c| "#{c.x}:#{c.y} zm #{c.zoom}" }.join(',')
        stitch_tiles_info = stitch_tiles.map{|c| "#{c.x}:#{c.y} zm #{c.zoom}" }.join(',')
        SLogger.warn("Could not reduce land mass image for position as not all children tiles exist.  Tile #{x}:#{y} (zoom #{zoom}).  Reduce tiles: #{reduce_tiles_info}.  Stitch tiles: #{stitch_tiles_info}")
        false
      end
      
    rescue Exception => e
      SLogger.warn("Could not save reduced land mass image for position #{x}:#{y} (zoom #{zoom}).  Error '#{e.message}'")
      false
    end
  end
  
  # get x,y tiles for all tiles at maximum zoom level - 1 down to zoom level 0 (1 tile)
  def get_tiles
    tiles = []
    accuracy_pixels_config = AppConfig.gmap_accuracy
    (0...AppConfig.gmap_max_zoom).reverse_each do |zoom|
      tiles_across = 2**zoom
      # the accuracy will go down by half at each zoom level with a floor of 1 i.e. 8 => 4, 7 => 2, 6 => 1, 5 => 1, 4 => 1
      accuracy_pixels = (accuracy_pixels_config.to_f / 2**(AppConfig.gmap_max_zoom - zoom).to_f ).ceil
      tiles_at_zoom = (0...tiles_across).map { |x| (0...tiles_across).map { |y| OpenStruct.new(:x => x, :y => y, :zoom => zoom, :accuracy_pixels => accuracy_pixels) } }.flatten(1)
      tiles.concat tiles_at_zoom
    end
    tiles
  end
end