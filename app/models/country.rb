class Country < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :places
  
  named_scope :with_country_code, { :conditions => [ "country_code IS NOT NULL" ] } 
  
  # override standard country_code search and make this case insensitive
  def self.find_by_country_code(country_code)
    find(:first, :conditions => ["country_code like ?", "#{country_code}"] )
  end
  
  # use country_code to identify country as opposed to Primary Key, this is used in the map.routes etc.
  def to_param
    country_code
  end
  
  # obtain the range of latitudes and longitudes from the Places within this country
  #
  # *Note on lat/longs*
  # latitudes: go north (higher) to south (lower)
  # longitudes: go east (lower) to west (higher)
  #
  def lat_long_rectangle_of_entire_country
    Place.lat_long_rectangle_with_descendents(self)
  end
  
end
