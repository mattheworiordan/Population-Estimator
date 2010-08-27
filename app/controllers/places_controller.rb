class PlacesController < ApplicationController
  # GET /countries/gb/places
  # GET /countries/gb/places.xml
  def index
    redirect_to :controller => 'countries'
  end

  # GET /countries/gb/places/1
  # GET /countries/gb/places/1.xml
  def show
    @country = Country.find_by_country_code(params[:country_id])
    @place = Place.find(params[:id])
    return redirect_to(:controller => 'countries', :action => 'show') if (@place.blank?)

    @children = @country.places.roots
    @ancestors_and_self = [] # we have no ancestors or self as we are showing root

    @map_rectangle = @place.lat_long_rectangle_with_descendents
    @children = @place.children

    respond_to do |format|
      format.js { render :partial => "places/index" }
      format.html { render :template => 'countries/show', :layout => 'application' }
      format.xml  { render :xml => @place }
    end
  end

  def search
    @country = Country.find_by_country_code(params[:country_id])

    @places_filter = (params[:search] ? params[:search][:place_name] : nil)
    @filtered_places = nil

    return redirect_to(url_for(:controller => "countries", :id => params[:country_id], :format => :js, :action => "show")) if @places_filter.blank? # if there is no filter, simply show the list

    @filtered_places = @country.places.name_containing_text(@places_filter)
    @map_rectangle = if @filtered_places.empty?
      @country.lat_long_rectangle_of_entire_country 
    else
      Rectangle.from_lat_longs(@filtered_places)
    end

    respond_to do |format|
      format.js { render_html_with_flash :partial => "places/places_list" }
      format.html { render :template => 'countries/show', :layout => 'application' }
      format.xml  { render :xml => @place }
    end
  end
end