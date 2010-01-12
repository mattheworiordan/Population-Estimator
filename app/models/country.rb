class Country < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :places
  
  named_scope :in_country_code, lambda { |country_code| { :conditions => ["country_code like ?", "#{country_code}"] } }
  named_scope :with_country_code, { :conditions => [ "country_code IS NOT NULL" ] } 
  
  # override standard country_code search and make this case insensitive
  def self.find_by_country_code(country_code)
    in_country_code(country_code).first
  end
  
  # use country_id to identify country
  def to_param
    country_code
  end
  
end
