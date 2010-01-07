# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_population_estimator_session',
  :secret      => '78fb978e2a67d55e74dd31ca378313c6fbccaae34f6e10fac6621c819029cdcd128206c665d28b3771ac5148d4bb782d015d11d27c75640d3ec40c4e0fda38c9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
