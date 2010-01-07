class AddAncestryToPlaces < ActiveRecord::Migration
  def self.up
    add_column :places, :ancestry, :string
    add_index :places, :ancestry
  end

  def self.down
    remove_index :places, :ancestry
    remove_column :places, :ancestry
  end
end
