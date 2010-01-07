class AddUrlToCountry < ActiveRecord::Migration
  def self.up
    add_column :countries, :data_url, :string
  end

  def self.down
    remove_column :countries, :data_url
  end
end
