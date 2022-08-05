# frozen_string_literal: true

class ReeLogger::Logger
  include Ree::BeanDSL

  bean :logger do
    singleton
    factory :build

    link :build_logger
    link :config
    link :not_blank, from: :ree_object
    link :is_blank, from: :ree_object
    link 'ree_logger/rate_limiter', -> { RateLimiter }
    link 'ree_logger/appenders/file_appender', -> { FileAppender }
    link 'ree_logger/appenders/stdout_appender', -> { StdoutAppender }
    link 'ree_logger/appenders/rollbar_appender', -> { RollbarAppender }
  end

  def build
    appenders = []

    if config.levels.file
      if is_blank(config.file_path)
        raise ArgumentError, "use ENV['LOG_FILE_PATH'] to specify path to log file"
      end

      appenders << FileAppender.new(
        config.levels.file, nil, config.file_path, auto_flush: config.file_auto_flush
      )
    end

    if config.levels.stdout
      appenders << StdoutAppender.new(
        config.levels.stdout, nil
      )
    end

    if config.rollbar.enabled
      opts = {}
      opts[:branch] = config.rollbar.branch if config.rollbar.branch
      opts[:host] = config.rollbar.host if config.rollbar.host

      appenders << RollbarAppender.new(
        config.levels.rollbar,
        access_token: config.rollbar.access_token,
        environment: config.rollbar.environment,
        **opts
      )
    end

    build_logger(
      appenders,
      ENV['APP_NAME'],
      RateLimiter.new(
        config.rate_limit.interval,
        config.rate_limit.max_count
      ),
      config.default_filter_words
    )
  end
end