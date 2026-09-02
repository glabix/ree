RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL
end

# The audit plugin option is inert unless the package itself is enabled.
ENV['AUDIT_ENABLED'] = 'true'
