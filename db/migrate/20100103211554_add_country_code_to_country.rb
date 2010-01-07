class AddCountryCodeToCountry < ActiveRecord::Migration
  def self.up
    remove_column :countries, :data_url
    add_column :countries, :country_code, :string
  end

  def self.down
    remove_column :countries, :country_code
    add_column :countries, :data_url, :string
  end
end
