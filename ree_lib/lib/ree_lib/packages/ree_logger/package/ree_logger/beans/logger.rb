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