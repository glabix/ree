require_relative '../sample_gem/sample_gem'

Ree.add_error_types(
  :invalid_param,
  :not_found,
  :validation
)

# Ree.set_performance_mode
Ree.preload_for(:test)