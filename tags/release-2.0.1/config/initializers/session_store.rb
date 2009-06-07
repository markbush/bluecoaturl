# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_testapp_session',
  :secret      => 'bc6ba7add6b8c7fe9f1771331576138d5eac3c7d95e851cceb695ac11b6436caa8912ea52a50e09796535700715b50b60c38353a8d3dde334a0f5e123bf6ee7e'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
