class CreatePlaces < ActiveRecord::Migration
  def self.up
    create_table :places do |t|
      t.string :name
      t.string :abbreviation
      t.integer :population
      t.string :place_type
      t.string :area_km_sq
      t.timestamp :created_at
      t.timestamp :updated_at

      t.timestamps
    end
    
    add_index :places, :name
    add_index :places, :abbreviation
  end

  def self.down
    remove_index :places, :name
    remove_index :places, :abbreviation
    drop_table :places
  end
end
