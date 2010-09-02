class Place < ActiveRecord::Base
  belongs_to :country
  acts_as_tree

  validates_presence_of :name, :population, :country_id, :place_type
  validates_numericality_of :latitude, :longitude, :unless => Proc.new { |place| place.latitude.nil? && place.longitude.nil? }

  scope :in_country_code, lambda { |country_code| { :include => [ :country ], :conditions => [ "countries.country_code LIKE ?", country_code ] } }
  scope :states, { :conditions => { :place_type => PlaceType::State } }
  scope :counties, { :conditions => { :place_type => PlaceType::County } }
  scope :cities, { :conditions => { :place_type => PlaceType::City } }
  scope :boroughs, { :conditions => { :place_type => PlaceType::Borough } }
  scope :cities_and_boroughs, { :conditions => { :place_type => [PlaceType::City, PlaceType::Borough] } }
  scope :counties_cities_and_boroughs, { :conditions => { :place_type => [PlaceType::City, PlaceType::Borough, PlaceType::County] } }
  scope :without_lat_long, { :conditions => "latitude is null OR longitude is null"}
  scope :name_containing_text, lambda { |text| { :conditions => [ "places.name LIKE ?", "%#{text}%"] } }

  before_save :enforce_borough_and_city_rules

  # override default finders to make them case insensitive
  def self.find_by_name (*args) find(:first, { :conditions => [ "places.name like ?", args[0] ] }, *args.from(1)); end
  def self.find_by_abbreviation (*args) find(:first, { :conditions => [ "places.abbreviation like ?", args[0] ] }, *args.from(1)); end

  # Get the rectangle of North/South Latitude and East/West Longitude for a Country or Place
  # Returns an oject with attributes north, south, east, west
  #
  # *Note on lat/longs*
  # latitudes: go north (higher) to south (lower)
  # longitudes: go east (higher) to west (lower)
  #
  def self.lat_long_rectangle_with_descendents(country, place = nil)
    raise ArgumentError, "Cannot determine longitude and latitude box if Country is missing or not a Country object" if (country.blank? || !country.instance_of?(Country))
    raise ArgumentError, "Place must be of type place" if (!place.blank? && !place.instance_of?(Place))

    # unfortunately ActiveRecord does not support .calculate, .max style calls for multiple columns simultaneously
    # so some SQL had to be embedded
    sql = 'select max(latitude) as north, min(latitude) as south, min(longitude) as west, max(longitude) as east from places where country_id = ?'
    sql_params = [country.id]

    # if a place param is passed in then include the place + any descendents
    if !place.blank?
      sql << ' and ( (ancestry like ?) or (id = ?) )'
      sql_params.concat( [ ( place.ancestry.blank? ? "" : "#{place.ancestry}/" ) + "#{place.id}%", place.id] )
    end

    rect = Place.find_by_sql( [sql].concat(sql_params) ).first
    rect = Rectangle.new(rect.north.to_f, rect.south.to_f, rect.east.to_f, rect.west.to_f)
  end

  # Get the rectangle of North/South Latitude and East/West Longitude for a Country or Place
  # Calls method Place#longitude_latitude_rectangle
  def lat_long_rectangle_with_descendents()
    self.class.lat_long_rectangle_with_descendents(country, self)
  end

  def ancestors_and_self(current_item = self, hierarchy = [])
    hierarchy.insert(0, current_item)
    ancestors_and_self(current_item.parent, hierarchy) if (current_item.parent)
    hierarchy
  end

  # ensure rules about Boroughs & Cities are kept intact
  # A borough can only exist if it has a parent city
  def enforce_borough_and_city_rules
    if (self.place_type == PlaceType::City)
      self.place_type = PlaceType::Borough if (!self.parent.blank? && self.parent.place_type == PlaceType::City)
    elsif (self.place_type == PlaceType::Borough)
      self.place_type = PlaceType::City if (self.parent.blank? || ![PlaceType::Borough, PlaceType::City].include?(self.parent.place_type))
    end
  end

  # Parents can container either a hash of parents (i.e. multiple counties) with or contains a single parent (one city / country etc)
  #--
  # TODO: Need to figure out how I deal with parent nodes, matching them when searching etc.
  def self.add_update_places_from_imported_places(imported_places, country, place_type, parents = nil)
    imported_places.each do |imported_place|
      place = nil

      case
        when parents.instance_of?(Hash) || parents.instance_of?(Place)
          parent = parents[parents.keys.find { |k| !k.blank? && imported_place.parent_identifier.downcase == k.downcase }] if parents.instance_of?(Hash)
          parent = parents if parents.instance_of?(Place)

          if parent == nil
            SLogger.warn("Parent '#{imported_place.parent_identifier}' for '#{imported_place.name}' could not be found")
          else
            place = parent.children.select { |child_place| child_place.name.downcase == imported_place.name.downcase }.first
            # strange ancestry bug means we can't use create from children, so we use build & then save instead, see http://github.com/stefankroes/ancestry/issues#issue/9
            place = parent.children.build(:country => country) if place == nil
          end
        else
          SLogger.info "Imported '#{imported_place.name}' with NO parent Place, parent is '#{parents}'"
          place = country.places.find_by_name(imported_place.name)
          place = country.places.build if place == nil
      end

      if place != nil
        place.name = imported_place.name
        place.abbreviation = imported_place.abbreviation
        place.population = ( !imported_place.population.blank? && imported_place.population.match(/^\d+$/) && (place.population.blank? || imported_place.population.to_i > place.population) ) ? imported_place.population : place.population
        place.place_type = ( place_type.class != Proc ? place_type : place_type.call(imported_place.place_type) )
        place.area_km_sq = ( !imported_place.area_km_sq.blank? && imported_place.area_km_sq.match(/^\d+$/) && (place.area_km_sq.blank? || imported_place.area_km_sq.to_i > place.area_km_sq) ) ? imported_place.area_km_sq : place.area_km_sq

        SLogger.warn("Place #{imported_place.name} not saved to database: #{place.errors.full_messages.to_sentence}") if (!place.save)
      else
        SLogger.warn("Nothing done for '#{imported_place.name}'")
      end
    end
  end
end