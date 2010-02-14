require 'skynet'
require 'build_land_mass_images'
require 'slogger'

# TODO: Build Land Mass Images using MapReduce needs to be refactored as I am using MapReduce as a threaded job processing system which it is not.  It therefore times out.

class BuildLandMassImagesMapreduce
  include SkynetDebugger
  
  def self.run
    data = BuildLandMassImages.new().get_tile_pairs
    
    job = Skynet::Job.new(
      :mappers          => 4,
      :reducers         => 1,
      :map_reduce_class => self,
      :map_data         => data,
      :map_timeout      => 10.minutes,
      :data_debug       => true
    )
    results = nil
    SLogger.info("Starting job on #{data.length} potential tiles") do
      results = job.run
    end
    SLogger.info("Completed and processed " + (results.inject(0) { |total, obj| total += obj[1] }).to_s)
    results
  end

  def self.map(tile_pairs)
    land_mass_builder = BuildLandMassImages.new()
    result = Array.new
    SLogger.info("Processing #{tile_pairs.length} tiles.  From #{tile_pairs.sort.first} to #{tile_pairs.sort.last}") do
      tile_pairs.each do |tile_pair|
        x, y, zoom = tile_pair
        processed = land_mass_builder.build_land_mass_image(x, y, zoom) ? true : false
        result << [x,y,processed] 
        # SLogger.info("Tile #{x}:#{y} - processed? #{processed}")
      end
    end
    return result if result.length > 0
  end

  def self.reduce(tiles)
    totals = Hash.new
    if tiles.length > 0
      tiles.each do |tile|
        if (tile)
          x, y, processed = tile
          totals[x] ||= 0
          totals[x] += 1 if processed
        end
      end
    end 
    
    totals.keys.sort.map { |key| [key, totals[key]] }
  end
end