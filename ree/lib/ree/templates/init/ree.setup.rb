# Switch Ree.logger to debug level
# Ree.set_logger_debug

if ENV['RUBY_ENV'] == 'test'
  Ree.enable_contracts
end

if ENV['RUBY_ENV'] == 'production'
  # Define preload context for registered objects
  Ree.preload_for(:production)
end