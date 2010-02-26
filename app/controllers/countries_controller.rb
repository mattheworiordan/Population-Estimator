class CountriesController < ApplicationController
  # GET /countries
  # GET /countries.xml
  def index
    @countries = Country.all.sort_by(&:country_code_exists_and_country_name)
    @map_rectangle = Rectangle.new(0,0,0,0) # GMap will just show a world map
    @place = nil
    
    SLogger.info("#{request.url}")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @countries }
    end
  end

  # GET /countries/1
  # GET /countries/1.xml
  def show
    @country = Country.find_by_country_code(params[:id]) unless params[:id].blank?
    return redirect_to :action => "index" if @country.blank? 
    
    @place = @filtered_places = nil

    @places_filter = (params[:search] ? params[:search][:place_name] : nil)
    if (!@places_filter.blank?)
      @filtered_places = @country.places.name_containing_text(@places_filter)
    else
      @children = @country.places.roots
      @ancestors_and_self = [] # we have no ancestors or self as we are showing root
    end
    
    @map_rectangle = @country.lat_long_rectangle_of_entire_country
    
    respond_to do |format|
      format.js { render_html_with_flash :partial => "places/places_list" } 
      format.html
      format.xml { render :xml => @countries }
    end
  end

  # GET /countries/search
  def search
    @search = OpenStruct.new(params[:search])
    @flash_results = false

    if @search.country_name.blank?
      @countries = Country.all.sort_by(&:country_code_exists_and_country_name)
    else
      @countries = Country.find_with_string(@search.country_name).sort_by(&:country_code_exists_and_country_name)
    end

    @map_rectangle = Rectangle.from_outside_of_rectangles(@countries.reject(&:country_code_blank?).map(&:lat_long_rectangle_of_entire_country)) unless @countries.blank?
    @map_rectangle = Rectangle.new(0,0,0,0) if (@countries.blank? || !@map_rectangle.valid?)
    @place = nil

    respond_to do |format|
      format.js { render_html_with_flash :partial => "country_list" } 
      format.html { render :action => "index" }    
      format.xml { render :xml => @countries }
    end
  end
end
