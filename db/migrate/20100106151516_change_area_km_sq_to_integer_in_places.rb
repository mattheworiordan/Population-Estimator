class ChangeAreaKmSqToIntegerInPlaces < ActiveRecord::Migration
  def self.up
    change_column :places, :area_km_sq, :integer
  end

  def self.down
    change_column :places, :area_km_sq, :string
  end
end
