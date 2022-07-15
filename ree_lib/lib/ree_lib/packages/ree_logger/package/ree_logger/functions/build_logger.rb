# frozen_string_literal: true

class ReeLogger::BuildLogger
  include Ree::FnDSL

  fn :build_logger do
    link 'ree_logger/appenders/appender', -> { Appender }
    link 'ree_logger/multi_logger', -> { MultiLogger }
    link 'ree_logger/rate_limiter', -> { RateLimiter }
  end

  contract(
    ArrayOf[Appender],
    Nilor[String],
    Nilor[RateLimiter],
    ArrayOf[String] => MultiLogger
  )
  def call(appenders, progname, rate_limiter, filter_words)
    logger = MultiLogger.new(progname, rate_limiter, filter_words)

    appenders.each do |appender|
      logger.add_appender(appender)
    end

    logger
  end
end