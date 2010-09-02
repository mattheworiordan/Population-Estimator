class LandMassTileController < ApplicationController
  # /tile/landmass/[x]/[y]/[zoom].png
  def view
    x, y, zoom = params[:x], params[:y], params[:zoom]
    path = LandMassTile.get_actual_tile_path_at_any_accuracy(x, y, zoom)
    if (path.nil?)
      send_file Rails.root.join('public', 'images', 'tile_missing.png'), :type => 'image/png', :disposition => 'inline'
    else
      send_file path, :type => 'image/png', :disposition => 'inline'
    end
  end
end