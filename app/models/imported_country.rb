class ImportedCountry
  
  attr_accessor :name, :population, :density_per_sq_km, :source_update_date 
  
  def initialize(name, population, density_per_sq_km, source_update_date)
    @name = name
    @population = population.gsub(/,/,"")
    @density_per_sq_km = density_per_sq_km.gsub(/,/,"")
    
    cleaned_source_update_date = source_update_date.gsub(/(est\.)/, "").strip
    @source_update_date = Chronic.parse(cleaned_source_update_date)
    
    @source_update_date = Date.new(cleaned_source_update_date.match(/(\d{4})/)[0].to_i, 1, 1) if (cleaned_source_update_date.match(/^\d{4}$/))
  end
  
  def self.all
    page = Nokogiri::HTML.parse( open( ImportConfig.country_list ) ) 
    
    @countries = []

    # this syntax does not work as Nokigiri fails with this "valid" CSS3 selector
    # page.css("table#tl tr:not(:first-child)").each do |country|
    page.xpath("//table[@id='tl']/tr[position()>0]").each do |country|
      @countries << self.new(
        country.css("td:nth-child(2) > a").inner_text.to_s, 
        country.css("td:nth-child(3)").inner_text.to_s, 
        country.css("td:nth-child(5)").inner_text.to_s, 
        country.css("td:nth-child(6)").inner_text.to_s
      ) unless !(country/"td:nth-child(1)").inner_text.match(/^\s*\d\s*$/)
    end
    
    @countries
  end
  
end 