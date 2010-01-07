class Country < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :places
  
  named_scope :in_country_code, lambda { |country_code| { :conditions => ["country_code like ?", "#{country_code}"] } }
  
  # override standard country_code search and make this case insensitive
  def self.find_by_country_code(country_code)
    in_country_code(country_code).first
  end
  
end
