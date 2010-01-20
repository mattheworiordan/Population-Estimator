# Stored in a Ruby File so that the TODO manager of TextMate includes this
#
# ### Population Estimator To Do list ###
# 
# TODO: GeoIP lookup http://mobiforge.com/forum/developing/location/retrieve-latlong-google-geolocation-and-calculate-radius
# TODO: Show all data in tree so that Matt can see and we can work out what to do with it...
# TODO: Consider adding batches to the import so a clean up can be done after import?
# TODO: REMEMBER TO GEOCODE THE FIRST 500 or so places again in order...
# TODO: Refactor UK to use the functionality built for Belgium where it can pick up lists of links and process them
# TODO: Add a de-duplication function for places that have the EXACT same lat/long
# TODO: Add wiki type functions to allow changes to be made to places
# TODO: Review performance issues calculating Lat/Long box, perhaps cache in model and then refresh cache if older than 1 day etc?
# TODO: Some places such as Ballina, Connacht, Ireland, are returning the wrong information for some reason.  We need to add a check to ensure the country matches when importing, and see if we can pass through some more country information in the request somehow.
# TODO: If we have more information on a place such as the sq.km, we could improve the accuracy of the zoom probably.
# TODO: Work through data manually to see where there may be too many places with the same lat/long
# TODO: Remove API keys from the config in Github, as well as work out what to do with passwords in database.yml
# TODO: Find a way to represent the earth in binary format i.e. land/water
# TODO: Build a library to read the earth image to work out land/water
# TODO: Look at duplicates of data, and remove duplicates, build rules around siblings / parents with same lat/long
# TODO: Use google maps API to get the land masses http://maps.google.com/maps/api/staticmap?center=53.814165,-3.0535135&zoom=16&size=1000x1000&maptype=roadmap&sensor=false&key=ABQIAAAAzr2EBOXUKnm_jVnk0OJI7xSsTL4WIgxhMZ0ZK_kHjwHeQuOD4xQJpBVbSrqNn69S6DOTv203MQ5ufA
# TODO: Use Devon & Cornwall for sample tests