# TODO: Add in caching for pages retrieved so each URL is only retrieved once

class ImportedPlace
  
  attr_accessor :name, :abbreviation, :parent_identifier, :population, :place_type, :area_km_sq
  
  def initialize(name, abbreviation, parent_identifier, population, place_type, area_km_sq)
    @name = name.strip
    @abbreviation = abbreviation ? abbreviation.strip : nil
    @parent_identifier = parent_identifier
    @population = population.gsub(/,/,"")
    @place_type = place_type
    @area_km_sq = (area_km_sq ? area_km_sq.to_s.gsub(/,/,"") : nil)
  end
  
  # url is the suffix part of the URL at http://www.citypopulation.de/ i.e. UK-England.html
  # data_source is the class used in the div to house the table which contains the places data
  #
  # Params:
  #   manual_column_css_selector allows the default xpaths for columns to be overriden using syntax such as :abbreviation => ":nth(1)"
  #   filters allows a set of places to be ignored based on a match in the name column
  def self.get_places(url, data_source, manual_column_css_selectors = {}, filters = [])
    raise ArgumentError, "URL '#{url}' is invalid" if (url.blank?)
    raise ArgumentError, "Data source '#{data_source}' is invalid" if (data_source.blank?)
    
    # fix up any nil / empty values passed in where we need a value
    filters = [] if filters.blank?
    manual_column_css_selectors = {} if manual_column_css_selectors.blank?
    
    full_url = "http://www.citypopulation.de/#{url}"
    page = nil
    begin
      page = Nokogiri::HTML.parse( open( full_url ) ) 
      # test that we can at least see the body tag which will raise an exception if missing
      page.css("body").first
    rescue Exception => e
      raise "Could not load or parse HTML for '#{full_url}', #{e.message}"
    end
    
    @places = []
    
    # get list of columns based on a few CSS selectors that work with the citypopulation site
    base_css_selectors = ["div.#{data_source} table.data", "div#table table##{data_source}"]
    base_css_selector = base_css_selectors.select { |css_selector| !page.css(css_selector).empty? }.first
    raise "Could not find data in #{url}, data source #{data_source}" if base_css_selector.blank?
    
    # see if we can match the columns using defaults (stored in imports.yml) regular expression matches or column positions
    columns = page.css("#{base_css_selector} tr:first th").map { |elem| elem.inner_text }
    
    # retrieve the various column defaults from imports.yml (regular expressions of css selectors)
    column_names = %w{ name abbreviation parent_identifier population place_type area_km_sq }
    css_selectors = Hash[*column_names.zip(column_names.map { |col| css_selector_from_config(columns, col) }).flatten]
    
    # allow css selectors to be passed in for columns and override any default matches
    manual_column_css_selectors.each { |column, css_selector| css_selectors[column.to_s] = css_selector }
    
    # add in a simple shortcut method to reduce code below
    def css_selectors.val(col, place)
      place.css('td' + self[col]).inner_text.to_s if self[col]
    end
    
    # SLogger.info("#{full_url}, #{data_source} - #{css_selectors['name']}, #{css_selectors['abbreviation']}, #{css_selectors['parent_identifier']}, #{css_selectors['population']}, #{css_selectors['place_type']}, #{css_selectors['area_km_sq']}")
    
    # ignore first row as it contains table header
    page.css("#{base_css_selector} tr").to_a.from(1).each do |place|
      # puts("#{css_selectors.val('name',place)}, #{css_selectors.val('parent_identifier',place)}, #{css_selectors.val('population',place)}")
      @places << self.new(*column_names.map { |col| css_selectors.val(col,place) }) unless
        (filters.find { |name| css_selectors.val('name',place).strip.downcase == name.downcase } || css_selectors.val('name',place).strip.blank?)
    end
    
    @places
  end
  
private

  # get the css selector that is needed for Nokogiri(was Hpricot) to find the required column 
  def self.css_selector_from_config(columns, config_key)
    css_selector = nil
    config_list = ImportConfig.place_column_defaults[config_key]
    
    # iterate through the default column names or css selector expressions
    matches = config_list.select do |item|
      # if item is a regular expression, see if we can match it to a column
      if item.to_s.match(/^\//)  
        columns.each_index do |column_index| 
          # SLogger.info "#{item.gsub(/(^\/)|(\/$)/, '')} - #{columns[column_index]}"
          css_selector = ":nth-child(#{column_index+1})" if Regexp.new(item.gsub(/(^\/)|(\/$)/, ""), Regexp::IGNORECASE).match(columns[column_index]) 
          break if css_selector != nil
        end
      else
        css_selector = item.to_s if css_selector == nil
      end
    end
    
    css_selector
  end
end