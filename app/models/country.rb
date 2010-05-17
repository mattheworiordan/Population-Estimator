class Country < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :places
  
  scope :with_country_code, { :conditions => [ "country_code IS NOT NULL" ] } 
  
  # override standard country_code search and make this case insensitive
  def self.find_by_country_code(country_code)
    find(:first, :conditions => ["country_code like ?", country_code] )
  end
  
  # find countries which match string
  def self.find_with_string(name_to_match)
    raise Exception, "Name to match is blank" if name_to_match.blank?
    find(:all, :conditions => ["name like ?", "%#{name_to_match}%"])
  end
  
  # use country_code to identify country as opposed to Primary Key, this is used in the map.routes etc.
  def to_param
    country_code
  end
  
  # obtain the range of latitudes and longitudes from the Places within this country
  #
  # *Note on lat/longs*
  # latitudes: go north (higher) to south (lower)
  # longitudes: go east (higher) to west (lower)
  #
  def lat_long_rectangle_of_entire_country
    Place.lat_long_rectangle_with_descendents(self)
  end

  def country_code_blank?
    country_code.blank?
  end
  
  # used for sorting, returns [boolean for country_code being blank, name]
  def country_code_exists_and_country_name
    [(country_code.blank? ? 1 : 0), name]
  end
end
