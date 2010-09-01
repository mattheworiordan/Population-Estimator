class GmapTile
  attr_reader :x, :y, :zoom

  def initialize(x, y, zoom)
    @x = x
    @y = y
    @zoom = zoom
  end

  class << self
    def replace_tile_vars(str, x, y, zoom)
      str.gsub(/\$x/, x.to_s).gsub(/\$y/, y.to_s).gsub(/\$z/, zoom.to_s)
    end

    def tile_path(x, y, zoom)
      Rails.root.join('db',AppConfig.gmap_db_path,replace_tile_vars(AppConfig.gmap_file_path,x,y,zoom))
    end
  end
end