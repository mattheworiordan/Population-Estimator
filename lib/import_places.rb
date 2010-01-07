# this module is needed first
require 'import_places/import_places_module.rb'

# now include all other import_place modules
Dir[File.dirname(__FILE__) + '/import_places/*.rb'].each { |file| require file }