# Switch Ree.logger to debug level
# Ree.set_logger_debug

if ENV['RUBY_ENV'] == 'test'
  Ree.enable_contracts
end

if ENV['RUBY_ENV'] == 'production'
  # Define preload context for registered objects
  Ree.preload_for(:production)

  # Skip db casting for values already typecast by the DB driver
  # Ree.enable_db_load_performance_mode
end