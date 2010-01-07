class RenameFullnameColumnCountry < ActiveRecord::Migration
  def self.up
    rename_column :countries, :full_name, :name
  end

  def self.down
    rename_column :countries, :name, :full_name
  end
end
