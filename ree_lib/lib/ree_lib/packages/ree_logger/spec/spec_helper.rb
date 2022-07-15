RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL
end

ENV['LOG_FILE_PATH'] = '/tmp/ree_logger.log'
ENV['LOG_LEVEL_FILE'] = 'info'
ENV['LOG_LEVEL_STDOUT'] = 'info'
ENV['LOG_RATE_LIMIT_INTERVAL'] = '60'
ENV['LOG_RATE_LIMIT_COUNT'] = '600'