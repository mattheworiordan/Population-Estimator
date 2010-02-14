class MapAreaColour
  attr_accessor :red, :green, :blue
  
  def self.water_colour 
    if @water_colour.nil?
      AppConfig.land_mass_water_colour.tap do |colour| 
        AppConfig.land_mass_water_colour_threshold.tap do |threshold| 
          #colour is a hex value stored in the config i.e. FFFFFF
          @water_colour = OpenStruct.new({
            :red => (colour[0,2].hex*256*(1-threshold) .. colour[0,2].hex*256*(1+threshold)),
            :green => (colour[2,2].hex*256*(1-threshold) .. colour[2,2].hex*256*(1+threshold)),
            :blue => (colour[4,2].hex*256*(1-threshold) .. colour[4,2].hex*256*(1+threshold))
          }) 
        end
      end
    end 
    @water_colour
  end
  
  # average colour for pixels array
  def initialize(pixels)
    @red = @green = @blue = 0
    pixels.each do |pixel|
      @red += pixel.red.to_f / pixels.length
      @green += pixel.green.to_f / pixels.length
      @blue += pixel.blue.to_f / pixels.length
    end
  end
  
  def is_water?()
    ( (self.class.water_colour.red === @red) && (self.class.water_colour.blue === @blue) && (self.class.water_colour.green === @green) )
  end
  
  def is_land?()
    !is_water?
  end
end
