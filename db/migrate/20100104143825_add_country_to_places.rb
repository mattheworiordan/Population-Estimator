class AddCountryToPlaces < ActiveRecord::Migration
  def self.up
    add_column :places, :country_id, :integer
  end

  def self.down
    remove_column :places, :country_id
  end
end
