class AddIndexesToLatLongOnPlaces < ActiveRecord::Migration
  def self.up
    add_index :places, :latitude
    add_index :places, :longitude
  end

  def self.down
    remove_index :places, :longitude
    remove_index :places, :latitude
  end
end
