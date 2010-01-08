class FixLatLongToPlaces < ActiveRecord::Migration
  def self.up
    rename_column :places, :lat, :latitude
    add_column :places, :longitude, :float, :precision => 7, :scale => 10
  end

  def self.down
    rename_column :places, :latitude, :lat
    remove_column :places, :longitude
  end
end
