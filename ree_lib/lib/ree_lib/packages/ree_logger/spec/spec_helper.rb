RSpec.configure do |config|
  config.extend Ree::RSpecLinkDSL
end

def with_captured_stdout
  original_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = original_stdout
end

ENV['LOG_FILE_PATH'] = '/tmp/ree_logger.log'
ENV['LOG_FILE_AUTO_FLUSH'] = 'true'
ENV['LOG_LEVEL_FILE'] = 'info'
ENV['LOG_LEVEL_STDOUT'] = 'info'
ENV['LOG_LEVEL_ROLLBAR'] = 'info'
ENV['LOG_RATE_LIMIT_INTERVAL'] = '60'
ENV['LOG_RATE_LIMIT_COUNT'] = '600'
ENV['LOG_ROLLBAR_ACCESS_TOKEN'] = 'SET_YOUR_TOKEN'
ENV['LOG_ROLLBAR_ENABLED'] = 'true'
ENV['LOG_ROLLBAR_ENVIRONMENT'] = 'test'