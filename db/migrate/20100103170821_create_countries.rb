class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.string :full_name
      t.integer :population
      t.float :density_per_sq_km
      t.date :source_update_date
      t.timestamp :created_at
      t.timestamp :updated_at

      t.timestamps
    end
  end

  def self.down
    drop_table :countries
  end
end
