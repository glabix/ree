RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL
end

ENV['AUDIT_ENABLED'] = 'true'
ENV['AUDIT_MAX_PARAMS_BYTES'] = '4096'
ENV['AUDIT_MAX_PARAMS_DEPTH'] = '4'

# The audit bean links a logger; keep it silent — the specs assert on the
# logger object itself, not on its output.
ENV['LOG_FILE_PATH'] = '/tmp/ree_audit.log'
ENV['LOG_LEVEL_FILE'] = ''
ENV['LOG_LEVEL_STDOUT'] = ''
