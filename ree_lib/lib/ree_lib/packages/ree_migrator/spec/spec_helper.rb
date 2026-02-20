RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL
end

ENV['LOG_FILE_PATH'] =
ENV['LOG_LEVEL_FILE'] = ''
ENV['LOG_LEVEL_STDOUT'] = ''
ENV['LOG_RATE_LIMIT_INTERVAL'] = ''
ENV['LOG_RATE_LIMIT_COUNT'] = ''