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
    @map_rectangle = @place.lat_long_rectangle_with_descendents
    @children = @place.children

    respond_to do |format|
      format.html { render :template => 'countries/show', :layout => 'application' }
      format.xml  { render :xml => @place }
    end
  end
end
