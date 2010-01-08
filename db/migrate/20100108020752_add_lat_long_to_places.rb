class AddLatLongToPlaces < ActiveRecord::Migration
  def self.up
    add_column :places, :lat, :float, :precision => 7, :scale => 10
  end

  def self.down
    remove_column :places, :lat
  end
end
