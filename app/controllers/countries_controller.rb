class CountriesController < ApplicationController
  # GET /countries
  # GET /countries.xml
  def index
    @countries = Country.all.sort do |a,b| 
      case
        when a.country_code.blank? && !b.country_code.blank? then 1
        when !a.country_code.blank? && b.country_code.blank? then -1
        else a.name <=> b.name
      end 
    end
    @map_rectangle = Rectangle.new(0,0,0,0) # GMap will just show a world map
    @place = nil

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @countries }
    end
  end

  # GET /countries/1
  # GET /countries/1.xml
  def show
    @country = Country.find_by_country_code(params[:id]) unless params[:id].blank?
    @map_rectangle = @country.lat_long_rectangle_of_entire_country
    @place = nil
    
    if @country.blank? 
      redirect_to :action => "index"  
    else
      @children = @country.places.roots
      @ancestors_and_self = [] # we have no ancestors or self as we are showing root
      
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @country }
      end
    end
  end
end
