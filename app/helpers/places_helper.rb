module PlacesHelper
  # provides the name with population and lat/long
  def name_with_info(place)
    "#{place.name}, #{place.population.thousands} people" + (place.instance_of?(Place) ? "#{place.latitude}:#{place.longitude}" : "")
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
          haml_concat link_to(name_with_info(current_place), country_place_path(@country, current_place), :class => 'selected') 
          yield
        end
      else
        parents.each do |place,children|
          haml_tag :li do
            haml_concat link_to(name_with_info(place), country_place_path(@country, place))
            render_parents children, current_place, &block
          end
        end
      end
    end
  end
end
