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

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @countries }
    end
  end

  # GET /countries/1
  # GET /countries/1.xml
  def show
    @country = Country.find_by_country_code(params[:id]) unless params[:id].blank?
    
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

   # GET /countries/1/edit
  def edit
    @country = Country.find(params[:id])
  end

  # PUT /countries/1
  # PUT /countries/1.xml
  def update
    @country = Country.find(params[:id])

    respond_to do |format|
      if @country.update_attributes(params[:country])
        flash[:notice] = 'Country was successfully updated.'
        format.html { redirect_to(@country) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @country.errors, :status => :unprocessable_entity }
      end
    end
  end
end
