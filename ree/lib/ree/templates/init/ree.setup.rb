
Ree.add_error_types(
  :invalid_param,
  :not_found,
  :validation
)

# Switch Ree.logger to debug level
# Ree.set_logger_debug

if ENV['RUBY_ENV'] == 'test'
  Ree.enable_contracts
end

if ENV['RUBY_ENV'] == 'production'
  # Define preload context for registered objects
  Ree.preload_for(:production)

  # Use performance mode to load packages and registered objects based on schema files
  Ree.set_performance_mode
end