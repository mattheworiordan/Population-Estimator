class LandMassTile
  attr_reader :x, :y, :zoom, :accuracy_pixels

  def initialize(x,y,zoom,accuracy_pixels)
    @x = x
    @y = y
    @zoom = zoom
    @accuracy_pixels = accuracy_pixels
  end

  class << self
    def replace_tile_vars(str, x, y, zoom, accuracy_pixels)
      str.gsub(/\$x/, x.to_s).gsub(/\$y/, y.to_s).gsub(/\$z/, zoom.to_s).gsub(/\$px/, accuracy_pixels.to_s)
    end

    def tile_path(x, y, zoom, accuracy_pixels)
      Rails.root.join('db', AppConfig.land_mass_db_path, replace_tile_vars(AppConfig.land_mass_file_path, x, y, zoom, accuracy_pixels))
    end

    def get_actual_tile_path_at_any_accuracy(x, y, zoom)
      gmap_accuracy = AppConfig.gmap_accuracy.to_f
      path = nil
      while gmap_accuracy >= 1
        check_path = tile_path(x, y, zoom, gmap_accuracy.to_i)
        path = check_path if (File.exists?(check_path))
        gmap_accuracy = gmap_accuracy / 2
        break if !path.nil?
      end
      path
    end
  end
end