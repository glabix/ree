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
ENV['ROLLBAR_ACCESS_TOKEN'] = 'f9501518abbd4464a6a9824515b6d05e'
ENV['ROLLBAR_ENVIRONMENT'] = 'test'