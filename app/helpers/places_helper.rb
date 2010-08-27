module PlacesHelper
  # provides the name with population and lat/long
  def name_with_info(place)
    size = place.public_methods.include?("area_km_sq") && !place.area_km_sq.blank? ? ", #{place.area_km_sq} sq/km" : ""
    density = place.public_methods.include?("density_per_sq_km") && !place.density_per_sq_km.blank? ? ", #{place.density_per_sq_km} p/sq/km" : ""
    "#{place.name}, #{place.population.thousands} people#{size}#{density}" + (place.instance_of?(Place) ? ", (#{place.latitude}:#{place.longitude})" : "")
  end

  def render_parents_and_self(current_place, &block)
    if current_place and current_place.ancestors
      parents = current_place.ancestors.arrange 
      render_parents(parents, current_place, &block)
    end
  end

  def render_parents(parents, current_place, &block)
    haml_tag :ul do
      if (parents.blank?)
        haml_tag :li do
          haml_concat link_to name_with_info(current_place), country_place_path(@country, current_place), :class => 'selected', :method => :get, :update => 'results_list_container', :remote => true
          yield
        end
      else
        parents.each do |place,children|
          haml_tag :li do
            haml_concat link_to name_with_info(place), country_place_path(@country, place), :method => :get, :update => 'results_list_container', :remote => true
            render_parents children, current_place, &block
          end
        end
      end
    end
  end

  def maps_api_key
    AppConfig.google_api_key
  end
end
